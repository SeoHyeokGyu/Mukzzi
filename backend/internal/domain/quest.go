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
	QuestStatusExpired   QuestStatus = "EXPIRED"
)

// QuestDefinition 은 시스템에 정의된 퀘스트의 템플릿입니다.
type QuestDefinition struct {
	BaseDomain
	Code          string        `gorm:"column:code;uniqueIndex;not null"` // 퀘스트 식별 코드 (예: DAILY_MEAL_1)
	Type          QuestType     `gorm:"column:type;not null"`             // DAILY, WEEKLY, ACHIEVEMENT
	Category      QuestCategory `gorm:"column:category;not null"`         // MEAL, SOCIAL, GROWTH
	Title         string        `gorm:"column:title;not null"`            // 퀘스트 제목
	Description   string        `gorm:"column:description"`               // 상세 설명
	TargetCount   int           `gorm:"column:target_count;not null"`     // 목표 수치
	RewardPoint   int           `gorm:"column:reward_point;default:0"`    // 보상 포인트
	RewardExp     int           `gorm:"column:reward_exp;default:0"`      // 보상 경험치
	RewardTitleID *int64        `gorm:"column:reward_title_id"`           // 보상 칭호 ID (Optional)
	RewardBadgeID *int64        `gorm:"column:reward_badge_id"`           // 보상 뱃지 ID (Optional)
	RewardItemID  *int64        `gorm:"column:reward_item_id"`            // 보상 코스메틱 아이템 ID (Optional)
	IsActive      bool          `gorm:"column:is_active;default:true"`    // 활성화 여부
}

func (QuestDefinition) TableName() string { return "quests" }

// UserQuest 는 사용자가 할당받은 구체적인 퀘스트 진행 상태를 나타냅니다.
type UserQuest struct {
	BaseDomain
	UserID       int64       `gorm:"column:user_id;not null;uniqueIndex:idx_user_quest,where:deleted_at IS NULL;index:idx_quest_user_status,where:deleted_at IS NULL"`
	QuestID      int64       `gorm:"column:quest_id;not null;uniqueIndex:idx_user_quest,where:deleted_at IS NULL"`
	CurrentCount int         `gorm:"column:current_count;default:0"` // 현재 진행 수치
	Status       QuestStatus `gorm:"column:status;default:'PROGRESS';index:idx_quest_user_status,where:deleted_at IS NULL"`
	AssignedAt   time.Time   `gorm:"column:assigned_at;not null"`     // 할당 일시
	ExpiresAt    time.Time   `gorm:"column:expires_at;not null"`      // 만료 일시 (업적은 먼 미래)

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
	GetAvailableQuestsByType(ctx context.Context, qType QuestType) ([]QuestDefinition, error)
	DeleteQuestsByUserIDAndType(ctx context.Context, userID int64, qType QuestType) error
	GetUserQuestByID(ctx context.Context, id int64) (*UserQuest, error)
	UpdateExpiredQuests(ctx context.Context, now time.Time) (int64, error)
}
