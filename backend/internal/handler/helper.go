package handler

import (
	"fmt"
	"strings"

	"github.com/gin-gonic/gin"
)

type ApiResponse struct {
	Success    bool        `json:"success"`
	Data       interface{} `json:"data,omitempty"`
	Pagination interface{} `json:"pagination,omitempty"`
	Error      interface{} `json:"error,omitempty"`
}

type ErrorDetail struct {
	Code    string      `json:"code"`
	Message string      `json:"message"`
	Details interface{} `json:"details"`
}

func writeSuccessResponse(c *gin.Context, statusCode int, data interface{}) {
	response := ApiResponse{Success: true}

	dataMap, ok := data.(map[string]interface{})
	if ok {
		response.Data = dataMap["data"]
		response.Pagination = dataMap["pagination"]
	} else {
		response.Data = data
	}

	c.JSON(statusCode, response)
}

func writeErrorResponse(c *gin.Context, statusCode int, code string, message string) {
	c.JSON(statusCode, ApiResponse{
		Success: false,
		Error: ErrorDetail{
			Code:    code,
			Message: message,
			Details: nil,
		},
	})
}

func extractUserIDFromGinContext(c *gin.Context) (int64, error) {
	auth := c.GetHeader("Authorization")
	if auth == "" {
		return 0, fmt.Errorf("missing authorization header")
	}

	parts := strings.Split(auth, " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		return 0, fmt.Errorf("invalid authorization format")
	}

	// TODO: JWT 검증 후 실제 userID 반환
	return 1, nil
}
