package main

import (
	"log/slog"
	"os"

	_ "github.com/SeoHyeokGyu/Mukzzi/backend/docs"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/config"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/route"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/joho/godotenv"
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
	// 환경 변수 로드
	if err := godotenv.Load("../.env"); err != nil {
		slog.Info(".env 파일을 찾을 수 없습니다. 환경 변수를 직접 사용합니다.")
	}

	// 로거 초기화
	config.InitLogger()

	// DB 초기화
	db := config.InitDB()

	// 포트 설정
	port := os.Getenv("SERVER_PORT")
	if port == "" {
		port = "8080"
	}

	// 의존성 주입 (DI)
	userRepo := repository.NewUserRepository(db)
	badgeRepo := repository.NewBadgeRepository(db)
	menuRepo := repository.NewMenuRepository(db)
	socialRepo := repository.NewSocialRepository(db)
	mealRepo := repository.NewMealRepository(db)
	nutritionRepo := repository.NewNutritionRepository(db)
	tagRepo := repository.NewMealFriendTagRepository(db)
	dailyIntakeRepo := repository.NewDailyIntakeRepository(db)
	charCollectionRepo := repository.NewCharacterCollectionRepository(db)
	masteryRepo := repository.NewMasteryRepository(db)
	titleRepo := repository.NewTitleRepository(db)
	rewardRepo := repository.NewRewardRepository(db)
	notificationRepo := repository.NewNotificationRepository(db)

	// Auth 도메인
	authUsecase := usecase.NewAuthUsecase(userRepo)
	authHandler := handler.NewAuthHandler(authUsecase)

	// User 도메인
	userUsecase := usecase.NewUserUsecase(userRepo)
	userHandler := handler.NewUserHandler(userUsecase)

	// Collection 도메인
	badgeGranter := usecase.NewBadgeGranter(badgeRepo, mealRepo, dailyIntakeRepo, charCollectionRepo)
	badgeUsecase := usecase.NewBadgeUsecase(badgeRepo)
	charCollectionUsecase := usecase.NewCharacterCollectionUsecase(charCollectionRepo)
	masteryUsecase := usecase.NewMasteryUsecase(masteryRepo)
	titleUsecase := usecase.NewTitleUsecase(titleRepo, userRepo)
	rewardUsecase := usecase.NewRewardUsecase(rewardRepo)
	collectionHandler := handler.NewCollectionHandler(badgeUsecase, charCollectionUsecase, masteryUsecase, titleUsecase, rewardUsecase)

	// Menu 도메인
	menuUsecase := usecase.NewMenuUsecase(menuRepo)
	menuHandler := handler.NewMenuHandler(menuUsecase)

	// Notification 도메인
	notificationUsecase := usecase.NewNotificationUsecase(notificationRepo)
	notificationHandler := handler.NewNotificationHandler(notificationUsecase)

	// Social 도메인
	socialUsecase := usecase.NewSocialUsecase(socialRepo, userRepo, notificationUsecase)
	socialHandler := handler.NewSocialHandler(socialUsecase)

	// Meal 도메인
	mealUsecase := usecase.NewMealUsecase(mealRepo, nutritionRepo, tagRepo, menuRepo, db)
	mealHandler := handler.NewMealHandler(mealUsecase)

	_ = badgeGranter // 추후 Meal 유즈케이스에 주입 예정

	// 라우터 초기화
	r := route.NewRouter(
		authHandler,
		userHandler,
		collectionHandler,
		menuHandler,
		socialHandler,
		notificationHandler,
		mealHandler,
	)

	// 서버 실행
	slog.Info("Mukzzi server listening", slog.String("port", port))
	if err := r.Run(":" + port); err != nil {
		slog.Error("서버 실행 실패", slog.Any("error", err))
		os.Exit(1)
	}
}
