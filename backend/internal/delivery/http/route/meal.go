package route

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/middleware"
	"github.com/gin-gonic/gin"
)

// MealRoute 는 식사 기록 및 영양 관련 라우트를 등록합니다.
func MealRoute(rg *gin.RouterGroup, mealHandler *handler.MealHandler) {
	meals := rg.Group("/meals")
	{
		meals.Use(middleware.AuthMiddleware())

		meals.POST("", mealHandler.CreateMeal)
		meals.GET("", mealHandler.ListMeals)
		meals.GET("/:id", mealHandler.GetMeal)
		meals.PATCH("/:id", mealHandler.UpdateMeal)
		meals.DELETE("/:id", mealHandler.DeleteMeal)
		meals.POST("/:id/tags/:tagId/accept", mealHandler.AcceptFriendTag)
	}

	nutrition := rg.Group("/nutrition")
	{
		nutrition.Use(middleware.AuthMiddleware())

		nutrition.GET("/today", mealHandler.GetTodayNutrition)
		nutrition.GET("/weekly", mealHandler.GetWeeklyNutrition)
	}
}
