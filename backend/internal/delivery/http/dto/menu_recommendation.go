package dto

type RecommendationResponse struct {
	Menus      []MenuResponse `json:"menus"`
	IsPersonal bool           `json:"is_personal"` // true: 개인화 추천, false: 인기 메뉴 폴백
}
