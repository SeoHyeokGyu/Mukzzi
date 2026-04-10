package dto

// MenuSearchRequest 는 메뉴 검색 요청 데이터를 정의합니다.
type MenuSearchRequest struct {
	Query    string `form:"query" binding:"required"`
	Category string `form:"category"`
	Cursor   string `form:"cursor"`
	Limit    int    `form:"limit"`
}
