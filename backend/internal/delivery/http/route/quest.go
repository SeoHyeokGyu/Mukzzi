package route

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/middleware"
	"github.com/gin-gonic/gin"
)

func QuestRoute(api *gin.RouterGroup, h *handler.QuestHandler) {
	quests := api.Group("/quests")
	quests.Use(middleware.AuthMiddleware())
	{
		quests.GET("", h.GetMyQuests)
		quests.POST("/:id/claim", h.ClaimReward)
	}
}
