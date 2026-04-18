package dto

import (
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/datatypes"
)

type NotificationResponse struct {
	ID        int64                   `json:"id,string"`
	UserID    int64                   `json:"user_id,string"`
	SenderID  *int64                  `json:"sender_id,string,omitempty"`
	Type      domain.NotificationType `json:"type"`
	Title     string                  `json:"title"`
	Content   string                  `json:"content"`
	LinkURL   string                  `json:"link_url,omitempty"`
	IsRead    bool                    `json:"is_read"`
	ReadAt    *time.Time              `json:"read_at,omitempty"`
	Metadata  datatypes.JSON          `json:"metadata,omitempty"`
	CreatedAt time.Time               `json:"created_at"`

	Sender *UserProfileResponse `json:"sender,omitempty"`
}

func ToNotificationResponse(n *domain.Notification) NotificationResponse {
	var sender *UserProfileResponse
	if n.Sender != nil {
		sender = &UserProfileResponse{
			ID:              n.Sender.ID,
			Nickname:        n.Sender.Nickname,
			ProfileImageURL: n.Sender.ProfileImageURL,
			PrivacyLevel:    n.Sender.PrivacyLevel,
		}
	}

	return NotificationResponse{
		ID:        n.ID,
		UserID:    n.UserID,
		SenderID:  n.SenderID,
		Type:      n.Type,
		Title:     n.Title,
		Content:   n.Content,
		LinkURL:   n.LinkURL,
		IsRead:    n.IsRead,
		ReadAt:    n.ReadAt,
		Metadata:  n.Metadata,
		CreatedAt: n.CreatedAt,
		Sender:    sender,
	}
}

func ToNotificationListResponse(notifications []domain.Notification) []NotificationResponse {
	res := make([]NotificationResponse, len(notifications))
	for i, n := range notifications {
		res[i] = ToNotificationResponse(&n)
	}
	return res
}
