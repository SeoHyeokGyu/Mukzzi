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
		// 로그인이 필요한 요청들에 미들웨어 적용
		collections.Use(middleware.AuthMiddleware())

		collections.GET("/badges", collectionHandler.GetBadges)
	}
}
