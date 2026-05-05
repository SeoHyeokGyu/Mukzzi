package usecase

import (
	"testing"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

type MockNotificationRepository struct {
	mock.Mock
}

func (m *MockNotificationRepository) Create(notification *domain.Notification) error {
	args := m.Called(notification)
	return args.Error(0)
}

func (m *MockNotificationRepository) GetByUserID(userID int64, limit int, cursor string) ([]domain.Notification, string, error) {
	args := m.Called(userID, limit, cursor)
	return args.Get(0).([]domain.Notification), args.String(1), args.Error(2)
}

func (m *MockNotificationRepository) MarkAsRead(id int64, userID int64) error {
	args := m.Called(id, userID)
	return args.Error(0)
}

func (m *MockNotificationRepository) MarkAllAsRead(userID int64) error {
	args := m.Called(userID)
	return args.Error(0)
}

func TestNotificationUsecase_GetNotifications(t *testing.T) {
	mockRepo := new(MockNotificationRepository)
	uc := NewNotificationUsecase(mockRepo)
	defer uc.Close()

	t.Run("알림 목록 조회 성공", func(t *testing.T) {
		userID := int64(123)
		limit := 20
		cursor := ""
		notifications := []domain.Notification{
			{BaseDomain: domain.BaseDomain{ID: 1}, UserID: userID, Title: "Test"},
		}

		mockRepo.On("GetByUserID", userID, limit, cursor).Return(notifications, "next-cursor", nil)

		res, next, err := uc.GetNotifications(userID, limit, cursor)

		assert.NoError(t, err)
		assert.Equal(t, notifications, res)
		assert.Equal(t, "next-cursor", next)
		mockRepo.AssertExpectations(t)
	})
}

func TestNotificationUsecase_ReadNotification(t *testing.T) {
	t.Run("알림 읽음 처리 성공 (비동기)", func(t *testing.T) {
		mockRepo := new(MockNotificationRepository)
		uc := NewNotificationUsecase(mockRepo)

		userID := int64(123)
		id := int64(1)

		mockRepo.On("MarkAsRead", id, userID).Return(nil)

		err := uc.ReadNotification(id, userID)
		assert.NoError(t, err)

		// 비동기 처리를 위해 잠시 대기하거나 Close 호출로 Flush 유도
		time.Sleep(50 * time.Millisecond)
		uc.Close()

		mockRepo.AssertExpectations(t)
	})
}

func TestNotificationUsecase_ReadAllNotifications(t *testing.T) {
	mockRepo := new(MockNotificationRepository)
	uc := NewNotificationUsecase(mockRepo)
	defer uc.Close()

	t.Run("전체 알림 읽음 처리 성공", func(t *testing.T) {
		userID := int64(123)

		mockRepo.On("MarkAllAsRead", userID).Return(nil)

		err := uc.ReadAllNotifications(userID)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})
}

func TestNotificationUsecase_CreateNotification(t *testing.T) {
	t.Run("알림 생성 성공 (비동기)", func(t *testing.T) {
		mockRepo := new(MockNotificationRepository)
		uc := NewNotificationUsecase(mockRepo)

		notification := &domain.Notification{
			UserID:  123,
			Title:   "New Notification",
			Content: "Hello World",
		}

		mockRepo.On("Create", notification).Return(nil)

		err := uc.CreateNotification(notification)
		assert.NoError(t, err)

		time.Sleep(50 * time.Millisecond) // 워커가 채널에서 읽을 시간 확보
		uc.Close() // 워커 종료 및 채널 flush 대기

		mockRepo.AssertExpectations(t)
	})
}
