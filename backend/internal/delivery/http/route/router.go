package route

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/docs"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/middleware"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

// NewRouter 는 Gin 엔진을 생성하고 미들웨어와 모든 라우트를 등록합니다.
func NewRouter(
	authHandler *handler.AuthHandler,
	userHandler *handler.UserHandler,
	collectionHandler *handler.CollectionHandler,
	menuHandler *handler.MenuHandler,
	socialHandler *handler.SocialHandler,
	notificationHandler *handler.NotificationHandler,
	mealHandler *handler.MealHandler,
	favoriteHandler *handler.FavoriteHandler,
	preferenceHandler *handler.PreferenceHandler,
	rouletteHandler *handler.RouletteHandler,
	filterHandler *handler.MenuFilterHandler,
	questHandler *handler.QuestHandler,
	recHandler *handler.MenuRecommendationHandler,
	aiHandler *handler.AIHandler,
	uploadHandler *handler.UploadHandler,
	seedHandler *handler.SeedHandler,
) *gin.Engine {
	r := gin.New()

	// CORS 상세 설정
	config := cors.DefaultConfig()
	config.AllowAllOrigins = true
	config.AllowMethods = []string{"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"}
	config.AllowHeaders = []string{"Origin", "Content-Length", "Content-Type", "Authorization", "X-Request-ID", "Cache-Control"}
	config.AllowCredentials = true

	// 전역 미들웨어 설정
	r.Use(gin.Recovery())
	r.Use(middleware.RequestIDMiddleware())
	r.Use(middleware.LoggerMiddleware())
	r.Use(cors.New(config))

	// 헬스체크
	r.GET("/health", func(c *gin.Context) {
		c.String(200, "ok")
	})

	// Swagger UI
	r.GET("/swagger/*any", func(c *gin.Context) {
		docs.SwaggerInfo.Host = c.Request.Host
		docs.SwaggerInfo.Schemes = []string{"http", "https"}
		ginSwagger.WrapHandler(swaggerFiles.Handler)(c)
	})

	// 정적 파일 서빙
	r.Static("/uploads", "./uploads")

	// API 라우트 그룹
	api := r.Group("/api")
	{
		AuthRoute(api, authHandler)
		UserRoute(api, userHandler)
		CollectionRoute(api, collectionHandler)
		MenuRoute(api, menuHandler, favoriteHandler, preferenceHandler, rouletteHandler, filterHandler, recHandler)
		SocialRoute(api, socialHandler)
		NotificationRoute(api, notificationHandler)
		MealRoute(api, mealHandler)
		QuestRoute(api, questHandler)
		CharacterRoute(api, userHandler)
		AIRoute(api, aiHandler)
		UploadRoute(api, uploadHandler)
		SeedRoute(api, seedHandler)
	}

	return r
}
