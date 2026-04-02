package router

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/handler"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"

	docs "github.com/SeoHyeokGyu/Mukzzi/backend/docs"
)

func NewRouter(
	collectionHandler *handler.CollectionHandler,
	menuHandler *handler.MenuHandler,
) *gin.Engine {
	r := gin.Default()

	r.Use(cors.Default())

	r.GET("/health", func(c *gin.Context) {
		c.String(200, "ok")
	})

	r.GET("/swagger/*any", func(c *gin.Context) {
		docs.SwaggerInfo.Host = c.Request.Host
		docs.SwaggerInfo.Schemes = []string{"http", "https"}
		ginSwagger.WrapHandler(swaggerFiles.Handler)(c)
	})

	v1 := r.Group("/api/v1")
	{
		collections := v1.Group("/collections")
		{
			collections.GET("/badges", collectionHandler.GetBadges)
		}

		menus := v1.Group("/menus")
		{
			menus.GET("/search", menuHandler.Search)
		}
	}

	return r
}
