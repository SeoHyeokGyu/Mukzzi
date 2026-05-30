package route

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/middleware"
	"github.com/gin-gonic/gin"
)

func AIRoute(rg *gin.RouterGroup, h *handler.AIHandler) {
	ai := rg.Group("/ai")
	ai.Use(middleware.AuthMiddleware())
	{
		ai.POST("/analyze-meal", h.AnalyzeMealImage)
		ai.POST("/recommend-meal", h.RecommendMeal)
		ai.POST("/nutrition-coaching", h.GetNutritionCoaching)
	}
}
