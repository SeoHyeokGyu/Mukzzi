package dto

import "time"

// BadgeResponse API 응답용 뱃지 정보
type BadgeResponse struct {
	ID          int64      `json:"id,string"`
	Code        string     `json:"code"`
	Name        string     `json:"name"`
	Description string     `json:"description"`
	IconURL     string     `json:"icon_url"`
	Acquired    bool       `json:"acquired"`
	AcquiredAt  *time.Time `json:"acquired_at,omitempty"`
}
