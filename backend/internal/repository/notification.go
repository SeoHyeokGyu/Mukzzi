package repository

import (
	"strconv"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
)

type NotificationRepository interface {
	Create(notification *domain.Notification) error
	GetByUserID(userID int64, limit int, cursor string) ([]domain.Notification, string, error)
	MarkAsRead(id int64, userID int64) error
	MarkAllAsRead(userID int64) error
}

type notificationRepository struct {
	db *gorm.DB
}

func NewNotificationRepository(db *gorm.DB) NotificationRepository {
	return &notificationRepository{db: db}
}

func (r *notificationRepository) Create(notification *domain.Notification) error {
	return r.db.Create(notification).Error
}

func (r *notificationRepository) GetByUserID(userID int64, limit int, cursor string) ([]domain.Notification, string, error) {
	var notifications []domain.Notification
	query := r.db.Where("user_id = ?", userID).Order("id DESC").Limit(limit)

	if cursor != "" {
		if id, err := strconv.ParseInt(cursor, 10, 64); err == nil {
			query = query.Where("id < ?", id)
		}
	}

	err := query.Preload("Sender").Find(&notifications).Error
	if err != nil {
		return nil, "", err
	}

	nextCursor := ""
	if len(notifications) == limit {
		nextCursor = notifications[len(notifications)-1].IDString()
	}

	return notifications, nextCursor, nil
}

func (r *notificationRepository) MarkAsRead(id int64, userID int64) error {
	now := time.Now()
	return r.db.Model(&domain.Notification{}).
		Where("id = ? AND user_id = ?", id, userID).
		Updates(map[string]interface{}{
			"is_read": true,
			"read_at": &now,
		}).Error
}

func (r *notificationRepository) MarkAllAsRead(userID int64) error {
	now := time.Now()
	return r.db.Model(&domain.Notification{}).
		Where("user_id = ? AND is_read = ?", userID, false).
		Updates(map[string]interface{}{
			"is_read": true,
			"read_at": &now,
		}).Error
}
