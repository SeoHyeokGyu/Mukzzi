package main

import (
	"log"
	"os"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/handler"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/router"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
)

// @title           Mukzzi API
// @version         1.0
// @description     Mukzzi 서비스 API 문서입니다.
// @host            localhost:8080
// @BasePath        /
// @securityDefinitions.apikey  BearerAuth
// @in              header
// @name            Authorization
func main() {
	port := os.Getenv("SERVER_PORT")
	if port == "" {
		port = "8080"
	}

	// DB 연결
	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		log.Fatal("DATABASE_URL environment variable not set")
	}

	db, err := gorm.Open(postgres.Open(databaseURL), &gorm.Config{})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// DB 마이그레이션
	if err := db.AutoMigrate(
		&domain.Badge{},
		&domain.UserBadge{},
		&domain.Menu{},
	); err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}

	// 의존성 조립 (DI)
	badgeRepo := repository.NewBadgeRepository()
	badgeUC := usecase.NewBadgeUsecase(badgeRepo, db)
	collectionHandler := handler.NewCollectionHandler(badgeUC)

	menuRepo := repository.NewMenuRepository()
	menuUC := usecase.NewMenuUsecase(menuRepo, db)
	menuHandler := handler.NewMenuHandler(menuUC)

	r := router.NewRouter(collectionHandler, menuHandler)

	log.Printf("Mukzzi server listening on :%s", port)
	log.Fatal(r.Run(":" + port))
}
