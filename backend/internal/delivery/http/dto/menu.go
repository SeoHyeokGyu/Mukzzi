package dto

// MenuSearchRequest 는 메뉴 검색 요청 데이터를 정의합니다.
type MenuSearchRequest struct {
	Query    string `form:"query" binding:"required"`
	Category string `form:"category"`
	Cursor   string `form:"cursor"`
	Limit    int    `form:"limit"`
}

// MenuResponse 는 메뉴 검색 응답 데이터를 정의합니다.
type MenuResponse struct {
	ID                  int64   `json:"id,string"`
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
