package domain

import "time"

type EvolutionStage string
type PenaltyStatus string

const (
	EvolutionEgg       EvolutionStage = "EGG"
	EvolutionBaby      EvolutionStage = "BABY"
	EvolutionTeen      EvolutionStage = "TEEN"
	EvolutionAdult     EvolutionStage = "ADULT"
	EvolutionLegendary EvolutionStage = "LEGENDARY"

	PenaltyNormal  PenaltyStatus = "NORMAL"
	PenaltyHungry  PenaltyStatus = "HUNGRY"
	PenaltyStarved PenaltyStatus = "STARVED"
)

// Character 는 사용자의 현재 먹찌 상태를 정의합니다.
type Character struct {
	BaseDomain
	UserID               int64          `gorm:"not null;uniqueIndex" json:"user_id,string"`
	Name                 string         `gorm:"not null;type:varchar(50)" json:"name"`
	Level                int            `gorm:"default:1" json:"level"`
	Exp                  int            `gorm:"default:0" json:"exp"`
	EvolutionStage       EvolutionStage `gorm:"type:varchar(20);default:'EGG'" json:"evolution_stage"`
	BodyType             int            `gorm:"default:3" json:"body_type"`
	Muscle               int            `gorm:"default:3" json:"muscle"`
	SkinTone             int            `gorm:"default:3" json:"skin_tone"`
	Expression           int            `gorm:"default:3" json:"expression"`
	PenaltyStatus        PenaltyStatus  `gorm:"type:varchar(20);default:'NORMAL'" json:"penalty_status"`
	LastRecordedAt       *time.Time     `json:"last_recorded_at"`
	EquippedBackgroundID *int64         `gorm:"type:bigint" json:"equipped_background_id,string"`
	EquippedAccessoryID  *int64         `gorm:"type:bigint" json:"equipped_accessory_id,string"`

	// 연관 관계
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
