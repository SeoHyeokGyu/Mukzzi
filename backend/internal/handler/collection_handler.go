package handler

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
)

// CollectionHandler 컬렉션 핸들러
type CollectionHandler struct {
	badgeUsecase usecase.BadgeUsecase
}

// NewCollectionHandler 컬렉션 핸들러 생성
func NewCollectionHandler(badgeUsecase usecase.BadgeUsecase) *CollectionHandler {
	return &CollectionHandler{
		badgeUsecase: badgeUsecase,
	}
}

// GetBadges 뱃지 목록 조회
// @Summary      뱃지 목록 조회
// @Description  사용자의 획득/미획득 뱃지 목록을 커서 기반 페이지네이션으로 반환합니다.
// @Tags         collections
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        include_acquired  query     bool    false  "획득한 뱃지 포함 여부 (기본값: true)"
// @Param        limit             query     int     false  "페이지당 항목 수 (기본값: 20, 최대: 50)"
// @Param        cursor            query     string  false  "다음 페이지 커서"
// @Success      200  {object}  ApiResponse
// @Failure      400  {object}  ApiResponse
// @Failure      401  {object}  ApiResponse
// @Failure      500  {object}  ApiResponse
// @Router       /api/v1/collections/badges [get]
func (h *CollectionHandler) GetBadges(c *gin.Context) {
	// 인증 확인
	userID, err := extractUserIDFromGinContext(c)
	if err != nil {
		writeErrorResponse(c, http.StatusUnauthorized, "UNAUTHORIZED", "missing or invalid authorization")
		return
	}

	// 쿼리 파라미터 파싱
	includeAcquiredStr := c.Query("include_acquired")
	limitStr := c.Query("limit")
	cursor := c.Query("cursor")

	// include_acquired 파싱 (기본값: true)
	includeAcquired := true
	if includeAcquiredStr != "" {
		if includeAcquiredStr == "false" {
			includeAcquired = false
		} else if includeAcquiredStr != "true" {
			writeErrorResponse(c, http.StatusBadRequest, "INVALID_PARAMETER", "include_acquired must be 'true' or 'false'")
			return
		}
	}

	// limit 파싱 (기본값: 20, 최대값: 50)
	limit := 20
	if limitStr != "" {
		parsedLimit, err := strconv.Atoi(limitStr)
		if err != nil || parsedLimit <= 0 || parsedLimit > 50 {
			writeErrorResponse(c, http.StatusBadRequest, "INVALID_PARAMETER", "limit must be between 1 and 50")
			return
		}
		limit = parsedLimit
	}

	// 유즈케이스 호출
	result, err := h.badgeUsecase.GetBadges(c.Request.Context(), domain.GetBadgesQuery{
		UserID:          userID,
		IncludeAcquired: includeAcquired,
		Cursor:          cursor,
		Limit:           limit,
	})
	if err != nil {
		writeErrorResponse(c, http.StatusInternalServerError, "INTERNAL_ERROR", "failed to retrieve badges")
		return
	}

	// 성공 응답
	writeSuccessResponse(c, http.StatusOK, map[string]interface{}{
		"data": result.Badges,
		"pagination": map[string]interface{}{
			"next_cursor": result.NextCursor,
			"has_next":    result.HasNext,
			"limit":       result.Limit,
		},
	})
}

// extractUserIDFromGinContext Gin 컨텍스트에서 사용자 ID 추출
func extractUserIDFromGinContext(c *gin.Context) (int64, error) {
	auth := c.GetHeader("Authorization")
	if auth == "" {
		return 0, fmt.Errorf("missing authorization header")
	}

	// Bearer token 추출
	parts := strings.Split(auth, " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		return 0, fmt.Errorf("invalid authorization format")
	}

	// TODO: JWT 토큰 검증 및 사용자 ID 추출
	// 임시로 1 반환 (실제 구현에서는 JWT 검증 필요)
	return 1, nil
}

// 공통 응답 구조
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

// writeSuccessResponse Gin 성공 응답
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

// writeErrorResponse Gin 에러 응답
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
