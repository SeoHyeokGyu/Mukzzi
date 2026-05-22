package usecase

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"gorm.io/gorm"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

// ─────────────────────────────────────────
// 에러 정의
// ─────────────────────────────────────────

var (
	ErrMealNotFound      = errors.New("MEAL_NOT_FOUND")
	ErrMealForbidden     = errors.New("MEAL_FORBIDDEN")
	ErrTagNotFound       = errors.New("TAG_NOT_FOUND")
	ErrTagAlreadyHandled = errors.New("TAG_ALREADY_HANDLED")
)

// ─────────────────────────────────────────
// Input / Output
// ─────────────────────────────────────────

type CreateMealInput struct {
	UserID      int64
	MenuID      *int64
	MenuName    string
	Category    string
	MealType    domain.MealType
	ServingSize float64
	RecordedAt  time.Time
	WeatherTag  *domain.WeatherTag
	MoodTag     *domain.MoodTag
	Review      *string
	Rating      *int
	IsManual    bool
	FriendTags  []int64
	ImageURL    *string
}

type UpdateMealInput struct {
	MealID      int64
	UserID      int64
	MenuName    *string
	Category    *string
	MealType    *domain.MealType
	ServingSize *float64
	RecordedAt  *time.Time
	WeatherTag  *domain.WeatherTag
	MoodTag     *domain.MoodTag
	Review      *string
	Rating      *int
}

type CreateMealOutput struct {
	Meal        *domain.MealRecord
	SideEffects *domain.MealSideEffects
}

type MealListOutput struct {
	Meals      []domain.MealRecord
	TotalCount int64
	HasNext    bool
}

// ─────────────────────────────────────────
// MealUsecase 인터페이스
// ─────────────────────────────────────────

type MealUsecase interface {
	CreateMeal(input CreateMealInput) (*CreateMealOutput, error)
	GetMeal(mealID int64, userID int64) (*domain.MealRecord, error)
	ListMeals(userID int64, filter domain.MealListFilter) (*MealListOutput, error)
	UpdateMeal(input UpdateMealInput) (*domain.MealRecord, error)
	DeleteMeal(mealID int64, userID int64) error
	AcceptFriendTag(mealID int64, taggedUserID int64) error
	GetTodayNutrition(userID int64) (*domain.DailyIntake, error)
	GetWeeklyNutrition(userID int64, startDate string) ([]domain.DailyIntake, error)
}

// ─────────────────────────────────────────
// 구현체
// ─────────────────────────────────────────

type mealUsecase struct {
	mealRepo            repository.MealRepository
	nutritionRepo       repository.NutritionRepository
	tagRepo             repository.MealFriendTagRepository
	menuRepo            repository.MenuRepository
	userUc              UserUsecase
	masteryTracker      MasteryTracker
	titleGranter        TitleGranter
	notificationUsecase NotificationUsecase
	eventBus            domain.EventBus
	questUc             QuestUsecase
	badgeGranter        BadgeGranter
	db                  *gorm.DB
}

func NewMealUsecase(
	mealRepo repository.MealRepository,
	nutritionRepo repository.NutritionRepository,
	tagRepo repository.MealFriendTagRepository,
	menuRepo repository.MenuRepository,
	userUc UserUsecase,
	masteryTracker MasteryTracker,
	titleGranter TitleGranter,
	notificationUsecase NotificationUsecase,
	eventBus domain.EventBus,
	questUc QuestUsecase,
	badgeGranter BadgeGranter,
	db *gorm.DB,
) MealUsecase {
	return &mealUsecase{
		mealRepo:            mealRepo,
		nutritionRepo:       nutritionRepo,
		tagRepo:             tagRepo,
		menuRepo:            menuRepo,
		userUc:              userUc,
		masteryTracker:      masteryTracker,
		titleGranter:        titleGranter,
		notificationUsecase: notificationUsecase,
		eventBus:            eventBus,
		questUc:             questUc,
		badgeGranter:        badgeGranter,
		db:                  db,
	}
}

