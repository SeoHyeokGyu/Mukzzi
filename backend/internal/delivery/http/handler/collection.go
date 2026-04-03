package handler

import (
	"net/http"
	"strconv"

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
// @Success      200  {object}  Response
// @Failure      400  {object}  Response
// @Failure      401  {object}  Response
// @Failure      500  {object}  Response
// @Router       /api/collections/badges [get]
func (h *CollectionHandler) GetBadges(c *gin.Context) {
	// 인증 확인 (미들웨어에서 설정한 userID 사용)
	userIDVal, exists := c.Get("userID")
	if !exists {
		Unauthorized(c, "UNAUTHORIZED", "인증 정보가 없습니다.")
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
			BadRequest(c, "INVALID_PARAMETER", "include_acquired 는 'true' 또는 'false' 여야 합니다.")
			return
		}
	}

	// limit 파싱 (기본값: 20, 최대값: 50)
	limit := 20
	if limitStr != "" {
		parsedLimit, err := strconv.Atoi(limitStr)
		if err != nil || parsedLimit <= 0 || parsedLimit > 50 {
			BadRequest(c, "INVALID_PARAMETER", "limit 은 1 에서 50 사이여야 합니다.")
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
		InternalError(c, "뱃지 목록을 가져오는 데 실패했습니다.")
		return
	}

	// 성공 응답 (기존 Response 구조체 사용)
	c.JSON(http.StatusOK, Response{
		Success: true,
		Data:    result.Badges,
		Pagination: &Pagination{
			Limit:   result.Limit,
			HasNext: result.HasNext,
			// 커서 기반 페이지네이션의 경우 TotalCount 가 없을 수 있으므로 0 혹은 생략 가능
			// 여기서는 NextCursor 를 Data 혹은 별도 필드에 포함할 수 있음
		},
	})
	// 주의: Pagination 구조체에 NextCursor 필드가 없으므로, 필요하다면 Data 에 포함하거나 구조체를 확장해야 함
	// 현재 response.go 의 Pagination 은 TotalCount 를 요구함.
}
