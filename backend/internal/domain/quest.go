package domain

import (
	"context"
	"time"
)

type QuestType string

const (
	QuestTypeDaily       QuestType = "DAILY"
	QuestTypeWeekly      QuestType = "WEEKLY"
	QuestTypeAchievement QuestType = "ACHIEVEMENT"
)

type QuestCategory string

const (
	QuestCategoryMeal   QuestCategory = "MEAL"
	QuestCategorySocial QuestCategory = "SOCIAL"
	QuestCategoryGrowth QuestCategory = "GROWTH"
)

type QuestStatus string

const (
	QuestStatusProgress  QuestStatus = "PROGRESS"
	QuestStatusCompleted QuestStatus = "COMPLETED"
	QuestStatusClaimed   QuestStatus = "CLAIMED"
)

type QuestDefinition struct {
	BaseDomain
	Code          string        `gorm:"column:code;uniqueIndex;not null"`
	Type          QuestType     `gorm:"column:type;not null"`
	Category      QuestCategory `gorm:"column:category;not null"`
	Title         string        `gorm:"column:title;not null"`
	Description   string        `gorm:"column:description"`
	TargetCount   int           `gorm:"column:target_count;not null"`
	RewardPoint   int           `gorm:"column:reward_point;default:0"`
	RewardExp     int           `gorm:"column:reward_exp;default:0"`
	RewardTitleID *int64        `gorm:"column:reward_title_id"`
	RewardBadgeID *int64        `gorm:"column:reward_badge_id"`
	IsActive      bool          `gorm:"column:is_active;default:true"`
}

func (QuestDefinition) TableName() string { return "quests" }

type UserQuest struct {
	BaseDomain
	UserID       int64       `gorm:"column:user_id;not null;uniqueIndex:idx_user_quest"`
	QuestID      int64       `gorm:"column:quest_id;not null;uniqueIndex:idx_user_quest"`
	CurrentCount int         `gorm:"column:current_count;default:0"`
	Status       QuestStatus `gorm:"column:status;default:'PROGRESS'"`
	AssignedAt   time.Time   `gorm:"column:assigned_at;not null"`
	ExpiresAt    time.Time   `gorm:"column:expires_at;not null"`

	Quest *QuestDefinition `gorm:"foreignKey:QuestID"`
}

func (UserQuest) TableName() string { return "user_quests" }

type QuestRepository interface {
	GetByID(ctx context.Context, id int64) (*QuestDefinition, error)
	GetActiveQuestsByUserID(ctx context.Context, userID int64) ([]UserQuest, error)
	GetQuestDefinitionByCode(ctx context.Context, code string) (*QuestDefinition, error)
	UpdateUserQuest(ctx context.Context, uq *UserQuest) error
	CreateUserQuest(ctx context.Context, uq *UserQuest) error
	GetAvailableDailyQuests(ctx context.Context, limit int) ([]QuestDefinition, error)
	DeleteDailyQuestsByUserID(ctx context.Context, userID int64) error
	GetUserQuestByID(ctx context.Context, id int64) (*UserQuest, error)
}
