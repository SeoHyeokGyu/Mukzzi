package route

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/middleware"
	"github.com/gin-gonic/gin"
)

// CharacterRoute 는 캐릭터 관련 라우트를 등록합니다.
func CharacterRoute(rg *gin.RouterGroup, userHandler *handler.UserHandler) {
	characters := rg.Group("/characters")
	{
		characters.Use(middleware.AuthMiddleware())
		characters.PATCH("/me/equipment", userHandler.EquipItem)
	}
}