func (u *mealUsecase) CreateMeal(input CreateMealInput) (*CreateMealOutput, error) {
	var output CreateMealOutput

	var menuData *domain.Menu
	if input.MenuID != nil {
		m, err := u.menuRepo.FindByID(*input.MenuID)
		if err != nil {
			return nil, err
		}
		menuData = m
	}

	err := u.db.Transaction(func(tx *gorm.DB) error {
		meal := &domain.MealRecord{
			UserID:      input.UserID,
			MenuID:      input.MenuID,
			ImageURL:    input.ImageURL,
			MenuName:    input.MenuName,
			Category:    input.Category,
			MealType:    input.MealType,
			ServingSize: input.ServingSize,
			RecordedAt:  input.RecordedAt,
			WeatherTag:  input.WeatherTag,
			MoodTag:     input.MoodTag,
			Review:      input.Review,
			Rating:      input.Rating,
			IsManual:    input.IsManual,
		}
		if err := tx.Create(meal).Error; err != nil {
			return err
		}

		nutrition := buildNutrition(meal.ID, menuData, input.ServingSize)
		if err := tx.Create(nutrition).Error; err != nil {
			return err
		}

		dateKey := repository.MealDateKey(input.RecordedAt)
		if err := repository.UpsertDailyIntakeInTx(tx, input.UserID, dateKey, nutrition); err != nil {
			return err
		}

		for _, friendID := range input.FriendTags {
			tag := &domain.MealFriendTag{
				MealID:       meal.ID,
				TaggedUserID: friendID,
				Status:       domain.FriendTagPending,
			}
			if err := tx.Create(tag).Error; err != nil {
				return err
			}
		}

		meal.Nutrition = nutrition
		output.Meal = meal
		return nil
	})
	if err != nil {
		return nil, err
	}

	ctx := context.Background()

	var masteryUpdate *domain.MasteryUpdate
	// 칭호 부여 체크
	var grantedTitle *domain.Title
	var menuID int64
	if input.MenuID != nil {
		menuID = *input.MenuID
	}
	updatedMastery, err := u.masteryTracker.OnMealCreated(ctx, input.UserID, menuID)
	if err != nil {
		slog.Error("마스터리 업데이트 실패", slog.Int64("user_id", input.UserID), slog.Any("error", err))
	} else if updatedMastery != nil {
		masteryUpdate = &domain.MasteryUpdate{
			MenuName:     input.MenuName,
			EatCount:     updatedMastery.EatCount,
			Grade:        string(updatedMastery.Grade),
			GradeChanged: true,
		}
		grantedTitle, err = u.titleGranter.OnMasteryGradeChanged(ctx, input.UserID, updatedMastery.Grade)
		if err != nil {
			slog.Error("칭호 부여 실패", slog.Int64("user_id", input.UserID), slog.Any("error", err))
			grantedTitle = nil
		}
	}

	// streak 갱신
	if err := u.userUc.UpdateStreakOnMeal(input.UserID, input.RecordedAt); err != nil {
		slog.Error("streak 갱신 실패", slog.Int64("user_id", input.UserID), slog.Any("error", err))
	}

	// 캐릭터 외형 재계산 (당일 영양소 기준)
	var appearanceEvent *domain.AppearanceChangedEvent
	appearanceEvent, err = u.userUc.RecalcAppearance(input.UserID, input.RecordedAt)
	if err != nil {
		slog.Error("외형 재계산 실패", slog.Int64("user_id", input.UserID), slog.Any("error", err))
	}

	// 퀘스트 진행도 갱신
	event := domain.Event{
		Type:      domain.EventMealCreated,
		UserID:    input.UserID,
		CreatedAt: time.Now(),
		Payload: map[string]interface{}{
			"meal_id":   output.Meal.ID,
			"meal_type": string(output.Meal.MealType),
			"calories":  output.Meal.Nutrition.Calories,
			"carbs":     output.Meal.Nutrition.Carbs,
			"protein":   output.Meal.Nutrition.Protein,
			"fat":       output.Meal.Nutrition.Fat,
		},
	}
	
	// 이벤트 발행은 비동기로 처리 (성능 향상)
	go u.eventBus.Publish(event)

	progressedQuests, err := u.questUc.HandleEvent(ctx, event)
	if err != nil {
		slog.Error("퀘스트 업데이트 실패", slog.Int64("user_id", input.UserID), slog.Any("error", err))
		progressedQuests = []domain.QuestProgress{}
	}

	// 뱃지 부여 체크 및 알림 생성도 비동기로 처리 (응답 속도 개선)
	go func() {
		bgCtx := context.Background()
		grantedBadges, err := u.badgeGranter.CheckAndGrant(bgCtx, input.UserID, EventMealCreated)
		if err != nil {
			slog.Error("뱃지 부여 실패", slog.Int64("user_id", input.UserID), slog.Any("error", err))
			return
		}
		
		for _, b := range grantedBadges {
			_ = u.notificationUsecase.CreateNotification(&domain.Notification{
				UserID:  input.UserID,
				Type:    domain.NotificationTypeBadgeAcquired,
				Title:   "새로운 뱃지 획득!",
				Content: fmt.Sprintf("[%s] 뱃지를 획득했습니다!", b.Name),
				LinkURL: "/profile/badges",
			})
		}
	}()

	output.SideEffects = &domain.MealSideEffects{
		QuestsProgressed:  progressedQuests,
		GrantedBadges:     []domain.Badge{},
		MasteryUpdated:    masteryUpdate,
		GrantedTitle:      grantedTitle,
		AppearanceChanged: appearanceEvent,
	}

	return &output, nil
}

