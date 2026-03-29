package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Response 는 모든 API 응답의 공통 래퍼 구조체입니다.
type Response struct {
	Success    bool           `json:"success" example:"true"`
	Data       interface{}    `json:"data,omitempty"`
	Error      *ErrorResponse `json:"error,omitempty"`
	Pagination *Pagination    `json:"pagination,omitempty"`
}

// ErrorResponse 는 실패 응답 시 에러 세부 정보를 담습니다.
type ErrorResponse struct {
	Code    string      `json:"code" example:"USER_NOT_FOUND"`
	Message string      `json:"message" example:"해당 사용자를 찾을 수 없습니다."`
	Details interface{} `json:"details,omitempty"`
}

// Pagination 은 목록 조회 시 페이징 정보를 담습니다.
type Pagination struct {
	TotalCount int64 `json:"total_count" example:"100"`
	Page       int   `json:"page" example:"1"`
	Limit      int   `json:"limit" example:"20"`
	HasNext    bool  `json:"has_next" example:"true"`
}

// Success 는 성공 응답을 전송합니다. (200 OK)
func Success(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Success: true,
		Data:    data,
	})
}

// Created 는 리소스 생성 성공 응답을 전송합니다. (201 Created)
func Created(c *gin.Context, data interface{}) {
	c.JSON(http.StatusCreated, Response{
		Success: true,
		Data:    data,
	})
}

// Paginated 는 페이징 정보가 포함된 목록 응답을 전송합니다.
func Paginated(c *gin.Context, data interface{}, totalCount int64, page, limit int) {
	hasNext := int64(page*limit) < totalCount
	c.JSON(http.StatusOK, Response{
		Success: true,
		Data:    data,
		Pagination: &Pagination{
			TotalCount: totalCount,
			Page:       page,
			Limit:      limit,
			HasNext:    hasNext,
		},
	})
}

// Error 는 에러 응답을 전송합니다.
func Error(c *gin.Context, status int, code, message string, details ...interface{}) {
	var detail interface{}
	if len(details) > 0 {
		detail = details[0]
	}

	c.JSON(status, Response{
		Success: false,
		Error: &ErrorResponse{
			Code:    code,
			Message: message,
			Details: detail,
		},
	})
}

// BadRequest 는 400 에러 응답을 전송합니다.
func BadRequest(c *gin.Context, code, message string, details ...interface{}) {
	Error(c, http.StatusBadRequest, code, message, details...)
}

// Unauthorized 는 401 에러 응답을 전송합니다.
func Unauthorized(c *gin.Context, code, message string, details ...interface{}) {
	Error(c, http.StatusUnauthorized, code, message, details...)
}

// Forbidden 는 403 에러 응답을 전송합니다.
func Forbidden(c *gin.Context, code, message string, details ...interface{}) {
	Error(c, http.StatusForbidden, code, message, details...)
}

// NotFound 는 404 에러 응답을 전송합니다.
func NotFound(c *gin.Context, code, message string, details ...interface{}) {
	Error(c, http.StatusNotFound, code, message, details...)
}

// InternalError 는 500 에러 응답을 전송합니다.
func InternalError(c *gin.Context, message string, details ...interface{}) {
	Error(c, http.StatusInternalServerError, "INTERNAL_SERVER_ERROR", message, details...)
}
