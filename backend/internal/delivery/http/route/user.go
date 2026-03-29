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
		
		users.GET("/me", userHandler.GetMe)
		users.GET("/:id", userHandler.GetProfile)
		users.PUT("/:id", userHandler.UpdateProfile)
		users.DELETE("/:id", userHandler.DeleteAccount)
	}
}