func (u *mealUsecase) GetMeal(mealID int64, userID int64) (*domain.MealRecord, error) {
	meal, err := u.mealRepo.FindByID(mealID)
	if err != nil {
		return nil, err
	}
	if meal == nil {
		return nil, ErrMealNotFound
	}
	if meal.UserID != userID {
		return nil, ErrMealForbidden
	}
	return meal, nil
}

func (u *mealUsecase) ListMeals(userID int64, filter domain.MealListFilter) (*MealListOutput, error) {
	if filter.Limit <= 0 {
		filter.Limit = 20
	}

	// menu.go 패턴: limit+1 개 조회해서 hasNext 판단
	filter.Limit++
	meals, total, err := u.mealRepo.FindByUserID(userID, filter)
	if err != nil {
		return nil, err
	}

	hasNext := len(meals) > filter.Limit-1
	if hasNext {
		meals = meals[:filter.Limit-1]
	}

	return &MealListOutput{
		Meals:      meals,
		TotalCount: total,
		HasNext:    hasNext,
	}, nil
}

func (u *mealUsecase) UpdateMeal(input UpdateMealInput) (*domain.MealRecord, error) {
	meal, err := u.mealRepo.FindByID(input.MealID)
	if err != nil {
		return nil, err
	}
	if meal == nil {
		return nil, ErrMealNotFound
	}
	if meal.UserID != input.UserID {
		return nil, ErrMealForbidden
	}

	if input.MenuName != nil {
		meal.MenuName = *input.MenuName
	}
	if input.Category != nil {
		meal.Category = *input.Category
	}
	if input.MealType != nil {
		meal.MealType = *input.MealType
	}
	if input.ServingSize != nil {
		meal.ServingSize = *input.ServingSize
	}
	if input.RecordedAt != nil {
		meal.RecordedAt = *input.RecordedAt
	}
	if input.WeatherTag != nil {
		meal.WeatherTag = input.WeatherTag
	}
	if input.MoodTag != nil {
		meal.MoodTag = input.MoodTag
	}
	if input.Review != nil {
		meal.Review = input.Review
	}
	if input.Rating != nil {
		meal.Rating = input.Rating
	}

	if err := u.mealRepo.Update(meal); err != nil {
		return nil, err
	}
	return meal, nil
}

func (u *mealUsecase) DeleteMeal(mealID int64, userID int64) error {
	err := u.mealRepo.Delete(mealID, userID)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return ErrMealNotFound
	}
	if err != nil {
		return err
	}

	// 스트릭 즉시 재계산 (정합성 보장)
	if err := u.userUc.RecalculateStreak(userID); err != nil {
		slog.Error("식사 삭제 후 스트릭 재계산 실패", slog.Int64("user_id", userID), slog.Any("error", err))
	}

	return nil
}

func (u *mealUsecase) AcceptFriendTag(mealID int64, taggedUserID int64) error {
	err := u.tagRepo.AcceptTag(mealID, taggedUserID)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return ErrTagNotFound
	}
	return err
}

func (u *mealUsecase) GetTodayNutrition(userID int64) (*domain.DailyIntake, error) {
	today := repository.MealDateKey(time.Now())
	di, err := u.nutritionRepo.FindDailyIntake(userID, today)
	if err != nil {
		return nil, err
	}
	if di == nil {
		parsedToday, _ := time.Parse(time.DateOnly, today)
		return &domain.DailyIntake{UserID: userID, Date: parsedToday}, nil
	}
	return di, nil
}

func (u *mealUsecase) GetWeeklyNutrition(userID int64, startDate string) ([]domain.DailyIntake, error) {
	start, err := time.Parse(time.DateOnly, startDate)
	if err != nil {
		return nil, fmt.Errorf("startDate 형식이 올바르지 않습니다: %w", err)
	}
	endDate := start.AddDate(0, 0, 6).Format(time.DateOnly)
	return u.nutritionRepo.FindWeeklyIntakes(userID, startDate, endDate)
}

// ─────────────────────────────────────────
// 내부 헬퍼
// ─────────────────────────────────────────

func buildNutrition(mealID int64, menu *domain.Menu, servingSize float64) *domain.Nutrition {
	n := &domain.Nutrition{MealID: mealID}
	if menu != nil {
		n.Calories = menu.DefaultCalories * servingSize
		n.Carbs = menu.DefaultCarbs * servingSize
		n.Protein = menu.DefaultProtein * servingSize
		n.Fat = menu.DefaultFat * servingSize
		n.Fiber = menu.DefaultFiber * servingSize
		n.VitaminScore = menu.DefaultVitaminScore
	}
	return n
}
