package domain

import (
	"time"

	"gorm.io/datatypes"
)

type (
	ActivityLevel string
	DietGoal      string
	PrivacyLevel  string
)

const (
	ActivityLow      ActivityLevel = "LOW"
	ActivityModerate ActivityLevel = "MODERATE"
	ActivityHigh     ActivityLevel = "HIGH"
	ActivityVeryHigh ActivityLevel = "VERY_HIGH"

	GoalDiet     DietGoal = "DIET"
	GoalMaintain DietGoal = "MAINTAIN"
	GoalBulk     DietGoal = "BULK"

	PrivacyPublic  PrivacyLevel = "PUBLIC"
	PrivacyFriends PrivacyLevel = "FRIENDS"
	PrivacyPrivate PrivacyLevel = "PRIVATE"
)

// User 는 사용자 기본 계정 정보를 정의합니다.
type User struct {
	BaseDomain
	Username string `gorm:"uniqueIndex;not null;type:varchar(50)" json:"username"`
	Email    string `gorm:"uniqueIndex;not null;type:varchar(100)" json:"email"`
	Password string `gorm:"not null;type:varchar(255)" json:"-"`
	Nickname string `gorm:"uniqueIndex;not null;type:varchar(50)" json:"nickname"`

	ProfileImageURL string     `gorm:"type:text" json:"profile_image_url"`
	LastLoginAt     *time.Time `json:"last_login_at"`
	Point           int        `gorm:"default:0" json:"point"`

	Provider   *string `gorm:"type:varchar(20)" json:"provider"`
	ProviderID *string `gorm:"uniqueIndex;type:varchar(100)" json:"provider_id"`

	// 설정
	EquippedTitleID      *int64         `gorm:"type:bigint" json:"equipped_title_id,string"`
	PrivacyLevel         PrivacyLevel   `gorm:"type:varchar(20);default:'PUBLIC'" json:"privacy_level"`
	NotificationSettings datatypes.JSON `gorm:"type:jsonb;default:'{}'" json:"notification_settings"`

	// 연관 관계 (Has One)
	Body          *UserBody          `gorm:"foreignKey:UserID" json:"body,omitempty"`
	NutritionGoal *UserNutritionGoal `gorm:"foreignKey:UserID" json:"nutrition_goal,omitempty"`
}

// UserBody 는 사용자의 신체 정보를 저장하며, 이력 관리가 가능하도록 설계되었습니다.
type UserBody struct {
	BaseDomain
	UserID        int64         `gorm:"index;not null" json:"user_id,string"`
	Height        float64       `json:"height"`
	Weight        float64       `json:"weight"`
	ActivityLevel ActivityLevel `gorm:"type:varchar(20)" json:"activity_level"`
}

// UserNutritionGoal 은 사용자의 영양 목표 수치를 정의합니다.
type UserNutritionGoal struct {
	BaseDomain
	UserID             int64    `gorm:"uniqueIndex;not null" json:"user_id,string"`
	Goal               DietGoal `gorm:"type:varchar(20)" json:"goal"`
	DailyKcalTarget    int      `json:"daily_kcal_target"`
	DailyCarbsTarget   int      `json:"daily_carbs_target"`
	DailyProteinTarget int      `json:"daily_protein_target"`
	DailyFatTarget     int      `json:"daily_fat_target"`
}

func (User) TableName() string              { return "users" }
func (UserBody) TableName() string          { return "user_bodies" }
func (UserNutritionGoal) TableName() string { return "user_nutrition_goals" }
