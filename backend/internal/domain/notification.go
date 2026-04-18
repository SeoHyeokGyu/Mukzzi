package domain

import (
	"time"

	"gorm.io/datatypes"
)

type NotificationType string

const (
	NotificationTypeFriendRequest   NotificationType = "FRIEND_REQUEST"
	NotificationTypeFriendAccepted  NotificationType = "FRIEND_ACCEPTED"
	NotificationTypeNudge           NotificationType = "NUDGE"
	NotificationTypeGuestbook       NotificationType = "GUESTBOOK"
	NotificationTypeLevelUp         NotificationType = "LEVEL_UP"
	NotificationTypeBadgeAcquired   NotificationType = "BADGE_ACQUIRED"
	NotificationTypeMealTag         NotificationType = "MEAL_TAG"
	NotificationTypeMealTagAccepted NotificationType = "MEAL_TAG_ACCEPTED"
)

type Notification struct {
	BaseDomain
	UserID   int64            `gorm:"index;not null" json:"user_id,string"`
	SenderID *int64           `gorm:"index" json:"sender_id,string,omitempty"`
	Type     NotificationType `gorm:"type:varchar(50);not null" json:"type"`
	Title    string           `gorm:"type:varchar(100);not null" json:"title"`
	Content  string           `gorm:"type:text;not null" json:"content"`
	LinkURL  string           `gorm:"type:text" json:"link_url,omitempty"`
	IsRead   bool             `gorm:"default:false;not null" json:"is_read"`
	ReadAt   *time.Time       `json:"read_at,omitempty"`
	Metadata datatypes.JSON   `gorm:"type:jsonb" json:"metadata,omitempty"`

	// Optional relation
	Sender *User `gorm:"foreignKey:SenderID" json:"sender,omitempty"`
}

func (Notification) TableName() string { return "notifications" }
