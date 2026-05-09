package dto

import (
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
)

// BadgeResponse API 응답용 뱃지 정보
type BadgeResponse struct {
	ID          int64      `json:"id,string"`
	Code        string     `json:"code"`
	Name        string     `json:"name"`
	Description string     `json:"description"`
	IconURL     string     `json:"icon_url"`
	Progress    int        `json:"progress"`
	Target      int        `json:"target"`
	Acquired    bool       `json:"acquired"`
	AcquiredAt  *time.Time `json:"acquired_at,omitempty"`
}

// CharacterCollectionResponse 먹찌 도감 응답
type CharacterCollectionResponse struct {
	ID         int64     `json:"id,string"`
	BodyType   int       `json:"body_type"`
	Muscle     int       `json:"muscle"`
	SkinTone   int       `json:"skin_tone"`
	Expression int       `json:"expression"`
	AchievedAt time.Time `json:"achieved_at"`
}

// MasteryResponse 마스터리 응답
type MasteryResponse struct {
	ID           int64               `json:"id,string"`
	MenuID       int64               `json:"menu_id,string"`
	MenuName     string              `json:"menu_name"`
	MenuCategory domain.MenuCategory `json:"menu_category"`
	EatCount     int                 `json:"eat_count"`
	Grade        domain.MasteryGrade `json:"grade"`
	FirstEatenAt time.Time           `json:"first_eaten_at"`
	LastEatenAt  time.Time           `json:"last_eaten_at"`
}

// TitleResponse 칭호 응답
type TitleResponse struct {
	ID          int64      `json:"id,string"`
	Code        string     `json:"code"`
	Name        string     `json:"name"`
	Description string     `json:"description"`
	Acquired    bool       `json:"acquired"`
	AchievedAt  *time.Time `json:"achieved_at,omitempty"`
	IsEquipped  bool       `json:"is_equipped"`
}

// EquipTitleRequest 칭호 장착/해제 요청 (title_id가 null이면 해제)
type EquipTitleRequest struct {
	TitleID *string `json:"title_id"`
}

// RewardResponse 보상 아이템 응답
type RewardResponse struct {
	ID          int64             `json:"id,string"`
	RewardType  domain.RewardType `json:"reward_type"`
	Name        string            `json:"name"`
	Description string            `json:"description"`
	AssetURL    string            `json:"asset_url"`
	Acquired    bool              `json:"acquired"`
	AchievedAt  *time.Time        `json:"achieved_at,omitempty"`
}
