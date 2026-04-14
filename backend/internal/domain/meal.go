package domain

import "time"

type MealType string

const (
	MealTypeBreakfast MealType = "BREAKFAST"
	MealTypeLunch     MealType = "LUNCH"
	MealTypeDinner    MealType = "DINNER"
	MealTypeSnack     MealType = "SNACK"
)

type MealRecord struct {
	BaseDomain
	UserID      int64        `gorm:"not null;index:idx_meal_records_user_recorded"`
	MenuID      *int64       `gorm:"index"`
	ImageURL    string       `gorm:"type:text"`
	MenuName    string       `gorm:"type:varchar(100);not null"`
	Category    MenuCategory `gorm:"type:varchar(20);not null"`
	MealType    MealType     `gorm:"type:varchar(20);not null"`
	ServingSize float64      `gorm:"default:1.0"`
	RecordedAt  time.Time    `gorm:"not null;index:idx_meal_records_user_recorded"`
	WeatherTag  string       `gorm:"type:varchar(20)"`
	MoodTag     string       `gorm:"type:varchar(20)"`
	Review      string       `gorm:"type:text"`
	Rating      *int         `gorm:"check:rating BETWEEN 1 AND 5"`
	IsManual    bool         `gorm:"default:false"`
}

func (MealRecord) TableName() string {
	return "meal_records"
}

type DailyIntake struct {
	BaseDomain
	UserID        int64     `gorm:"not null;uniqueIndex:idx_daily_intakes_user_date"`
	Date          time.Time `gorm:"type:date;not null;uniqueIndex:idx_daily_intakes_user_date"`
	TotalCalories float64   `gorm:"default:0"`
	TotalCarbs    float64   `gorm:"default:0"`
	TotalProtein  float64   `gorm:"default:0"`
	TotalFat      float64   `gorm:"default:0"`
	TotalSodium   float64   `gorm:"default:0"`
	TotalFiber    float64   `gorm:"default:0"`
	VitaminScore  float64   `gorm:"default:0"`
	MealCount     int       `gorm:"default:0"`
	IsBalanced    bool      `gorm:"default:false"`
}

func (DailyIntake) TableName() string {
	return "daily_intakes"
}
