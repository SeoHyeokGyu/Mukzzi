package handler

import (
	"strings"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/dto"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
)

type MenuFilterHandler struct {
	filterUsecase usecase.MenuFilterUsecase
}

func NewMenuFilterHandler(filterUsecase usecase.MenuFilterUsecase) *MenuFilterHandler {
	return &MenuFilterHandler{filterUsecase: filterUsecase}
}

// Filter 상황별 메뉴 필터 추천
// @Summary      상황별 메뉴 추천
// @Description  날씨/기분 태그 조합으로 어울리는 메뉴를 추천합니다. 본인 기록 우선, 없으면 전체 유저 기록 기반으로 추천합니다.
// @Tags         menus
// @Security     BearerAuth
// @Produce      json
// @Param        weather  query  string  false  "날씨 태그 (복수: SUNNY,RAINY)"
// @Param        mood     query  string  false  "기분 태그 (복수: GOOD,TIRED)"
// @Success      200  {object}  Response  "필터 추천 결과"
// @Failure      401  {object}  Response  "UNAUTHORIZED"
// @Failure      500  {object}  Response  "INTERNAL_SERVER_ERROR"
// @Router       /api/menus/filter [get]
func (h *MenuFilterHandler) Filter(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		Unauthorized(c, "UNAUTHORIZED", "인증 정보가 없습니다.")
		return
	}

	weathers := parseTags(c.Query("weather"))
	moods := parseTags(c.Query("mood"))

	result, err := h.filterUsecase.Filter(userID.(int64), weathers, moods)
	if err != nil {
		InternalError(c, "메뉴 추천에 실패했습니다.", err.Error())
		return
	}

	menus := make([]dto.MenuResponse, len(result.Menus))
	for i, m := range result.Menus {
		menus[i] = toMenuResponse(m)
	}

	Success(c, dto.MenuFilterResponse{
		Menus:  menus,
		Source: result.Source,
	})
}

// parseTags "SUNNY,RAINY" → ["SUNNY", "RAINY"], "" → []
func parseTags(raw string) []string {
	if raw == "" {
		return []string{}
	}
	parts := strings.Split(raw, ",")
	result := make([]string, 0, len(parts))
	for _, p := range parts {
		if t := strings.TrimSpace(p); t != "" {
			result = append(result, t)
		}
	}
	return result
}
