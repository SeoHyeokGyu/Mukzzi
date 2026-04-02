package router

import (
	"os"
	"strings"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	ginSwagger "github.com/swaggo/gin-swagger"
	swaggerFiles "github.com/swaggo/files"

	_ "github.com/SeoHyeokGyu/Mukzzi/backend/docs"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/handler"
)

// NewRouter Gin 엔진 생성 및 라우트 등록
func NewRouter(collectionHandler *handler.CollectionHandler) *gin.Engine {
	r := gin.Default()

	// CORS 미들웨어
	r.Use(cors.Default())

	// 헬스체크
	r.GET("/health", func(c *gin.Context) {
		c.String(200, "ok")
	})

	// Swagger UI - 동적 host 설정
	swaggerURL := getSwaggerURL()
	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler, ginSwagger.URL(swaggerURL)))

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

// getSwaggerURL 환경변수에 따라 Swagger 문서 URL 생성
func getSwaggerURL() string {
	serverIP := os.Getenv("SERVER_IP")
	serverPort := os.Getenv("SERVER_PORT")
	if serverPort == "" {
		serverPort = "8080"
	}

	// SERVER_IP가 설정되지 않았으면 localhost 사용
	if serverIP == "" {
		serverIP = "localhost"
	}

	// swagger.json 경로
	swaggerURL := "/swagger/doc.json"

	// HOST 헤더 기반으로 URL 구성 (docker-compose의 경우 IP:PORT 사용)
	if strings.Contains(serverIP, "localhost") || serverIP == "" {
		return swaggerURL
	}

	// 프로덕션 환경에서 절대 URL 사용
	return "http://" + serverIP + ":" + serverPort + swaggerURL
}
