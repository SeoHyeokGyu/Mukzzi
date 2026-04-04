package dto

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
)

// BadgeResponse domain.BadgeResponse의 alias
type BadgeResponse = domain.BadgeResponse

// CollectionResponse 뱃지 목록 조회 응답
type CollectionResponse struct {
	Success    bool              `json:"success"`
	Data       []BadgeResponse   `json:"data,omitempty"`
	Error      *ErrorInfo        `json:"error,omitempty"`
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

// BadgeSuccessResponse 뱃지 성공 응답 (OpenAPI 3.0용)
type BadgeSuccessResponse struct {
	Success    bool            `json:"success" example:"true"`
	Data       []BadgeResponse `json:"data"`
	Error      *ErrorInfo      `json:"error"`
	Pagination *PaginationInfo `json:"pagination"`
}

// BadgeErrorResponse 뱃지 에러 응답 (OpenAPI 3.0용)
type BadgeErrorResponse struct {
	Success    bool       `json:"success" example:"false"`
	Data       interface{} `json:"data"`
	Error      *ErrorInfo `json:"error"`
	Pagination interface{} `json:"pagination"`
}

// BadgeErrorCode 뱃지 API 에러 코드
type BadgeErrorCode string

const (
	BadgeErrorUnauthorized          BadgeErrorCode = "UNAUTHORIZED"
	BadgeErrorInvalidParameter      BadgeErrorCode = "INVALID_PARAMETER"
	BadgeErrorBadgeFetchFailed      BadgeErrorCode = "BADGE_FETCH_ERROR"
	BadgeErrorUserBadgeFetchFailed  BadgeErrorCode = "USER_BADGE_FETCH_ERROR"
	BadgeErrorInternalServerError   BadgeErrorCode = "INTERNAL_SERVER_ERROR"
)
