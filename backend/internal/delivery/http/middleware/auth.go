package middleware

import (
	"fmt"
	"os"
	"strings"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// AuthMiddleware 는 JWT 토큰을 검증하는 미들웨어입니다.
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			handler.Unauthorized(c, "MISSING_TOKEN", "인증 토큰이 필요합니다.")
			c.Abort()
			return
		}

		// Bearer 토큰 형식 확인
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			handler.Unauthorized(c, "INVALID_TOKEN_FORMAT", "토큰 형식이 올바르지 않습니다.")
			c.Abort()
			return
		}

		tokenString := parts[1]
		jwtSecret := os.Getenv("JWT_SECRET")
		if jwtSecret == "" {
			jwtSecret = "mukzzi-secret"
		}

		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
			}
			return []byte(jwtSecret), nil
		})

		if err != nil || !token.Valid {
			handler.Unauthorized(c, "INVALID_TOKEN", "유효하지 않은 토큰입니다.")
			c.Abort()
			return
		}

		// 토큰에서 사용자 ID 추출 (문자열로 파싱하여 64비트 정밀도 손실 방지)
		if claims, ok := token.Claims.(jwt.MapClaims); ok {
			userIDStr, ok := claims["user_id"].(string)
			if !ok {
				handler.Unauthorized(c, "INVALID_TOKEN_PAYLOAD", "토큰 페이로드가 유효하지 않습니다.")
				c.Abort()
				return
			}
			
			var userID int64
			_, err := fmt.Sscanf(userIDStr, "%d", &userID)
			if err != nil {
				handler.Unauthorized(c, "INVALID_USER_ID", "유효하지 않은 사용자 ID입니다.")
				c.Abort()
				return
			}
			c.Set("userID", userID)
		}

		c.Next()
	}
}
