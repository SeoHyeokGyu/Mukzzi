package route

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/middleware"
	"github.com/gin-gonic/gin"
)

func SocialRoute(rg *gin.RouterGroup, socialHandler *handler.SocialHandler) {
	// 9. 친구 관련 (/api/friends)
	friends := rg.Group("/friends")
	{
		friends.Use(middleware.AuthMiddleware())
		friends.GET("", socialHandler.GetFriends)
		friends.DELETE("/:userId", socialHandler.DeleteFriend)
		friends.GET("/requests", socialHandler.GetPendingRequests)
		friends.GET("/requests/sent", socialHandler.GetSentRequests)
		friends.POST("/requests/:userId", socialHandler.SendFriendRequest)
		friends.PATCH("/requests/:userId/accept", socialHandler.AcceptFriendRequest)
		friends.PATCH("/requests/:userId/reject", socialHandler.RejectFriendRequest)
	}

	// 10. 상호작용 관련 (/api/users/:id/...)
	interaction := rg.Group("/users/:id")
	{
		interaction.Use(middleware.AuthMiddleware())
		interaction.POST("/nudge", socialHandler.Nudge)
		interaction.GET("/guestbook", socialHandler.GetGuestbooks)
		interaction.POST("/guestbook", socialHandler.WriteGuestbook)
		interaction.POST("/block", socialHandler.BlockUser)
		interaction.DELETE("/block", socialHandler.UnblockUser)
		interaction.POST("/report", socialHandler.ReportUser)
	}
}
