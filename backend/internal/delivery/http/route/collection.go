package route

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/middleware"
	"github.com/gin-gonic/gin"
)

// CollectionRoute 는 컬렉션 관련 라우트를 등록합니다.
func CollectionRoute(rg *gin.RouterGroup, collectionHandler *handler.CollectionHandler) {
	collections := rg.Group("/collections")
	{
		collections.Use(middleware.AuthMiddleware())

		collections.GET("/characters", collectionHandler.GetCharacterCollections)
		collections.GET("/mastery", collectionHandler.GetMasteries)
		collections.GET("/mastery/:menuId", collectionHandler.GetMasteryByMenu)
		collections.GET("/badges", collectionHandler.GetBadges)
		collections.GET("/titles", collectionHandler.GetTitles)
		collections.PATCH("/titles/equip", collectionHandler.EquipTitle)
		collections.GET("/rewards", collectionHandler.GetRewards)
	}
}
