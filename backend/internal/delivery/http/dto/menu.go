package dto

// MenuSearchRequest 는 메뉴 검색 요청 데이터를 정의합니다.
type MenuSearchRequest struct {
	Query    string `form:"query" binding:"required"`
	Category string `form:"category"`
	Cursor   string `form:"cursor"`
	Limit    int    `form:"limit"`
}

// MenuCreateRequest 는 사용자 정의 메뉴 등록 요청 데이터를 정의합니다.
type MenuCreateRequest struct {
	Name     string  `json:"name"     binding:"required,min=1,max=100"`
	Category string  `json:"category" binding:"required,oneof=KOREAN CHINESE JAPANESE WESTERN SNACK CAFE OTHER"`
	Calories float64 `json:"calories"`
	Carbs    float64 `json:"carbs"`
	Protein  float64 `json:"protein"`
	Fat      float64 `json:"fat"`
	Fiber    float64 `json:"fiber"`
}

// MenuResponse 는 메뉴 응답 데이터를 정의합니다.
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
