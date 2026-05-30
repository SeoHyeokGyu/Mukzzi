package handler

import (
	"net/http"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/dto"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
)

type AIHandler struct {
	aiUc usecase.AIUsecase
}

func NewAIHandler(aiUc usecase.AIUsecase) *AIHandler {
	return &AIHandler{aiUc: aiUc}
}

// AnalyzeMealImage godoc
// @Summary      음식 사진 분석
// @Description  Gemini API를 사용하여 음식 사진에서 메뉴명과 영양 성분을 분석합니다.
// @Tags         AI
// @Accept       json
// @Produce      json
// @Param        request body dto.AnalyzeMealRequest true "이미지 분석 요청"
// @Success      200 {object} Response{data=usecase.AnalyzeMealOutput}
// @Failure      400 {object} Response
// @Failure      500 {object} Response
// @Security     BearerAuth
// @Router       /api/ai/analyze-meal [post]
func (h *AIHandler) AnalyzeMealImage(c *gin.Context) {
	var req dto.AnalyzeMealRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_INPUT", "잘못된 요청 데이터입니다.", err.Error())
		return
	}

	userID := c.GetInt64("userID")

	input := usecase.AnalyzeMealInput{
		UserID:   userID,
		ImageURL: req.ImageURL,
	}

	res, err := h.aiUc.AnalyzeMealImage(c.Request.Context(), input)
	if err != nil {
		InternalError(c, "이미지 분석 중 오류가 발생했습니다.", err.Error())
		return
	}

	Success(c, res)
}

// RecommendMeal godoc
// @Summary      식단 추천
// @Description  Gemini API를 사용하여 현재 섭취량과 목표를 바탕으로 다음 끼니를 추천합니다.
// @Tags         AI
// @Accept       json
// @Produce      json
// @Param        request body dto.RecommendMealRequest true "식단 추천 요청"
// @Success      200 {object} Response{data=usecase.RecommendMealOutput}
// @Failure      400 {object} Response
// @Failure      500 {object} Response
// @Security     BearerAuth
// @Router       /api/ai/recommend-meal [post]
func (h *AIHandler) RecommendMeal(c *gin.Context) {
	var req dto.RecommendMealRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_INPUT", "잘못된 요청 데이터입니다.", err.Error())
		return
	}

	userID := c.GetInt64("userID")

	input := usecase.RecommendMealInput{
		UserID:   userID,
		MealType: req.MealType,
	}

	res, err := h.aiUc.RecommendMeal(c.Request.Context(), input)
	if err != nil {
		InternalError(c, "식단 추천 중 오류가 발생했습니다.", err.Error())
		return
	}

	Success(c, res)
}

// GetNutritionCoaching godoc
// @Summary      영양 코칭
// @Description  Gemini API를 사용하여 특정일의 식단에 대한 종합 피드백과 코칭을 제공합니다.
// @Tags         AI
// @Accept       json
// @Produce      json
// @Param        request body dto.NutritionCoachingRequest true "영양 코칭 요청 (날짜 생략 시 오늘)"
// @Success      200 {object} Response{data=usecase.NutritionCoachingOutput}
// @Failure      400 {object} Response
// @Failure      500 {object} Response
// @Security     BearerAuth
// @Router       /api/ai/nutrition-coaching [post]
func (h *AIHandler) GetNutritionCoaching(c *gin.Context) {
	var req dto.NutritionCoachingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_INPUT", "잘못된 요청 데이터입니다.", err.Error())
		return
	}

	userID := c.GetInt64("userID")

	input := usecase.NutritionCoachingInput{
		UserID: userID,
		Date:   req.Date,
	}

	res, err := h.aiUc.GetNutritionCoaching(c.Request.Context(), input)
	if err != nil {
		// 해당일 식사 기록이 없는 경우 등
		Error(c, http.StatusBadRequest, "COACHING_FAILED", err.Error())
		return
	}

	Success(c, res)
}
