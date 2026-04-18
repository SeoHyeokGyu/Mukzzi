package usecase

import (
	"context"
	"log/slog"
	"sync"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

// NotificationUsecase 는 알림 도메인의 비즈니스 로직을 정의합니다.
type NotificationUsecase interface {
	// GetNotifications 사용자의 알림 목록을 커서 기반 페이지네이션으로 조회합니다.
	GetNotifications(userID int64, limit int, cursor string) ([]domain.Notification, string, error)
	// ReadNotification 특정 알림을 읽음 처리합니다 (비동기 채널을 통해 처리됨).
	ReadNotification(id int64, userID int64) error
	// ReadAllNotifications 사용자의 모든 읽지 않은 알림을 즉시 읽음 처리합니다.
	ReadAllNotifications(userID int64) error
	// CreateNotification 새로운 알림을 생성합니다 (비동기 채널을 통해 DB 저장 및 SSE 브로드캐스트 수행).
	CreateNotification(notification *domain.Notification) error
	// Subscribe 실시간 알림 수신을 위한 채널을 구독합니다 (SSE 핸들러에서 사용).
	Subscribe(userID int64) (<-chan *domain.Notification, func())
	// Close 모든 백라운드 워커를 안전하게 종료합니다.
	Close()
}

type notificationUsecase struct {
	notificationRepo repository.NotificationRepository
	readChan         chan readTask             // 알림 읽음 처리 작업을 전달하는 채널
	createChan       chan *domain.Notification // 알림 생성 작업을 전달하는 채널

	// SSE 구독자 관리를 위한 동기화 객체
	mu          sync.RWMutex
	subscribers map[int64][]chan *domain.Notification // userID별로 열려있는 SSE 채널 목록

	wg     sync.WaitGroup
	ctx    context.Context
	cancel context.CancelFunc
}

// readTask 는 비동기 읽음 처리를 위한 최소 정보 단위입니다.
type readTask struct {
	id     int64
	userID int64
}

const (
	batchSize     = 100             // 읽음 처리 시 DB에 한 번에 반영할 최대 개수
	flushInterval = 5 * time.Second // DB 반영 주기 (메모리 버퍼 비우기 시간)
)

// NewNotificationUsecase 는 NotificationUsecase 의 인스턴스를 생성하고 백그라운드 워커를 시작합니다.
func NewNotificationUsecase(notificationRepo repository.NotificationRepository) NotificationUsecase {
	ctx, cancel := context.WithCancel(context.Background())
	u := &notificationUsecase{
		notificationRepo: notificationRepo,
		readChan:         make(chan readTask, 1000),            // 1000개까지 대기 가능
		createChan:       make(chan *domain.Notification, 500), // 500개까지 대기 가능
		subscribers:      make(map[int64][]chan *domain.Notification),
		ctx:              ctx,
		cancel:           cancel,
	}

	u.wg.Add(2)
	go u.readWorker()   // 읽음 처리 전용 워커 실행
	go u.createWorker() // 생성 및 전송 전용 워커 실행

	return u
}

// readWorker 는 알림 읽음 요청을 모아서 일정 주기마다 DB에 반영합니다 (DB 부하 감소).
func (u *notificationUsecase) readWorker() {
	defer u.wg.Done()
	ticker := time.NewTicker(flushInterval)
	defer ticker.Stop()

	tasks := make([]readTask, 0, batchSize)

	// flush 함수는 현재까지 모인 읽음 처리 작업을 DB에 실제 반영합니다.
	flush := func() {
		if len(tasks) == 0 {
			return
		}
		for _, task := range tasks {
			if err := u.notificationRepo.MarkAsRead(task.id, task.userID); err != nil {
				slog.Error("알림 읽음 처리 실패", slog.Int64("notification_id", task.id), slog.Any("error", err))
			}
		}
		tasks = tasks[:0] // 슬라이스 초기화
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

// createWorker 는 알림 생성 요청을 받아 DB에 저장하고, 실시간 스트림(SSE)으로 즉시 전송합니다.
func (u *notificationUsecase) createWorker() {
	defer u.wg.Done()

	for {
		select {
		case n, ok := <-u.createChan:
			if !ok {
				return
			}
			// 1. DB에 알림 저장
			if err := u.notificationRepo.Create(n); err != nil {
				slog.Error("알림 비동기 생성 실패", slog.Any("error", err))
				continue
			}

			// 2. 해당 유저가 온라인인 경우 SSE 로 실시간 전송
			u.broadcast(n)

		case <-u.ctx.Done():
			return
		}
	}
}

// broadcast 는 메모리상에 관리 중인 유저의 SSE 채널들로 알림을 전송합니다.
func (u *notificationUsecase) broadcast(n *domain.Notification) {
	u.mu.RLock() // 읽기 락 (구독자 목록 조회)
	defer u.mu.RUnlock()

	chans, ok := u.subscribers[n.UserID]
	if !ok {
		return // 유저가 현재 접속 중이지 않음
	}

	for _, ch := range chans {
		select {
		case ch <- n:
			// 전송 성공
		default:
			// 채널 버퍼가 꽉 찬 경우 (네트워크 지연 등) 무시하여 메인 로직 블로킹 방지
		}
	}
}

// Subscribe 는 특정 사용자를 위한 실시간 알림 스트림을 생성합니다.
// 반환된 채널을 통해 알림을 수신하며, 두 번째 반환값인 함수를 호출하여 구독을 해제할 수 있습니다.
func (u *notificationUsecase) Subscribe(userID int64) (<-chan *domain.Notification, func()) {
	u.mu.Lock() // 쓰기 락 (구독자 목록 수정)
	defer u.mu.Unlock()

	// 10개까지 버퍼링 가능한 채널 생성
	ch := make(chan *domain.Notification, 10)
	u.subscribers[userID] = append(u.subscribers[userID], ch)

	slog.Info("SSE 구독 시작", slog.Int64("user_id", userID), slog.Int("current_subscribers", len(u.subscribers[userID])))

	// sync.Once 를 사용하여 여러 경로(컨텍스트 종료, 하트비트 실패 등)에서
	// 동시에 구독 해제 요청이 오더라도 실제 정리 로직은 단 한 번만 안전하게 실행되도록 보장합니다.
	// 이는 이미 닫힌 채널을 다시 닫으려 할 때 발생하는 패닉(double close panic)을 원천 차단합니다.
	var once sync.Once
	// unsubscribe 함수는 클라이언트 연결 종료 시 호출되어야 합니다.
	unsubscribe := func() {
		once.Do(func() {
			u.mu.Lock()
			defer u.mu.Unlock()

			chans := u.subscribers[userID]
			for i, c := range chans {
				// Go에서 채널 비교(==)는 참조 값(메모리 주소) 비교입니다.
				// 이를 통해 수많은 연결 중 현재 종료된 특정 채널 객체를 정확히 식별합니다.
				if c == ch {
					// 해당 유저의 채널 리스트에서 자신을 제거 (Go의 슬라이스 요소 삭제 방식)
					u.subscribers[userID] = append(chans[:i], chans[i+1:]...)
					close(ch)
					break
				}
			}

			// 더 이상 구독 중인 채널이 없으면 맵에서 유저 키 삭제 (메모리 해제)
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
	// 채널에 작업을 던져 워커가 처리하게 함 (즉시 응답)
	select {
	case u.readChan <- readTask{id: id, userID: userID}:
		return nil
	default:
		// 채널이 꽉 찬 특수한 경우에만 직접 DB 업데이트 (동기 폴백)
		return u.notificationRepo.MarkAsRead(id, userID)
	}
}

func (u *notificationUsecase) ReadAllNotifications(userID int64) error {
	// 전체 읽음은 양이 많을 수 있으므로 즉시 DB에 반영
	return u.notificationRepo.MarkAllAsRead(userID)
}

func (u *notificationUsecase) CreateNotification(notification *domain.Notification) error {
	// 채널에 던져 워커가 저장 및 브로드캐스트 처리하게 함 (비차단)
	select {
	case u.createChan <- notification:
		return nil
	default:
		// 채널 꽉 참 발생 시 유실 방지를 위해 직접 저장
		return u.notificationRepo.Create(notification)
	}
}

func (u *notificationUsecase) Close() {
	u.cancel()
	close(u.readChan)
	close(u.createChan)
	u.wg.Wait()
}
