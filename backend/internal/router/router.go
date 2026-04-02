package router

import (
	"github.com/gin-gonic/gin"
	ginSwagger "github.com/swaggo/gin-swagger"
	swaggerFiles "github.com/swaggo/files"

	_ "github.com/SeoHyeokGyu/Mukzzi/backend/docs"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/handler"
)

// NewRouter Gin 엔진 생성 및 라우트 등록
func NewRouter(collectionHandler *handler.CollectionHandler) *gin.Engine {
	r := gin.Default()

	// 헬스체크
	r.GET("/health", func(c *gin.Context) {
		c.String(200, "ok")
	})

	// Swagger UI
	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// API v1
	v1 := r.Group("/api/v1")
	{
		collections := v1.Group("/collections")
		{
			collections.GET("/badges", collectionHandler.GetBadges)
		}
	}

	return r
}
