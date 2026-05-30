package route

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/middleware"
	"github.com/gin-gonic/gin"
)

func UploadRoute(rg *gin.RouterGroup, h *handler.UploadHandler) {
	upload := rg.Group("/upload")
	upload.Use(middleware.AuthMiddleware())
	{
		upload.POST("/image", h.UploadImage)
	}
}
