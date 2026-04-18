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
	Close() // 워커 종료를 위해 추가
}

type notificationUsecase struct {
	notificationRepo repository.NotificationRepository
	readChan         chan readTask
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
		readChan:         make(chan readTask, 1000), // 버퍼링된 채널
		ctx:              ctx,
		cancel:           cancel,
	}

	u.wg.Add(1)
	go u.readWorker() // 백그라운드 워커 시작

	return u
}

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
			// 채널에 남은 데이터를 소비하기 위해 루프를 더 돌릴 수도 있지만,
			// 여기서는 일단 flush 후 종료. readChan이 닫히면 위 case ok=false에서 처리됨.
			flush()
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
		// 채널이 꽉 찼을 경우 직접 실행 (동기)
		return u.notificationRepo.MarkAsRead(id, userID)
	}
}

func (u *notificationUsecase) ReadAllNotifications(userID int64) error {
	return u.notificationRepo.MarkAllAsRead(userID)
}

func (u *notificationUsecase) CreateNotification(notification *domain.Notification) error {
	return u.notificationRepo.Create(notification)
}

func (u *notificationUsecase) Close() {
	u.cancel()
	close(u.readChan)
	u.wg.Wait()
}
