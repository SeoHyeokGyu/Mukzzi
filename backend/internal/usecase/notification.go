package usecase

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

type NotificationUsecase interface {
	GetNotifications(userID int64, limit int, cursor string) ([]domain.Notification, string, error)
	ReadNotification(id int64, userID int64) error
	ReadAllNotifications(userID int64) error
	CreateNotification(notification *domain.Notification) error
}

type notificationUsecase struct {
	notificationRepo repository.NotificationRepository
}

func NewNotificationUsecase(notificationRepo repository.NotificationRepository) NotificationUsecase {
	return &notificationUsecase{
		notificationRepo: notificationRepo,
	}
}

func (u *notificationUsecase) GetNotifications(userID int64, limit int, cursor string) ([]domain.Notification, string, error) {
	if limit <= 0 {
		limit = 20
	}
	return u.notificationRepo.GetByUserID(userID, limit, cursor)
}

func (u *notificationUsecase) ReadNotification(id int64, userID int64) error {
	return u.notificationRepo.MarkAsRead(id, userID)
}

func (u *notificationUsecase) ReadAllNotifications(userID int64) error {
	return u.notificationRepo.MarkAllAsRead(userID)
}

func (u *notificationUsecase) CreateNotification(notification *domain.Notification) error {
	return u.notificationRepo.Create(notification)
}
