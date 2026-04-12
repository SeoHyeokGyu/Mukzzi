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
// @Param        include_acquired  query     bool    false  "획득한 뱃지 포함 여부 (기본값: true, 허용값: 'true'|'false')"
// @Param        limit             query     int     false  "페이지당 항목 수 (기본값: 20, 범위: 1-50)"
// @Param        cursor            query     string  false  "다음 페이지 커서 (이전 응답의 next_cursor 값 사용)"
// @Success      200  {object}  Response  "뱃지 목록 조회 성공"
// @Failure      400  {object}  Response  "잘못된 쿼리 파라미터"
// @Failure      401  {object}  Response  "인증 토큰 누락 또는 유효하지 않음"
// @Failure      500  {object}  Response  "서버 내부 에러"
// @Router       /api/collections/badges [get]
func (h *CollectionHandler) GetBadges(c *gin.Context) {
	// 인증 확인 (미들웨어에서 설정한 userID 사용)
	userIDVal, exists := c.Get("userID")
	if !exists {
		Unauthorized(c, "UNAUTHORIZED", "인증 토큰이 누락되었거나 유효하지 않습니다.", "BearerToken을 포함한 Authorization 헤더를 확인하세요.")
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
			BadRequest(c, "INVALID_PARAMETER", "include_acquired 파라미터는 'true' 또는 'false'여야 합니다.", map[string]any{"parameter": "include_acquired", "allowed": []string{"true", "false"}})
			return
		}
	}

	// limit 파싱 (기본값: 20, 최대값: 50)
	limit := 20
	if limitStr != "" {
		parsedLimit, err := strconv.Atoi(limitStr)
		if err != nil || parsedLimit <= 0 || parsedLimit > 50 {
			BadRequest(c, "INVALID_PARAMETER", "limit 파라미터는 1 이상 50 이하의 정수여야 합니다.", map[string]any{"parameter": "limit", "min": 1, "max": 50, "default": 20})
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
		// BadgeError 타입 확인
		badgeErr, ok := err.(*usecase.BadgeError)
		if !ok {
			InternalError(c, "서버 내부 오류가 발생했습니다.")
			return
		}

		// BadgeError 코드별 처리
		Error(c, http.StatusInternalServerError, badgeErr.Code, badgeErr.Message, badgeErr.Details)
		return
	}

	// 성공 응답 (CursorPaginated 사용)
	responses := make([]dto.BadgeResponse, len(result.Badges))
	for i, badge := range result.Badges {
		userBadge, isAcquired := result.AcquiredMap[badge.ID]
		responses[i] = dto.BadgeResponse{
			ID:          badge.ID,
			Code:        badge.Code,
			Name:        badge.Name,
			Description: badge.Description,
			IconURL:     badge.IconURL,
			Acquired:    isAcquired,
		}
		if isAcquired && userBadge != nil {
			responses[i].AcquiredAt = &userBadge.AcquiredAt
		}
	}

	CursorPaginated(c, responses, result.Limit, result.HasNext, result.NextCursor)
}
