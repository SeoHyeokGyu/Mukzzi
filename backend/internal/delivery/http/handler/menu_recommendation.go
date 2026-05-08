package handler

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/dto"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
)

// MenuRecommendationHandler 메뉴 추천 핸들러
type MenuRecommendationHandler struct {
	recUc usecase.MenuRecommendationUsecase
}

func NewMenuRecommendationHandler(recUc usecase.MenuRecommendationUsecase) *MenuRecommendationHandler {
	return &MenuRecommendationHandler{recUc: recUc}
}

// GetRecommendations godoc
// @Summary      선호도 기반 메뉴 추천 목록
// @Description  즐겨찾기 + 최근 기록 + 명시적 선호도를 기반으로 개인화된 메뉴 추천 목록을 반환합니다.
//
//	최근 3일 내 먹은 메뉴와 싫어요 메뉴는 제외됩니다.
//	신호가 부족한 신규 유저는 인기 메뉴로 폴백합니다.
//
// @Tags         menus
// @Security     BearerAuth
// @Produce      json
// @Success      200  {object}  Response{data=dto.RecommendationResponse}
// @Failure      401  {object}  Response
// @Failure      500  {object}  Response
// @Router       /menus/recommendations [get]
func (h *MenuRecommendationHandler) GetRecommendations(c *gin.Context) {
	userIDVal, exists := c.Get("userID")
	if !exists {
		Unauthorized(c, "UNAUTHORIZED", "인증이 필요합니다.")
		return
	}
	userID, ok := userIDVal.(int64)
	if !ok {
		Unauthorized(c, "INVALID_TOKEN_PAYLOAD", "토큰 페이로드가 유효하지 않습니다.")
		return
	}

	result, err := h.recUc.GetRecommendations(c.Request.Context(), userID)
	if err != nil {
		InternalError(c, "추천 메뉴 조회에 실패했습니다.")
		return
	}

	menus := make([]dto.MenuResponse, len(result.Menus))
	for i, m := range result.Menus {
		menus[i] = dto.MenuResponse{
			ID:                  m.ID,
			Name:                m.Name,
			Category:            string(m.Category),
			Source:              string(m.Source),
			DefaultCalories:     m.DefaultCalories,
			DefaultCarbs:        m.DefaultCarbs,
			DefaultProtein:      m.DefaultProtein,
			DefaultFat:          m.DefaultFat,
			DefaultFiber:        m.DefaultFiber,
			DefaultVitaminScore: m.DefaultVitaminScore,
		}
	}

	Success(c, dto.RecommendationResponse{
		Menus:      menus,
		IsPersonal: result.IsPersonal,
	})
}
