package route

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/middleware"
	"github.com/gin-gonic/gin"
)

func NotificationRoute(r *gin.RouterGroup, h *handler.NotificationHandler) {
	notification := r.Group("/notifications")
	notification.Use(middleware.AuthMiddleware())
	{
		notification.GET("", h.GetNotifications)
		notification.PATCH("/:id/read", h.ReadNotification)
		notification.POST("/read-all", h.ReadAllNotifications)
	}
}
