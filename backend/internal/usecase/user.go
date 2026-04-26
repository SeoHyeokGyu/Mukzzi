package usecase

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
	"github.com/redis/go-redis/v9"
	"gorm.io/datatypes"
	"gorm.io/gorm"
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
	ProcessPhysicalDeletion() error
	GetCharacter(id int64) (*domain.Character, error)
	Search(query string) ([]domain.User, error)
	GetRecommendations(id int64) ([]domain.User, error)
	Onboarding(id int64, mukzziName string, height, weight float64, activityLevel domain.ActivityLevel, goal domain.DietGoal, bodyType, muscle, skinTone, expression int) error
	AddExp(userID int64, amount int) error
	SyncRankingToRedis(ctx context.Context) error
}

type userUsecase struct {
	userRepo        repository.UserRepository
	mealRepo        repository.MealRepository
	dailyIntakeRepo repository.DailyIntakeRepository
	badgeRepo       repository.BadgeRepository
	charRepo        repository.CharacterCollectionRepository
	characterRepo   repository.CharacterRepository
	rdb             *redis.Client
	db              *gorm.DB
}

// NewUserUsecase 는 UserUsecase 인터페이스의 구현체를 반환합니다.
func NewUserUsecase(
	userRepo repository.UserRepository,
	mealRepo repository.MealRepository,
	dailyIntakeRepo repository.DailyIntakeRepository,
	badgeRepo repository.BadgeRepository,
	charRepo repository.CharacterCollectionRepository,
	characterRepo repository.CharacterRepository,
	rdb *redis.Client,
	db *gorm.DB,
) UserUsecase {
	return &userUsecase{
		userRepo:        userRepo,
		mealRepo:        mealRepo,
		dailyIntakeRepo: dailyIntakeRepo,
		badgeRepo:       badgeRepo,
		charRepo:        charRepo,
		characterRepo:   characterRepo,
		rdb:             rdb,
		db:              db,
	}
}

func (u *userUsecase) GetProfile(id int64) (*domain.User, error) {
	ctx := context.Background()
	cacheKey := fmt.Sprintf("user:profile:%d", id)

	// 1. 캐시 확인
	if val, err := u.rdb.Get(ctx, cacheKey).Result(); err == nil {
		var user domain.User
		if err := json.Unmarshal([]byte(val), &user); err == nil {
			return &user, nil
		}
	}

	// 2. DB 조회
	user, err := u.userRepo.GetByID(id)
	if err != nil {
		return nil, err
	}
	user.Password = ""

	// 3. Redis 저장 (TTL 5분)
	if data, err := json.Marshal(user); err == nil {
		u.rdb.Set(ctx, cacheKey, data, 5*time.Minute)
	}

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
		StreakDays: streakDays,
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

	if err := u.userRepo.Update(user); err != nil {
		return err
	}

	// 캐시 삭제
	u.rdb.Del(context.Background(), fmt.Sprintf("user:profile:%d", id))
	return nil
}

func (u *userUsecase) UpdateBody(id int64, height, weight float64, activityLevel domain.ActivityLevel) error {
	newBody := &domain.UserBody{
		UserID:        id,
		Height:        height,
		Weight:        weight,
		ActivityLevel: activityLevel,
	}

	if err := u.userRepo.CreateBody(newBody); err != nil {
		return err
	}

	nutritionGoal, err := u.userRepo.GetNutritionGoal(id)
	if err == nil && nutritionGoal != nil {
		u.calculateNutritionTargets(newBody, nutritionGoal)
		return u.userRepo.CreateOrUpdateNutritionGoal(nutritionGoal)
	}

	// 정보 변경 시 프로필 캐시 삭제 (isOnboarded 등 상태 변경 가능성)
	u.rdb.Del(context.Background(), fmt.Sprintf("user:profile:%d", id))
	return nil
}

func (u *userUsecase) UpdateNutritionGoal(id int64, goal domain.DietGoal) error {
	body, err := u.userRepo.GetLatestBody(id)
	if err != nil || body == nil {
		return errors.New("신체 정보를 먼저 등록해주세요.")
	}

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

	if err := u.userRepo.Update(user); err != nil {
		return err
	}

	u.rdb.Del(context.Background(), fmt.Sprintf("user:profile:%d", id))
	return nil
}

func (u *userUsecase) DeleteAccount(id int64) error {
	return u.userRepo.Delete(id)
}

func (u *userUsecase) ProcessPhysicalDeletion() error {
	return u.userRepo.DeletePhysicallyExpired(30)
}

func (u *userUsecase) GetCharacter(id int64) (*domain.Character, error) {
	ctx := context.Background()
	cacheKey := fmt.Sprintf("user:char:%d", id)

	// 1. 캐시 확인
	if val, err := u.rdb.Get(ctx, cacheKey).Result(); err == nil {
		var char domain.Character
		if err := json.Unmarshal([]byte(val), &char); err == nil {
			return &char, nil
		}
	}

	// 2. DB 조회
	char, err := u.characterRepo.GetByUserID(id)
	if err != nil {
		return nil, err
	}

	// 3. Redis 저장 (TTL 5분)
	if char != nil {
		if data, err := json.Marshal(char); err == nil {
			u.rdb.Set(ctx, cacheKey, data, 5*time.Minute)
		}
	}

	return char, nil
}

