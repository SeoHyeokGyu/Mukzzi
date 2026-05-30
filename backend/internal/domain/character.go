package domain

import "time"

type PenaltyStatus string

const (
	PenaltyNormal   PenaltyStatus = "NORMAL"
	PenaltyHungry   PenaltyStatus = "HUNGRY"
	PenaltyStarving PenaltyStatus = "STARVING"
	PenaltyWeakened PenaltyStatus = "WEAKENED"
)

// Character 는 사용자의 현재 먹찌 상태를 정의합니다.
type Character struct {
	BaseDomain
	UserID                   int64         `gorm:"not null;uniqueIndex" json:"user_id,string"`
	Name                     string        `gorm:"not null;type:varchar(50)" json:"name"`
	BodyType                 int           `gorm:"default:3" json:"body_type"`
	Muscle                   int           `gorm:"default:3" json:"muscle"`
	SkinTone                 int           `gorm:"default:3" json:"skin_tone"`
	Expression               int           `gorm:"default:3" json:"expression"`
	PenaltyStatus            PenaltyStatus `gorm:"type:varchar(20);default:'NORMAL'" json:"penalty_status"`
	Level                    int           `gorm:"default:1" json:"level"`
	Exp                      int           `gorm:"default:0" json:"exp"`
	StreakDays               int           `gorm:"default:0" json:"streak_days"`
	NutritionAchievementDays int           `gorm:"default:0" json:"nutrition_achievement_days"`
	LastRecordedAt           *time.Time    `json:"last_recorded_at"`
	EquippedBackgroundID     *int64        `gorm:"type:bigint" json:"equipped_background_id,string"`
	EquippedAccessoryID      *int64        `gorm:"type:bigint" json:"equipped_accessory_id,string"`

	User               *User   `gorm:"foreignKey:UserID" json:"-"`
	EquippedBackground *Reward `gorm:"foreignKey:EquippedBackgroundID" json:"equipped_background,omitempty"`
	EquippedAccessory  *Reward `gorm:"foreignKey:EquippedAccessoryID" json:"equipped_accessory,omitempty"`
}

func (Character) TableName() string {
	return "characters"
}

// CharacterCollection 은 사용자가 획득한 먹찌 외형 도감 기록입니다.
type CharacterCollection struct {
	BaseDomain
	UserID     int64     `gorm:"not null;uniqueIndex:idx_char_collection"`
	BodyType   int       `gorm:"not null;uniqueIndex:idx_char_collection"`
	Muscle     int       `gorm:"not null;uniqueIndex:idx_char_collection"`
	SkinTone   int       `gorm:"not null;uniqueIndex:idx_char_collection"`
	Expression int       `gorm:"not null;uniqueIndex:idx_char_collection"`
	AchievedAt time.Time `gorm:"not null"`
}

func (CharacterCollection) TableName() string {
	return "character_collections"
}
