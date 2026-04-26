package domain

import "time"

// ─────────────────────────────────────────
// 상수 정의
// ─────────────────────────────────────────

type MealType string

const (
	MealTypeBreakfast MealType = "BREAKFAST"
	MealTypeLunch     MealType = "LUNCH"
	MealTypeDinner    MealType = "DINNER"
	MealTypeSnack     MealType = "SNACK"
)

type WeatherTag string

const (
	WeatherSunny  WeatherTag = "SUNNY"
	WeatherCloudy WeatherTag = "CLOUDY"
	WeatherRainy  WeatherTag = "RAINY"
	WeatherSnowy  WeatherTag = "SNOWY"
	WeatherWindy  WeatherTag = "WINDY"
	WeatherHot    WeatherTag = "HOT"
	WeatherCold   WeatherTag = "COLD"
)

type MoodTag string

const (
	MoodGood     MoodTag = "GOOD"
	MoodTired    MoodTag = "TIRED"
	MoodStressed MoodTag = "STRESSED"
	MoodHungry   MoodTag = "HUNGRY"
	MoodExcited  MoodTag = "EXCITED"
	MoodSad      MoodTag = "SAD"
	MoodNormal   MoodTag = "NORMAL"
)

type FriendTagStatus string

const (
	FriendTagPending  FriendTagStatus = "PENDING"
	FriendTagAccepted FriendTagStatus = "ACCEPTED"
)

// ─────────────────────────────────────────
// 엔티티
// ─────────────────────────────────────────

type MealRecord struct {
	BaseDomain
	UserID      int64       `gorm:"column:user_id;not null;index"`
	MenuID      *int64      `gorm:"column:menu_id;index"`
	ImageURL    *string     `gorm:"column:image_url"`
	MenuName    string      `gorm:"column:menu_name;not null"`
	Category    string      `gorm:"column:category;not null"`
	MealType    MealType    `gorm:"column:meal_type;not null"`
	ServingSize float64     `gorm:"column:serving_size;default:1.0"`
	RecordedAt  time.Time   `gorm:"column:recorded_at;not null"`
	WeatherTag  *WeatherTag `gorm:"column:weather_tag"`
	MoodTag     *MoodTag    `gorm:"column:mood_tag"`
	Review      *string     `gorm:"column:review"`
	Rating      *int        `gorm:"column:rating;check:rating >= 1 AND rating <= 5"`
	IsManual    bool        `gorm:"column:is_manual;default:false"`

	Nutrition  *Nutrition      `gorm:"foreignKey:MealID"`
	FriendTags []MealFriendTag `gorm:"foreignKey:MealID"`
	Menu       *Menu           `gorm:"foreignKey:ID;references:MenuID"`
	User       *User           `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

func (MealRecord) TableName() string { return "meal_records" }

type Nutrition struct {
	BaseDomain
	MealID       int64   `gorm:"column:meal_id;not null;uniqueIndex"`
	Calories     float64 `gorm:"column:calories;default:0"`
	Carbs        float64 `gorm:"column:carbs;default:0"`
	Protein      float64 `gorm:"column:protein;default:0"`
	Fat          float64 `gorm:"column:fat;default:0"`
	Sodium       float64 `gorm:"column:sodium;default:0"`
	Fiber        float64 `gorm:"column:fiber;default:0"`
	VitaminScore float64 `gorm:"column:vitamin_score;default:0"`
}

func (Nutrition) TableName() string { return "nutritions" }

// DailyIntake — badge_granter 호환을 위해 Date를 time.Time으로 유지
// IsBalanced는 Cron(AppearanceRecalculate 05:10)에서 설정
type DailyIntake struct {
	BaseDomain
	UserID        int64     `gorm:"column:user_id;not null;uniqueIndex:idx_daily_intakes_user_date"`
	Date          time.Time `gorm:"column:date;not null;type:date;uniqueIndex:idx_daily_intakes_user_date"`
	TotalCalories float64   `gorm:"column:total_calories;default:0"`
	TotalCarbs    float64   `gorm:"column:total_carbs;default:0"`
	TotalProtein  float64   `gorm:"column:total_protein;default:0"`
	TotalFat      float64   `gorm:"column:total_fat;default:0"`
	TotalSodium   float64   `gorm:"column:total_sodium;default:0"`
	TotalFiber    float64   `gorm:"column:total_fiber;default:0"`
	VitaminScore  float64   `gorm:"column:vitamin_score;default:0"`
	MealCount     int       `gorm:"column:meal_count;default:0"`
	IsBalanced    bool      `gorm:"column:is_balanced;default:false"`
}

func (DailyIntake) TableName() string { return "daily_intakes" }

type MealFriendTag struct {
	BaseDomain
	MealID       int64           `gorm:"column:meal_id;not null;uniqueIndex:idx_meal_friend_tags"`
	TaggedUserID int64           `gorm:"column:tagged_user_id;not null;uniqueIndex:idx_meal_friend_tags"`
	Status       FriendTagStatus `gorm:"column:status;default:'PENDING'"`
}

func (MealFriendTag) TableName() string { return "meal_friend_tags" }

// ─────────────────────────────────────────
// 쿼리 파라미터
// ─────────────────────────────────────────

type MealListFilter struct {
	StartDate string
	EndDate   string
	MealType  MealType
	Cursor    int64
	Limit     int
}

// ─────────────────────────────────────────
// SideEffects
// ─────────────────────────────────────────

type QuestProgress struct {
	QuestType string `json:"quest_type"`
	Progress  int    `json:"progress"`
	Target    int    `json:"target"`
	Completed bool   `json:"completed"`
}

type MasteryUpdate struct {
	MenuName     string `json:"menu_name"`
	EatCount     int    `json:"eat_count"`
	Grade        string `json:"grade"`
	GradeChanged bool   `json:"grade_changed"`
}

type MealSideEffects struct {
	QuestsProgressed []QuestProgress `json:"quests_progressed"`
	MasteryUpdated   *MasteryUpdate  `json:"mastery_updated"`
	GrantedBadges    []Badge         `json:"granted_badges"`
	GrantedTitle     *Title          `json:"granted_title,omitempty"`
	ExpGained        int             `json:"exp_gained"`
	LevelUp          interface{}     `json:"level_up"`
}
