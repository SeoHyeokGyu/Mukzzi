package route

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/middleware"
	"github.com/gin-gonic/gin"
)

// MenuRoute 는 메뉴 관련 라우트를 등록합니다.
func MenuRoute(
	rg *gin.RouterGroup,
	menuHandler *handler.MenuHandler,
	favoriteHandler *handler.FavoriteHandler,
) {
	menus := rg.Group("/menus")
	menus.Use(middleware.AuthMiddleware())
	{
		// 메뉴 검색/등록/조회
		menus.GET("/search", menuHandler.Search)
		menus.POST("", menuHandler.Create)
		menus.GET("/favorites", favoriteHandler.GetList) // /:id 보다 앞에 등록
		menus.GET("/:id", menuHandler.FindByID)

		// 즐겨찾기
		menus.POST("/:id/favorites", favoriteHandler.Add)
		menus.DELETE("/:id/favorites", favoriteHandler.Remove)
	}
}
