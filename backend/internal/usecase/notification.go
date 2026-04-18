package usecase

import (
	"context"
	"log"
	"sync"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

type NotificationUsecase interface {
	GetNotifications(userID int64, limit int, cursor string) ([]domain.Notification, string, error)
	ReadNotification(id int64, userID int64) error
	ReadAllNotifications(userID int64) error
	CreateNotification(notification *domain.Notification) error
	Close()
}

type notificationUsecase struct {
	notificationRepo repository.NotificationRepository
	readChan         chan readTask
	createChan       chan *domain.Notification // 알림 생성용 채널 추가
	wg               sync.WaitGroup
	ctx              context.Context
	cancel           context.CancelFunc
}

type readTask struct {
	id     int64
	userID int64
}

const (
	batchSize     = 100
	flushInterval = 5 * time.Second
)

func NewNotificationUsecase(notificationRepo repository.NotificationRepository) NotificationUsecase {
	ctx, cancel := context.WithCancel(context.Background())
	u := &notificationUsecase{
		notificationRepo: notificationRepo,
		readChan:         make(chan readTask, 1000),
		createChan:       make(chan *domain.Notification, 500), // 생성 버퍼
		ctx:              ctx,
		cancel:           cancel,
	}

	u.wg.Add(2)
	go u.readWorker()
	go u.createWorker() // 생성 전용 워커 시작

	return u
}

// readWorker 는 이전과 동일하게 배치 업데이트 처리
func (u *notificationUsecase) readWorker() {
	defer u.wg.Done()
	ticker := time.NewTicker(flushInterval)
	defer ticker.Stop()

	tasks := make([]readTask, 0, batchSize)

	flush := func() {
		if len(tasks) == 0 {
			return
		}
		for _, task := range tasks {
			if err := u.notificationRepo.MarkAsRead(task.id, task.userID); err != nil {
				log.Printf("Failed to mark notification %d as read: %v", task.id, err)
			}
		}
		tasks = tasks[:0]
	}

	for {
		select {
		case task, ok := <-u.readChan:
			if !ok {
				flush()
				return
			}
			tasks = append(tasks, task)
			if len(tasks) >= batchSize {
				flush()
			}
		case <-ticker.C:
			flush()
		case <-u.ctx.Done():
			flush()
			return
		}
	}
}

// createWorker 는 알림 생성 및 (추후) 푸시 발송 처리
func (u *notificationUsecase) createWorker() {
	defer u.wg.Done()

	for {
		select {
		case n, ok := <-u.createChan:
			if !ok {
				return
			}
			// 1. DB 저장
			if err := u.notificationRepo.Create(n); err != nil {
				log.Printf("Failed to create notification asynchronously: %v", err)
				continue
			}

			// 2. TODO: FCM 푸시 알림 발송 로직 연동
			// log.Printf("Notification created and push sent for user %d", n.UserID)

		case <-u.ctx.Done():
			return
		}
	}
}

func (u *notificationUsecase) GetNotifications(userID int64, limit int, cursor string) ([]domain.Notification, string, error) {
	if limit <= 0 {
		limit = 20
	}
	return u.notificationRepo.GetByUserID(userID, limit, cursor)
}

func (u *notificationUsecase) ReadNotification(id int64, userID int64) error {
	select {
	case u.readChan <- readTask{id: id, userID: userID}:
		return nil
	default:
		return u.notificationRepo.MarkAsRead(id, userID)
	}
}

func (u *notificationUsecase) ReadAllNotifications(userID int64) error {
	return u.notificationRepo.MarkAllAsRead(userID)
}

func (u *notificationUsecase) CreateNotification(notification *domain.Notification) error {
	// 채널에 던져서 비동기로 처리
	select {
	case u.createChan <- notification:
		return nil
	default:
		// 채널이 꽉 찼을 경우에만 동기 처리하여 유실 방지
		return u.notificationRepo.Create(notification)
	}
}

func (u *notificationUsecase) Close() {
	u.cancel()
	close(u.readChan)
	close(u.createChan)
	u.wg.Wait()
}
