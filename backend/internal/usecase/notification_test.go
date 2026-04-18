package usecase

import (
	"testing"

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
	mockRepo := new(MockNotificationRepository)
	uc := NewNotificationUsecase(mockRepo)

	t.Run("알림 읽음 처리 성공", func(t *testing.T) {
		userID := int64(123)
		id := int64(1)

		mockRepo.On("MarkAsRead", id, userID).Return(nil)

		err := uc.ReadNotification(id, userID)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})
}

func TestNotificationUsecase_ReadAllNotifications(t *testing.T) {
	mockRepo := new(MockNotificationRepository)
	uc := NewNotificationUsecase(mockRepo)

	t.Run("전체 알림 읽음 처리 성공", func(t *testing.T) {
		userID := int64(123)

		mockRepo.On("MarkAllAsRead", userID).Return(nil)

		err := uc.ReadAllNotifications(userID)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})
}
