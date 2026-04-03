package dto

import "time"

// BadgeResponse API 응답용 뱃지 정보
type BadgeResponse struct {
	ID          int64      `json:"id,string"`
	Code        string     `json:"code"`
	Name        string     `json:"name"`
	Description string     `json:"description"`
	IconURL     string     `json:"icon_url"`
	Acquired    bool       `json:"acquired"`
	AcquiredAt  *time.Time `json:"acquired_at,omitempty"`
}

// CollectionResponse 뱃지 목록 조회 응답
type CollectionResponse struct {
	Success    bool              `json:"success"`
	Data       []BadgeResponse   `json:"data"`
	Pagination *PaginationInfo   `json:"pagination,omitempty"`
	Error      *ErrorInfo        `json:"error,omitempty"`
}

// PaginationInfo 페이징 정보
type PaginationInfo struct {
	TotalCount int64  `json:"total_count"`
	Page       int    `json:"page"`
	Limit      int    `json:"limit"`
	HasNext    bool   `json:"has_next"`
	NextCursor string `json:"next_cursor,omitempty"`
}

// ErrorInfo 에러 정보
type ErrorInfo struct {
	Code    string      `json:"code"`
	Message string      `json:"message"`
	Details interface{} `json:"details,omitempty"`
}

// ErrorResponse 에러 응답
type ErrorResponse struct {
	Success bool      `json:"success"`
	Error   *ErrorInfo `json:"error"`
}
