package router

import (
	"encoding/json"
	"net/http"

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

	// Swagger UI - 요청의 Host 헤더를 기반으로 spec의 host 동적 설정
	r.GET("/swagger/*any", swaggerHandlerWithDynamicHost())

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

// swaggerHandlerWithDynamicHost swagger.json의 host를 요청의 Host 헤더로 동적 설정
func swaggerHandlerWithDynamicHost() gin.HandlerFunc {
	swaggerHandler := ginSwagger.WrapHandler(swaggerFiles.Handler)

	return func(c *gin.Context) {
		// swagger.json 요청인 경우에만 host 수정
		if c.Request.URL.Path == "/swagger/doc.json" {
			// swagger.json 문서를 읽어서 host 필드 수정
			modifySwaggerHost(c)
			return
		}

		// 다른 swagger 리소스는 기본 handler 사용
		swaggerHandler(c)
	}
}

// modifySwaggerHost swagger.json의 host를 현재 요청의 Host로 수정
func modifySwaggerHost(c *gin.Context) {
	// swagger.json 파일 읽기
	jsonData, err := swaggerFiles.ReadFile("swagger.json")
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "swagger.json not found"})
		return
	}

	// JSON을 map으로 파싱
	var spec map[string]interface{}
	if err := json.Unmarshal(jsonData, &spec); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse swagger.json"})
		return
	}

	// 현재 요청의 Host를 spec에 설정
	spec["host"] = c.Request.Host

	// 수정된 JSON 응답
	c.JSON(http.StatusOK, spec)
}
