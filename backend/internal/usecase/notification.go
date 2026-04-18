package usecase

import (
	"context"
	"log/slog"
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
	Subscribe(userID int64) (<-chan *domain.Notification, func())
	Close()
}

type notificationUsecase struct {
	notificationRepo repository.NotificationRepository
	readChan         chan readTask
	createChan       chan *domain.Notification

	mu          sync.RWMutex
	subscribers map[int64][]chan *domain.Notification

	wg     sync.WaitGroup
	ctx    context.Context
	cancel context.CancelFunc
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
		createChan:       make(chan *domain.Notification, 500),
		subscribers:      make(map[int64][]chan *domain.Notification),
		ctx:              ctx,
		cancel:           cancel,
	}

	u.wg.Add(2)
	go u.readWorker()
	go u.createWorker()

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
				slog.Error("알림 읽음 처리 실패", slog.Int64("notification_id", task.id), slog.Any("error", err))
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

func (u *notificationUsecase) createWorker() {
	defer u.wg.Done()

	for {
		select {
		case n, ok := <-u.createChan:
			if !ok {
				return
			}
			if err := u.notificationRepo.Create(n); err != nil {
				slog.Error("알림 비동기 생성 실패", slog.Any("error", err))
				continue
			}

			u.broadcast(n)

		case <-u.ctx.Done():
			return
		}
	}
}

func (u *notificationUsecase) broadcast(n *domain.Notification) {
	u.mu.RLock()
	defer u.mu.RUnlock()

	chans, ok := u.subscribers[n.UserID]
	if !ok {
		return
	}

	for _, ch := range chans {
		select {
		case ch <- n:
		default:
			// 버퍼 꽉 참 무시
		}
	}
}

func (u *notificationUsecase) Subscribe(userID int64) (<-chan *domain.Notification, func()) {
	u.mu.Lock()
	defer u.mu.Unlock()

	ch := make(chan *domain.Notification, 10)
	u.subscribers[userID] = append(u.subscribers[userID], ch)

	slog.Info("SSE 구독 시작", slog.Int64("user_id", userID), slog.Int("current_subscribers", len(u.subscribers[userID])))

	var once sync.Once
	unsubscribe := func() {
		once.Do(func() {
			u.mu.Lock()
			defer u.mu.Unlock()

			chans := u.subscribers[userID]
			for i, c := range chans {
				if c == ch {
					u.subscribers[userID] = append(chans[:i], chans[i+1:]...)
					close(ch)
					break
				}
			}

			subCount := len(u.subscribers[userID])
			if subCount == 0 {
				delete(u.subscribers, userID)
			}
			slog.Info("SSE 구독 해제", slog.Int64("user_id", userID), slog.Int("remaining_subscribers", subCount))
		})
	}

	return ch, unsubscribe
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
	select {
	case u.createChan <- notification:
		return nil
	default:
		return u.notificationRepo.Create(notification)
	}
}

func (u *notificationUsecase) Close() {
	u.cancel()
	close(u.readChan)
	close(u.createChan)
	u.wg.Wait()
}
