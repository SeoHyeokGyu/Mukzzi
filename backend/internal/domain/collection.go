package domain

import "time"

// --- Mastery ---

// MasteryGrade 마스터리 등급
type MasteryGrade string

const (
	MasteryBeginner MasteryGrade = "BEGINNER"
	MasteryMania    MasteryGrade = "MANIA"
	MasteryArtisan  MasteryGrade = "ARTISAN"
	MasteryMaster   MasteryGrade = "MASTER"
)

// CalcMasteryGrade 섭취 횟수로부터 마스터리 등급 계산
func CalcMasteryGrade(eatCount int) MasteryGrade {
	switch {
	case eatCount >= 50:
		return MasteryMaster
	case eatCount >= 20:
		return MasteryArtisan
	case eatCount >= 5:
		return MasteryMania
	default:
		return MasteryBeginner
	}
}

// Mastery 메뉴 마스터리
type Mastery struct {
	BaseDomain
	UserID       int64        `gorm:"not null;uniqueIndex:idx_mastery_user_menu"`
	MenuID       int64        `gorm:"not null;uniqueIndex:idx_mastery_user_menu"`
	EatCount     int          `gorm:"default:0"`
	Grade        MasteryGrade `gorm:"type:varchar(20);default:'BEGINNER'"`
	FirstEatenAt time.Time    `gorm:"not null"`
	LastEatenAt  time.Time    `gorm:"not null"`
	Menu         Menu         `gorm:"foreignKey:MenuID"`
}

func (Mastery) TableName() string { return "masteries" }

// --- Title ---

// Title 칭호 정의
type Title struct {
	BaseDomain
	Code        string `gorm:"uniqueIndex;not null;type:varchar(50)"`
	Name        string `gorm:"not null;type:varchar(50)"`
	Description string `gorm:"type:text"`
}

func (Title) TableName() string { return "titles" }

// UserTitle 사용자 칭호 획득 기록
type UserTitle struct {
	BaseDomain
	UserID     int64     `gorm:"not null;uniqueIndex:idx_user_title"`
	TitleID    int64     `gorm:"not null;uniqueIndex:idx_user_title"`
	AchievedAt time.Time `gorm:"not null"`
	Title      Title     `gorm:"foreignKey:TitleID"`
}

func (UserTitle) TableName() string { return "user_titles" }

// --- Reward ---

// RewardType 보상 유형
type RewardType string

const (
	RewardBackground RewardType = "BACKGROUND"
	RewardEffect     RewardType = "EFFECT"
	RewardMotion     RewardType = "MOTION"
	RewardAccessory  RewardType = "ACCESSORY"
)

// Reward 보상 아이템
type Reward struct {
	BaseDomain
	RewardType  RewardType `gorm:"type:varchar(20);not null"`
	Name        string     `gorm:"not null;type:varchar(50)"`
	Description string     `gorm:"type:text"`
	AssetURL    string     `gorm:"type:text"`
}

func (Reward) TableName() string { return "rewards" }

// UserReward 사용자 보상 획득 기록
type UserReward struct {
	BaseDomain
	UserID     int64     `gorm:"not null;uniqueIndex:idx_user_reward"`
	RewardID   int64     `gorm:"not null;uniqueIndex:idx_user_reward"`
	QuestID    *int64    `gorm:"type:bigint"`
	AchievedAt time.Time `gorm:"not null"`
	Reward     Reward    `gorm:"foreignKey:RewardID"`
}

func (UserReward) TableName() string { return "user_rewards" }

// --- Badge ---

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
	UserID     int64     `gorm:"index:idx_user_badge,unique"`
	BadgeID    int64     `gorm:"index:idx_user_badge,unique"`
	AcquiredAt time.Time `gorm:"not null"`
	Badge      Badge     `gorm:"foreignKey:BadgeID"`
}

// GetBadgesQuery 뱃지 목록 조회 쿼리
type GetBadgesQuery struct {
	UserID          int64
	IncludeAcquired bool
	Cursor          string
	Limit           int
}

// GetBadgesResult 뱃지 목록 조회 결과
type GetBadgesResult struct {
	Badges      []Badge
	AcquiredMap map[int64]*UserBadge
	NextCursor  string
	HasNext     bool
	Limit       int
}
