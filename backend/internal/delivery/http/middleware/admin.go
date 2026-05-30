package middleware

import (
	"os"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/gin-gonic/gin"
)

// AdminOnlyMiddleware 는 ADMIN_USER_ID 환경변수에 등록된 유저만 통과시킵니다.
// AuthMiddleware 이후에 사용해야 합니다.
func AdminOnlyMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		adminID := os.Getenv("ADMIN_USER_ID")
		if adminID == "" {
			handler.InternalError(c, "관리자 ID가 설정되지 않았습니다.", "ADMIN_USER_ID not set")
			c.Abort()
			return
		}

		userIDStr, _ := c.Get("userIDStr")
		if userIDStr != adminID {
			handler.Forbidden(c, "FORBIDDEN", "관리자 권한이 필요합니다.")
			c.Abort()
			return
		}

		c.Next()
	}
}
