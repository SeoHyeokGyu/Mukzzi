package dto

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
)

// BadgeResponse domain.BadgeResponse의 alias
type BadgeResponse = domain.BadgeResponse

// CollectionResponse 뱃지 목록 조회 성공 응답
type CollectionResponse struct {
	Success    bool              `json:"success"`
	Data       []BadgeResponse   `json:"data"`
	Pagination *PaginationInfo   `json:"pagination,omitempty"`
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
