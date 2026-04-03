package domain

type MenuCategory string
type MenuSource string
type PreferenceType string

const (
	CategoryKorean   MenuCategory = "KOREAN"
	CategoryChinese  MenuCategory = "CHINESE"
	CategoryJapanese MenuCategory = "JAPANESE"
	CategoryWestern  MenuCategory = "WESTERN"
	CategorySnack    MenuCategory = "SNACK"
	CategoryCafe     MenuCategory = "CAFE"
	CategoryOther    MenuCategory = "OTHER"

	SourceUSDA MenuSource = "USDA"
	SourceMFDS MenuSource = "MFDS"
	SourceUser MenuSource = "USER"

	PreferenceLike    PreferenceType = "LIKE"
	PreferenceDislike PreferenceType = "DISLIKE"
)

type Menu struct {
	BaseDomain
	Name                string       `gorm:"type:varchar(100);not null;uniqueIndex:idx_menus_name_category"`
	Category            MenuCategory `gorm:"type:varchar(20);not null;uniqueIndex:idx_menus_name_category"`
	DefaultCalories     float64      `gorm:"default:0"`
	DefaultCarbs        float64      `gorm:"default:0"`
	DefaultProtein      float64      `gorm:"default:0"`
	DefaultFat          float64      `gorm:"default:0"`
	DefaultFiber        float64      `gorm:"default:0"`
	DefaultVitaminScore float64      `gorm:"default:0"`
	Source              MenuSource   `gorm:"type:varchar(20);default:'USER'"`
}

// 쿼리/결과 타입
type MenuNutritionDefaults struct {
	Calories     float64
	Carbs        float64
	Protein      float64
	Fat          float64
	Fiber        float64
	VitaminScore float64
}

type SearchMenuQuery struct {
	Query    string
	Category *MenuCategory
	Cursor   *int64
	Limit    int
}

type SearchMenuResult struct {
	Menus      []MenuResponse
	NextCursor *string
	HasNext    bool
	Limit      int
}

type MenuResponse struct {
	ID                  string  `json:"id"`
	Name                string  `json:"name"`
	Category            string  `json:"category"`
	Source              string  `json:"source"`
	DefaultCalories     float64 `json:"default_calories"`
	DefaultCarbs        float64 `json:"default_carbs"`
	DefaultProtein      float64 `json:"default_protein"`
	DefaultFat          float64 `json:"default_fat"`
	DefaultFiber        float64 `json:"default_fiber"`
	DefaultVitaminScore float64 `json:"default_vitamin_score"`
}
