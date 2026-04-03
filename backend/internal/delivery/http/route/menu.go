package route

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/middleware"
	"github.com/gin-gonic/gin"
)

// MenuRoute 는 메뉴 관련 라우트를 등록합니다.
func MenuRoute(rg *gin.RouterGroup, menuHandler *handler.MenuHandler) {
	menus := rg.Group("/menus")
	{
		// 로그인이 필요한 요청들에 미들웨어 적용
		menus.Use(middleware.AuthMiddleware())

		menus.GET("/search", menuHandler.Search)
	}
}
