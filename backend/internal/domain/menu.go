package domain

type (
	MenuCategory   string
	MenuSource     string
	PreferenceType string
)

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
	Menus      []Menu
	NextCursor *string
	HasNext    bool
	Limit      int
}

// CreateMenuInput 사용자 정의 메뉴 생성 입력
type CreateMenuInput struct {
	Name     string
	Category MenuCategory
	Calories float64
	Carbs    float64
	Protein  float64
	Fat      float64
	Fiber    float64
}
