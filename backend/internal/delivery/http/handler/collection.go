package handler

import (
	"net/http"
	"strconv"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/dto"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
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
// @Success      200  {object}  dto.CollectionResponse  "뱃지 목록 조회 성공"
// @Failure      400  {object}  dto.CollectionResponse  "잘못된 쿼리 파라미터"
// @Failure      401  {object}  dto.CollectionResponse  "인증 토큰 누락 또는 유효하지 않음"
// @Failure      500  {object}  dto.CollectionResponse  "서버 내부 에러"
// @Router       /api/collections/badges [get]
func (h *CollectionHandler) GetBadges(c *gin.Context) {
	// 인증 확인 (미들웨어에서 설정한 userID 사용)
	userIDVal, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, dto.CollectionResponse{
			Success: false,
			Error: &dto.ErrorInfo{
				Code:    "UNAUTHORIZED",
				Message: "인증 정보가 없습니다.",
			},
		})
		return
	}
	userID := userIDVal.(int64)

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
			c.JSON(http.StatusBadRequest, dto.CollectionResponse{
				Success: false,
				Error: &dto.ErrorInfo{
					Code:    "INVALID_PARAMETER",
					Message: "include_acquired 는 'true' 또는 'false' 여야 합니다.",
				},
			})
			return
		}
	}

	// limit 파싱 (기본값: 20, 최대값: 50)
	limit := 20
	if limitStr != "" {
		parsedLimit, err := strconv.Atoi(limitStr)
		if err != nil || parsedLimit <= 0 || parsedLimit > 50 {
			c.JSON(http.StatusBadRequest, dto.CollectionResponse{
				Success: false,
				Error: &dto.ErrorInfo{
					Code:    "INVALID_PARAMETER",
					Message: "limit 은 1 에서 50 사이여야 합니다.",
				},
			})
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
		c.JSON(http.StatusInternalServerError, dto.CollectionResponse{
			Success: false,
			Error: &dto.ErrorInfo{
				Code:    "INTERNAL_SERVER_ERROR",
				Message: "뱃지 목록을 가져오는 데 실패했습니다.",
			},
		})
		return
	}

	// 성공 응답 (CollectionResponse DTO 사용)
	c.JSON(http.StatusOK, dto.CollectionResponse{
		Success: true,
		Data:    result.Badges,
		Error:   nil,
		Pagination: &dto.PaginationInfo{
			Limit:      result.Limit,
			HasNext:    result.HasNext,
			NextCursor: result.NextCursor,
		},
	})
}
