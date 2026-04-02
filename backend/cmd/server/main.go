package main

import (
	"log"
	"os"

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

	// 의존성 조립 (DI)
	badgeRepo := repository.NewBadgeRepository()
	badgeUC := usecase.NewBadgeUsecase(badgeRepo, nil)
	collectionHandler := handler.NewCollectionHandler(badgeUC)

	r := router.NewRouter(collectionHandler)

	log.Printf("Mukzzi server listening on :%s", port)
	log.Fatal(r.Run(":" + port))
}
