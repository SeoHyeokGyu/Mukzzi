package handler

import (
	"errors"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/dto"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
)

type RouletteHandler struct {
	rouletteUsecase usecase.RouletteUsecase
}

func NewRouletteHandler(rouletteUsecase usecase.RouletteUsecase) *RouletteHandler {
	return &RouletteHandler{rouletteUsecase: rouletteUsecase}
}

// Spin 룰렛 실행
// @Summary      메뉴 룰렛
// @Description  즐겨찾기 + 마스터리 가중치 기반으로 메뉴를 랜덤 추천합니다. 최근 3일 내 먹은 메뉴는 제외됩니다.
// @Tags         menus
// @Security     BearerAuth
// @Produce      json
// @Success      200  {object}  Response  "룰렛 결과"
// @Failure      401  {object}  Response  "UNAUTHORIZED"
// @Failure      404  {object}  Response  "NO_CANDIDATE"
// @Failure      500  {object}  Response  "INTERNAL_SERVER_ERROR"
// @Router       /api/menus/roulette [post]
func (h *RouletteHandler) Spin(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		Unauthorized(c, "UNAUTHORIZED", "인증 정보가 없습니다.")
		return
	}

	result, err := h.rouletteUsecase.Spin(userID.(int64))
	if err != nil {
		if errors.Is(err, usecase.ErrNoRouletteCandidate) {
			NotFound(c, "NO_CANDIDATE", "추천할 메뉴가 없습니다.")
			return
		}
		InternalError(c, "룰렛 실행에 실패했습니다.", err.Error())
		return
	}

	Success(c, dto.ToRouletteResponse(result.Candidates, result.Menu, result.Reason))
}
