package middleware

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
)

func TestAuthMiddleware(t *testing.T) {
	gin.SetMode(gin.TestMode)
	jwtSecret := "test-secret"
	os.Setenv("JWT_SECRET", jwtSecret)

	setupRouter := func() *gin.Engine {
		r := gin.New()
		r.Use(AuthMiddleware())
		r.GET("/test", func(c *gin.Context) {
			userID, _ := c.Get("userID")
			c.JSON(http.StatusOK, gin.H{"userID": userID})
		})
		return r
	}

	createToken := func(userID int64) string {
		token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
			"user_id": fmt.Sprintf("%d", userID),
			"exp":     time.Now().Add(time.Hour).Unix(),
		})
		tString, _ := token.SignedString([]byte(jwtSecret))
		return tString
	}

	t.Run("유효한 토큰으로 요청 성공", func(t *testing.T) {
		r := setupRouter()
		token := createToken(12345)

		req, _ := http.NewRequest("GET", "/test", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.Contains(t, w.Body.String(), `"userID":12345`)
	})

	t.Run("인증 헤더 누락 시 401", func(t *testing.T) {
		r := setupRouter()

		req, _ := http.NewRequest("GET", "/test", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		assert.Contains(t, w.Body.String(), "MISSING_TOKEN")
	})

	t.Run("잘못된 형식의 인증 헤더 시 401", func(t *testing.T) {
		r := setupRouter()

		req, _ := http.NewRequest("GET", "/test", nil)
		req.Header.Set("Authorization", "InvalidFormat token")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		assert.Contains(t, w.Body.String(), "INVALID_TOKEN_FORMAT")
	})

	t.Run("만료되거나 유효하지 않은 토큰 시 401", func(t *testing.T) {
		r := setupRouter()

		req, _ := http.NewRequest("GET", "/test", nil)
		req.Header.Set("Authorization", "Bearer invalid.token.here")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		assert.Contains(t, w.Body.String(), "INVALID_TOKEN")
	})
}
