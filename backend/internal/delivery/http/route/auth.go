package route

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/gin-gonic/gin"
)

// AuthRoute 는 인증 관련 라우트를 등록합니다.
func AuthRoute(rg *gin.RouterGroup, authHandler *handler.AuthHandler) {
	auth := rg.Group("/auth")
	{
		auth.POST("/register", authHandler.Register)
		auth.POST("/login", authHandler.Login)
	}
}
