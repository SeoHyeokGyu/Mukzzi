package domain

type MenuPreference struct {
	BaseDomain
	UserID     int64          `gorm:"not null;uniqueIndex:idx_menu_preferences_user_menu"`
	MenuID     int64          `gorm:"not null;uniqueIndex:idx_menu_preferences_user_menu"`
	Preference PreferenceType `gorm:"type:varchar(10);not null"`
	Menu       Menu           `gorm:"foreignKey:MenuID"`
}

func (MenuPreference) TableName() string { return "menu_preferences" }

// SetPreferenceInput 선호도 설정 입력
type SetPreferenceInput struct {
	UserID     int64
	MenuID     int64
	Preference PreferenceType
}