func (u *userUsecase) Search(query string) ([]domain.User, error) {
	return u.userRepo.Search(query)
}

func (u *userUsecase) GetRecommendations(id int64) ([]domain.User, error) {
	return u.userRepo.GetRecommendations(id, 10)
}

func (u *userUsecase) Onboarding(id int64, mukzziName string, height, weight float64, activityLevel domain.ActivityLevel, goal domain.DietGoal, bodyType, muscle, skinTone, expression int) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		// 1. 신체 정보 생성 또는 업데이트
		body := &domain.UserBody{UserID: id}
		if err := tx.Where(domain.UserBody{UserID: id}).
			Assign(domain.UserBody{
				Height:        height,
				Weight:        weight,
				ActivityLevel: activityLevel,
			}).
			FirstOrCreate(body).Error; err != nil {
			return err
		}

		// 2. 영양 목표 계산 및 생성/업데이트
		nutritionGoal := &domain.UserNutritionGoal{UserID: id}
		u.calculateNutritionTargets(body, nutritionGoal)
		if err := tx.Where(domain.UserNutritionGoal{UserID: id}).
			Assign(domain.UserNutritionGoal{
				Goal:               goal,
				DailyKcalTarget:    nutritionGoal.DailyKcalTarget,
				DailyCarbsTarget:   nutritionGoal.DailyCarbsTarget,
				DailyProteinTarget: nutritionGoal.DailyProteinTarget,
				DailyFatTarget:     nutritionGoal.DailyFatTarget,
			}).
			FirstOrCreate(nutritionGoal).Error; err != nil {
			return err
		}

		// 3. 캐릭터 생성
		character := &domain.Character{UserID: id}
		if err := tx.Where(domain.Character{UserID: id}).
			Assign(domain.Character{
				Name:           mukzziName,
				Level:          1,
				Exp:            0,
				EvolutionStage: domain.EvolutionEgg,
				BodyType:       bodyType,
				Muscle:         muscle,
				SkinTone:       skinTone,
				Expression:     expression,
				PenaltyStatus:  domain.PenaltyNormal,
			}).
			FirstOrCreate(character).Error; err != nil {
			return err
		}

		// 4. 캐릭터 도감 등록
		charCol := &domain.CharacterCollection{
			UserID:     id,
			BodyType:   bodyType,
			Muscle:     muscle,
			SkinTone:   skinTone,
			Expression: expression,
		}
		if err := tx.Where(charCol).
			Assign(domain.CharacterCollection{
				AchievedAt: time.Now(),
			}).
			FirstOrCreate(charCol).Error; err != nil {
			return err
		}

		// 온보딩 완료 시 관련 캐시 무효화
		u.rdb.Del(context.Background(), fmt.Sprintf("user:char:%d", id))
		u.rdb.Del(context.Background(), fmt.Sprintf("user:profile:%d", id))

		return nil
	})
}

const RankingWeeklyKey = "ranking:exp:weekly"

func (u *userUsecase) AddExp(userID int64, amount int) error {
	ctx := context.Background()

	// 1. DB 업데이트
	err := u.db.Transaction(func(tx *gorm.DB) error {
		var char domain.Character
		if err := tx.Where("user_id = ?", userID).First(&char).Error; err != nil {
			return err
		}

		char.Exp += amount
		if char.Exp >= 100 {
			char.Level += char.Exp / 100
			char.Exp = char.Exp % 100
		}

		if err := tx.Save(&char).Error; err != nil {
			return err
		}
		return nil
	})

	if err != nil {
		return err
	}

	// 2. Redis 랭킹 업데이트 (ZSET)
	_ = u.rdb.ZIncrBy(ctx, RankingWeeklyKey, float64(amount), fmt.Sprintf("%d", userID)).Err()

	// 캐시 삭제
	u.rdb.Del(ctx, fmt.Sprintf("user:char:%d", userID))

	return nil
}

func (u *userUsecase) SyncRankingToRedis(ctx context.Context) error {
	var chars []domain.Character
	if err := u.db.Find(&chars).Error; err != nil {
		return err
	}

	u.rdb.Del(ctx, RankingWeeklyKey)

	for _, char := range chars {
		// 초기 스코어는 레벨 * 100 + 경험치로 산정
		score := float64(char.Level*100 + char.Exp)
		if score > 0 {
			_ = u.rdb.ZAdd(ctx, RankingWeeklyKey, redis.Z{
				Score:  score,
				Member: fmt.Sprintf("%d", char.UserID),
			}).Err()
		}
	}
	return nil
}

// calculateNutritionTargets 는 신체 정보와 목표를 기반으로 영양 목표를 계산합니다.
func (u *userUsecase) calculateNutritionTargets(body *domain.UserBody, goal *domain.UserNutritionGoal) {
	if body == nil || goal == nil {
		return
	}

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
