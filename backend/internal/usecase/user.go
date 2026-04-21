package usecase

import (
	"encoding/json"
	"errors"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
	"gorm.io/datatypes"
)

// UserStats 프로필 통계 데이터
type UserStats struct {
	TotalMeals int64 `json:"total_meals"`
	StreakDays int   `json:"streak_days"`
	BadgeCount int64 `json:"badge_count"`
}

// UserUsecase 인터페이스는 사용자 프로필 관련 비즈니스 로직을 정의합니다.
type UserUsecase interface {
	GetProfile(id int64) (*domain.User, error)
	GetStats(id int64) (*UserStats, error)
	UpdateProfile(id int64, nickname, profileImageURL string) error
	UpdateBody(id int64, height, weight float64, activityLevel domain.ActivityLevel) error
	UpdateNutritionGoal(id int64, goal domain.DietGoal) error
	UpdateSettings(id int64, privacyLevel *domain.PrivacyLevel, notificationSettings any) error
	DeleteAccount(id int64) error
	Search(query string) ([]domain.User, error)
	GetRecommendations(id int64) ([]domain.User, error)
}

type userUsecase struct {
	userRepo        repository.UserRepository
	mealRepo        repository.MealRepository
	dailyIntakeRepo repository.DailyIntakeRepository
	badgeRepo       repository.BadgeRepository
}

// NewUserUsecase 는 UserUsecase 인터페이스의 구현체를 반환합니다.
func NewUserUsecase(
	userRepo repository.UserRepository,
	mealRepo repository.MealRepository,
	dailyIntakeRepo repository.DailyIntakeRepository,
	badgeRepo repository.BadgeRepository,
) UserUsecase {
	return &userUsecase{
		userRepo:        userRepo,
		mealRepo:        mealRepo,
		dailyIntakeRepo: dailyIntakeRepo,
		badgeRepo:       badgeRepo,
	}
}

func (u *userUsecase) GetProfile(id int64) (*domain.User, error) {
	user, err := u.userRepo.GetByID(id)
	if err != nil {
		return nil, err
	}
	user.Password = ""
	return user, nil
}

func (u *userUsecase) GetStats(id int64) (*UserStats, error) {
	totalMeals, err := u.mealRepo.CountByUserID(id)
	if err != nil {
		return nil, err
	}
	streakDays, err := u.dailyIntakeRepo.CountStreakDays(id)
	if err != nil {
		return nil, err
	}
	badgeCount, err := u.badgeRepo.CountUserAcquiredBadges(id)
	if err != nil {
		return nil, err
	}
	return &UserStats{
		TotalMeals: totalMeals,
		StreakDays:  streakDays,
		BadgeCount: badgeCount,
	}, nil
}

func (u *userUsecase) UpdateProfile(id int64, nickname, profileImageURL string) error {
	user, err := u.userRepo.GetByID(id)
	if err != nil {
		return err
	}

	if nickname != "" {
		user.Nickname = nickname
	}
	if profileImageURL != "" {
		user.ProfileImageURL = profileImageURL
	}

	return u.userRepo.Update(user)
}

func (u *userUsecase) UpdateBody(id int64, height, weight float64, activityLevel domain.ActivityLevel) error {
	// 1. 새로운 신체 정보 생성 (이력 관리)
	newBody := &domain.UserBody{
		UserID:        id,
		Height:        height,
		Weight:        weight,
		ActivityLevel: activityLevel,
	}

	if err := u.userRepo.CreateBody(newBody); err != nil {
		return err
	}

	// 2. 영양 목표가 이미 있다면 재계산하여 업데이트
	nutritionGoal, err := u.userRepo.GetNutritionGoal(id)
	if err == nil && nutritionGoal != nil {
		u.calculateNutritionTargets(newBody, nutritionGoal)
		return u.userRepo.CreateOrUpdateNutritionGoal(nutritionGoal)
	}

	return nil
}

func (u *userUsecase) UpdateNutritionGoal(id int64, goal domain.DietGoal) error {
	// 1. 최신 신체 정보 조회
	body, err := u.userRepo.GetLatestBody(id)
	if err != nil || body == nil {
		return errors.New("신체 정보를 먼저 등록해주세요.")
	}

	// 2. 영양 목표 생성 또는 업데이트
	nutritionGoal := &domain.UserNutritionGoal{
		UserID: id,
		Goal:   goal,
	}

	u.calculateNutritionTargets(body, nutritionGoal)

	return u.userRepo.CreateOrUpdateNutritionGoal(nutritionGoal)
}

func (u *userUsecase) UpdateSettings(id int64, privacyLevel *domain.PrivacyLevel, notificationSettings any) error {
	user, err := u.userRepo.GetByID(id)
	if err != nil {
		return err
	}

	if privacyLevel != nil {
		user.PrivacyLevel = *privacyLevel
	}

	if notificationSettings != nil {
		b, err := json.Marshal(notificationSettings)
		if err != nil {
			return err
		}
		user.NotificationSettings = datatypes.JSON(b)
	}

	return u.userRepo.Update(user)
}

func (u *userUsecase) DeleteAccount(id int64) error {
	return u.userRepo.Delete(id)
}

func (u *userUsecase) Search(query string) ([]domain.User, error) {
	return u.userRepo.Search(query)
}

func (u *userUsecase) GetRecommendations(id int64) ([]domain.User, error) {
	// 상위 10명의 추천 사용자 조회
	return u.userRepo.GetRecommendations(id, 10)
}

// calculateNutritionTargets 는 신체 정보와 목표를 기반으로 영양 목표를 계산합니다.
func (u *userUsecase) calculateNutritionTargets(body *domain.UserBody, goal *domain.UserNutritionGoal) {
	if body == nil || goal == nil {
		return
	}

	// 단순화된 계산식 (Mifflin-St Jeor 기반 가상 로직)
	bmr := 10*(body.Weight) + 6.25*(body.Height) - 120

	var activityFactor float64
	switch body.ActivityLevel {
	case domain.ActivityLow:
		activityFactor = 1.2
	case domain.ActivityModerate:
		activityFactor = 1.375
	case domain.ActivityHigh:
		activityFactor = 1.55
	case domain.ActivityVeryHigh:
		activityFactor = 1.725
	default:
		activityFactor = 1.2
	}

	tdee := bmr * activityFactor

	var kcalTarget float64
	switch goal.Goal {
	case domain.GoalDiet:
		kcalTarget = tdee - 500
	case domain.GoalBulk:
		kcalTarget = tdee + 300
	default:
		kcalTarget = tdee
	}

	goal.DailyKcalTarget = int(kcalTarget)
	goal.DailyCarbsTarget = int(kcalTarget * 0.5 / 4)
	goal.DailyProteinTarget = int(kcalTarget * 0.3 / 4)
	goal.DailyFatTarget = int(kcalTarget * 0.2 / 9)
}
