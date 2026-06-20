package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"time"

	_ "github.com/SeoHyeokGyu/Mukzzi/backend/docs"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/config"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/route"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/infrastructure/eventbus"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/infrastructure/gemini"
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
	start := time.Now()
	db := config.InitDB()
	slog.Info("DB 초기화 완료", slog.Duration("elapsed", time.Since(start)))

	start = time.Now()
	config.SeedTitles(db)
	slog.Info("칭호 시드 완료", slog.Duration("elapsed", time.Since(start)))

	start = time.Now()
	config.SeedBadges(db)
	slog.Info("뱃지 시드 완료", slog.Duration("elapsed", time.Since(start)))

	start = time.Now()
	config.SeedQuests(db)
	slog.Info("퀘스트 시드 완료", slog.Duration("elapsed", time.Since(start)))

	start = time.Now()
	config.SeedRewards(db)
	slog.Info("보상 시드 완료", slog.Duration("elapsed", time.Since(start)))

	start = time.Now()
	config.BackfillMenuAllergies(db)
	slog.Info("메뉴 알레르기 백필 완료", slog.Duration("elapsed", time.Since(start)))

	// Redis 초기화
	start = time.Now()
	rdb := config.InitRedis()
	slog.Info("Redis 초기화 완료", slog.Duration("elapsed", time.Since(start)))

	// 포트 설정
	port := os.Getenv("SERVER_PORT")
	if port == "" {
		port = "8080"
	}

	// 의존성 주입 (DI)
	eventBus := eventbus.NewInternalBus()

	userRepo := repository.NewUserRepository(db)
	badgeRepo := repository.NewBadgeRepository(db)
	menuRepo := repository.NewMenuRepository(db)
	socialRepo := repository.NewSocialRepository(db)
	mealRepo := repository.NewMealRepository(db)
	nutritionRepo := repository.NewNutritionRepository(db)
	tagRepo := repository.NewMealFriendTagRepository(db)
	dailyIntakeRepo := repository.NewDailyIntakeRepository(db)
	charCollectionRepo := repository.NewCharacterCollectionRepository(db)
	characterRepo := repository.NewCharacterRepository(db)
	masteryRepo := repository.NewMasteryRepository(db)
	titleRepo := repository.NewTitleRepository(db)
	rewardRepo := repository.NewRewardRepository(db)
	favoriteRepo := repository.NewFavoriteRepository(db)
	preferenceRepo := repository.NewPreferenceRepository(db)
	questRepo := repository.NewQuestRepository(db)

	// Auth 도메인
	authUsecase := usecase.NewAuthUsecase(userRepo, rdb)
	authHandler := handler.NewAuthHandler(authUsecase)

	// Notification 도메인 (UserUsecase 의존성으로 먼저 초기화)
	notificationRepo := repository.NewNotificationRepository(db)
	notificationUsecase := usecase.NewNotificationUsecase(notificationRepo)
	notificationHandler := handler.NewNotificationHandler(notificationUsecase)

	// Quest 도메인
	questUsecase := usecase.NewQuestUsecase(questRepo, userRepo, characterRepo, mealRepo, badgeRepo, titleRepo, eventBus, db)
	questHandler := handler.NewQuestHandler(questUsecase)

	// User 도메인
	userUsecase := usecase.NewUserUsecase(userRepo, mealRepo, dailyIntakeRepo, badgeRepo, charCollectionRepo, characterRepo, notificationUsecase, eventBus, rdb, db)
	userHandler := handler.NewUserHandler(userUsecase)

	// 이벤트 구독 설정
	eventBus.Subscribe(domain.EventUserOnboarded, func(ev domain.Event) {
		slog.Info("유저 온보딩 이벤트 수신, 퀘스트 할당 시작", slog.Int64("user_id", ev.UserID))
		ctx := context.Background()
		if err := questUsecase.AssignDailyQuests(ctx, ev.UserID); err != nil {
			slog.Error("온보딩 일일 퀘스트 할당 실패", slog.Int64("user_id", ev.UserID), slog.Any("error", err))
		}
		if err := questUsecase.AssignWeeklyQuests(ctx, ev.UserID); err != nil {
			slog.Error("온보딩 주간 퀘스트 할당 실패", slog.Int64("user_id", ev.UserID), slog.Any("error", err))
		}
		if err := questUsecase.AssignAchievementQuests(ctx, ev.UserID); err != nil {
			slog.Error("온보딩 업적 퀘스트 할당 실패", slog.Int64("user_id", ev.UserID), slog.Any("error", err))
		}
		if err := questUsecase.AssignTutorialQuest(ctx, ev.UserID); err != nil {
			slog.Error("온보딩 튜토리얼 퀘스트 할당 실패", slog.Int64("user_id", ev.UserID), slog.Any("error", err))
		}
	})

	eventBus.Subscribe(domain.EventQuestCompleted, func(ev domain.Event) {
		slog.Info("퀘스트 완료 이벤트 수신, 알림 생성", slog.Int64("user_id", ev.UserID))
		title := ev.Payload["quest_title"].(string)
		_ = notificationUsecase.CreateNotification(&domain.Notification{
			UserID:  ev.UserID,
			Type:    domain.NotificationTypeQuestCompleted,
			Title:   "퀘스트 완료!",
			Content: fmt.Sprintf("[%s] 퀘스트를 달성했습니다! 보상을 받으러 오세요.", title),
			LinkURL: "/home/quests",
		})
	})

	eventBus.Subscribe(domain.EventCharacterVisited, func(ev domain.Event) {
		slog.Info("친구 캐릭터 방문 이벤트 수신, 알림 생성", slog.Int64("visitor_id", ev.UserID))
		hostIDRaw, ok1 := ev.Payload["host_id"]
		interactionTypeRaw, ok2 := ev.Payload["interaction_type"]
		if !ok1 || !ok2 {
			slog.Error("이벤트 페이로드 누락")
			return
		}

		var hostID int64
		switch v := hostIDRaw.(type) {
		case int64:
			hostID = v
		case float64:
			hostID = int64(v)
		default:
			slog.Error("host_id의 타입이 유효하지 않습니다", slog.Any("host_id", hostIDRaw))
			return
		}

		interactionType, ok := interactionTypeRaw.(string)
		if !ok {
			slog.Error("interaction_type이 string이 아닙니다")
			return
		}

		visitor, err := userRepo.GetByID(ev.UserID)
		if err != nil {
			slog.Error("방문 유저 정보 조회 실패", slog.Int64("user_id", ev.UserID), slog.Any("error", err))
			return
		}

		var actionTitle string
		if interactionType == "FEED" {
			actionTitle = "먹이"
		} else {
			actionTitle = "응원"
		}

		_ = notificationUsecase.CreateNotification(&domain.Notification{
			UserID:   hostID,
			SenderID: &ev.UserID,
			Type:     domain.NotificationTypeNudge,
			Title:    fmt.Sprintf("캐릭터 룸 %s 도착", actionTitle),
			Content:  fmt.Sprintf("%s님이 내 먹찌에게 %s를 주었습니다!", visitor.Nickname, actionTitle),
			LinkURL:  "/social",
		})
	})

	// BadgeGranter 초기화 (여러 도메인에서 사용)
	badgeGranter := usecase.NewBadgeGranter(badgeRepo, mealRepo, dailyIntakeRepo, charCollectionRepo)

	// Collection 도메인
	badgeUsecase := usecase.NewBadgeUsecase(badgeRepo, badgeGranter)
	charCollectionUsecase := usecase.NewCharacterCollectionUsecase(charCollectionRepo)
	masteryUsecase := usecase.NewMasteryUsecase(masteryRepo)
	titleUsecase := usecase.NewTitleUsecase(titleRepo, userRepo)
	rewardUsecase := usecase.NewRewardUsecase(rewardRepo)
	collectionHandler := handler.NewCollectionHandler(badgeUsecase, charCollectionUsecase, masteryUsecase, titleUsecase, rewardUsecase)

	// Menu 도메인
	menuUsecase := usecase.NewMenuUsecase(menuRepo, favoriteRepo, preferenceRepo, rdb)
	menuHandler := handler.NewMenuHandler(menuUsecase)
	favoriteUsecase := usecase.NewFavoriteUsecase(favoriteRepo, menuRepo)
	favoriteHandler := handler.NewFavoriteHandler(favoriteUsecase)
	preferenceUsecase := usecase.NewPreferenceUsecase(preferenceRepo, menuRepo)
	preferenceHandler := handler.NewPreferenceHandler(preferenceUsecase)

	// 메뉴 Redis 동기화
	start = time.Now()
	if err := menuUsecase.SyncMenusToRedis(context.Background()); err != nil {
		slog.Error("메뉴 Redis 동기화 실패", slog.Any("error", err))
	} else {
		slog.Info("메뉴 Redis 동기화 완료", slog.Duration("elapsed", time.Since(start)))
	}

	// 랭킹 Redis 동기화
	start = time.Now()
	if err := userUsecase.SyncRankingToRedis(context.Background()); err != nil {
		slog.Error("랭킹 Redis 동기화 실패", slog.Any("error", err))
	} else {
		slog.Info("랭킹 Redis 동기화 완료", slog.Duration("elapsed", time.Since(start)))
	}

	// Social 도메인
	socialUsecase := usecase.NewSocialUsecase(socialRepo, userRepo, mealRepo, characterRepo, notificationUsecase, eventBus, rdb)
	socialHandler := handler.NewSocialHandler(socialUsecase)

	// AI 도메인 (Meal 도메인 등 여러 곳에서 사용되므로 미리 초기화)
	geminiClient, err := gemini.NewClient(os.Getenv("GEMINI_API_KEY"))
	if err != nil {
		slog.Error("Gemini 클라이언트 초기화 실패", slog.Any("error", err))
	}

	// Meal 도메인
	masteryTracker := usecase.NewMasteryTracker(masteryRepo)
	titleGranter := usecase.NewTitleGranter(titleRepo)
	mealUsecase := usecase.NewMealUsecase(mealRepo, nutritionRepo, tagRepo, menuRepo, userUsecase, masteryTracker, titleGranter, notificationUsecase, eventBus, questUsecase, badgeGranter, geminiClient, db, rdb)
	mealHandler := handler.NewMealHandler(mealUsecase)

	// Roulette 도메인
	rouletteRepo := repository.NewRouletteRepository(db)
	rouletteUc := usecase.NewRouletteUsecase(rouletteRepo)
	rouletteHandler := handler.NewRouletteHandler(rouletteUc)

	filterRepo := repository.NewMenuFilterRepository(db)
	filterUc := usecase.NewMenuFilterUsecase(filterRepo)
	filterHandler := handler.NewMenuFilterHandler(filterUc)

	// 추천 도메인
	recRepo := repository.NewMenuRecommendationRepository(db)
	recUc := usecase.NewMenuRecommendationUsecase(recRepo)
	recHandler := handler.NewMenuRecommendationHandler(recUc)

	// AI 도메인 라우터/핸들러 연동
	aiUc := usecase.NewAIUsecase(geminiClient, dailyIntakeRepo, mealRepo, userRepo, preferenceRepo, rdb)
	aiHandler := handler.NewAIHandler(aiUc)

	// 업로드 핸들러
	uploadHandler := handler.NewUploadHandler()

	// Seed 도메인 (menuRepo, rdb 의존 → menuUsecase 초기화 이후)
	seedUsecase := usecase.NewSeedUsecase(menuRepo, menuUsecase, db)
	seedHandler := handler.NewSeedHandler(seedUsecase)

	// 스케줄러 시작 (seedUsecase 초기화 완료 후)
	config.StartScheduler(userUsecase, questUsecase, seedUsecase)

	// 라우터 초기화
	r := route.NewRouter(
		authHandler,
		userHandler,
		collectionHandler,
		menuHandler,
		socialHandler,
		notificationHandler,
		mealHandler,
		favoriteHandler,
		preferenceHandler,
		rouletteHandler,
		filterHandler,
		questHandler,
		recHandler,
		aiHandler,
		uploadHandler,
		seedHandler,
	)

	// 서버 실행
	slog.Info("Mukzzi server listening", slog.String("port", port))
	if err := r.Run(":" + port); err != nil {
		slog.Error("서버 실행 실패", slog.Any("error", err))
		os.Exit(1)
	}
}
