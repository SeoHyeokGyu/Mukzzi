package route

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/middleware"
	"github.com/gin-gonic/gin"
)

// UserRoute 는 사용자 관련 라우트를 등록합니다.
func UserRoute(rg *gin.RouterGroup, userHandler *handler.UserHandler) {
	users := rg.Group("/users")
	{
		// 로그인이 필요한 요청들에 미들웨어 적용
		users.Use(middleware.AuthMiddleware())

		// 내 정보 관련
		users.GET("/me", userHandler.GetMe)
		users.GET("/me/stats", userHandler.GetStats)
		users.PATCH("/me", userHandler.UpdateMe)
		users.PATCH("/me/body", userHandler.UpdateBody)
		users.PATCH("/me/nutrition-goal", userHandler.UpdateNutritionGoal)
		users.PATCH("/me/settings", userHandler.UpdateSettings)
		users.DELETE("/me", userHandler.WithdrawAccount)

		// 타인 정보 및 검색
		users.GET("/:id/profile", userHandler.GetOtherProfile)
		users.GET("/search", userHandler.Search)
		users.GET("/recommendations", userHandler.GetRecommendations)
		users.POST("/onboarding", userHandler.Onboarding)
	}
}
