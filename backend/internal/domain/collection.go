package domain

import "time"

// Badge 뱃지 정의
type Badge struct {
	BaseDomain
	Code        string `gorm:"uniqueIndex;not null"`
	Name        string `gorm:"not null"`
	Description string
	IconURL     string
}

// UserBadge 사용자 뱃지 획득 기록
type UserBadge struct {
	BaseDomain
	UserID    int64     `gorm:"index:idx_user_badge,unique"`
	BadgeID   int64     `gorm:"index:idx_user_badge,unique"`
	AcquiredAt time.Time `gorm:"not null"`
	Badge     Badge     `gorm:"foreignKey:BadgeID"`
}

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

// GetBadgesQuery 뱃지 목록 조회 쿼리
type GetBadgesQuery struct {
	UserID            int64
	IncludeAcquired   bool
	Cursor            string
	Limit             int
}

// GetBadgesResult 뱃지 목록 조회 결과
type GetBadgesResult struct {
	Badges     []BadgeResponse
	NextCursor string
	HasNext    bool
	Limit      int
}
