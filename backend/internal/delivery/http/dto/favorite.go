package dto

// FavoriteResponse 즐겨찾기 응답
type FavoriteResponse struct {
	ID   int64        `json:"id,string"`
	Menu MenuResponse `json:"menu"`
}
