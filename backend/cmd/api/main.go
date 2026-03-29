package main

import (
	"log"
	"os"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/config"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/middleware"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/route"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// 환경 변수 로드 (현재 디렉토리 또는 상위 디렉토리에서 .env 탐색)
	if err := godotenv.Load("../.env"); err != nil {
		log.Println(".env 파일을 찾을 수 없습니다. 환경 변수를 직접 사용합니다.")
	}

	// DB 초기화
	db := config.InitDB()

	// Gin 엔진 생성
	r := gin.New()

	// 전역 미들웨어 설정
	r.Use(gin.Recovery())                   // 패닉 방지
	r.Use(middleware.RequestIDMiddleware()) // 요청마다 고유 ID 부여
	r.Use(middleware.LoggerMiddleware())    // 상세 API 로그 기록

	// 포트 설정
	port := os.Getenv("SERVER_PORT")
	if port == "" {
		port = "8080"
	}

	// Health Check
	r.GET("/health", func(c *gin.Context) {
		c.String(200, "ok")
	})

	// 의존성 주입 (DI)
	userRepo := repository.NewUserRepository(db)

	// Auth 도메인
	authUsecase := usecase.NewAuthUsecase(userRepo)
	authHandler := handler.NewAuthHandler(authUsecase)

	// User 도메인
	userUsecase := usecase.NewUserUsecase(userRepo)
	userHandler := handler.NewUserHandler(userUsecase)

	// 라우트 등록
	api := r.Group("/api")
	route.AuthRoute(api, authHandler)
	route.UserRoute(api, userHandler)

	// 서버 실행
	log.Printf("Mukzzi server listening on :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal("서버 실행 실패:", err)
	}
}
