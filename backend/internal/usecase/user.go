package usecase

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
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
	AddExp(userID int64, amount int) (*AddExpResult, error)
	AddPoint(ctx context.Context, userID int64, amount int) error
	UpdateStreakOnMeal(userID int64, recordedAt time.Time) error
	RunInactivityPenalty() error
	SyncRankingToRedis(ctx context.Context) error
}

type userUsecase struct {
	userRepo        repository.UserRepository
	mealRepo        repository.MealRepository
	dailyIntakeRepo repository.DailyIntakeRepository
	badgeRepo       repository.BadgeRepository
	charRepo        repository.CharacterCollectionRepository
	characterRepo   repository.CharacterRepository
	notificationUc  NotificationUsecase
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
	notificationUc NotificationUsecase,
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
		notificationUc:  notificationUc,
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

type AddExpResult struct {
	LeveledUp bool
	OldLevel  int
	NewLevel  int
}

func (u *userUsecase) AddExp(userID int64, amount int) (*AddExpResult, error) {
	ctx := context.Background()
	result := &AddExpResult{}

	err := u.db.Transaction(func(tx *gorm.DB) error {
		var char domain.Character
		if err := tx.Where("user_id = ?", userID).First(&char).Error; err != nil {
			return err
		}

		result.OldLevel = char.Level
		char.Exp += amount
		// 레벨업 공식: 레벨 N의 필요 EXP = 100 × N (선형 증가)
		for char.Exp >= char.Level*100 {
			char.Exp -= char.Level * 100
			char.Level++
		}

		if char.Level > result.OldLevel {
			result.LeveledUp = true
			result.NewLevel = char.Level
		} else {
			result.NewLevel = char.Level
		}

		return tx.Save(&char).Error
	})
	if err != nil {
		return nil, err
	}

	_ = u.rdb.ZIncrBy(ctx, RankingWeeklyKey, float64(amount), fmt.Sprintf("%d", userID)).Err()
	u.rdb.Del(ctx, fmt.Sprintf("user:char:%d", userID))

	return result, nil
}

func (u *userUsecase) AddPoint(ctx context.Context, userID int64, amount int) error {
	return u.userRepo.AddPoint(userID, amount)
}

func (u *userUsecase) UpdateStreakOnMeal(userID int64, recordedAt time.Time) error {
	char, err := u.characterRepo.GetByUserID(userID)
	if err != nil || char == nil {
		return err
	}

	loc, _ := time.LoadLocation("Asia/Seoul")
	if loc == nil {
		loc = time.Local
	}
	today := recordedAt.In(loc).Truncate(24 * time.Hour)

	if char.LastRecordedAt != nil {
		lastDay := char.LastRecordedAt.In(loc).Truncate(24 * time.Hour)
		yesterday := today.AddDate(0, 0, -1)

		switch {
		case lastDay.Equal(today):
			if char.PenaltyStatus == domain.PenaltyNormal {
				return nil
			}
		case lastDay.Equal(yesterday):
			char.StreakDays++
		default:
			char.StreakDays = 1
		}
	} else {
		char.StreakDays = 1
	}

	char.LastRecordedAt = &recordedAt
	char.PenaltyStatus = domain.PenaltyNormal
	return u.characterRepo.Update(char)
}

func (u *userUsecase) RunInactivityPenalty() error {
	var chars []domain.Character
	if err := u.db.Find(&chars).Error; err != nil {
		return err
	}

	now := time.Now()
	for i := range chars {
		char := &chars[i]
		if char.LastRecordedAt == nil {
			continue
		}

		days := int(now.Sub(*char.LastRecordedAt).Hours() / 24)
		newStatus := penaltyFromDays(days)
		if char.PenaltyStatus == newStatus {
			continue
		}

		char.PenaltyStatus = newStatus
		if err := u.characterRepo.Update(char); err != nil {
			slog.Error("패널티 상태 업데이트 실패", slog.Int64("user_id", char.UserID), slog.Any("error", err))
			continue
		}

		if u.notificationUc != nil {
			_ = u.notificationUc.CreateNotification(&domain.Notification{
				UserID:  char.UserID,
				Type:    domain.NotificationTypePenaltyChanged,
				Title:   penaltyTitle(newStatus),
				Content: penaltyContent(newStatus),
			})
		}
	}
	return nil
}

func penaltyFromDays(days int) domain.PenaltyStatus {
	switch {
	case days >= 5:
		return domain.PenaltyWeakened
	case days >= 3:
		return domain.PenaltyStarving
	case days >= 2:
		return domain.PenaltyHungry
	default:
		return domain.PenaltyNormal
	}
}

func penaltyTitle(status domain.PenaltyStatus) string {
	switch status {
	case domain.PenaltyHungry:
		return "먹찌가 배고파요!"
	case domain.PenaltyStarving:
		return "먹찌가 굶주리고 있어요!"
	case domain.PenaltyWeakened:
		return "먹찌가 약해지고 있어요!"
	default:
		return ""
	}
}

func penaltyContent(status domain.PenaltyStatus) string {
	switch status {
	case domain.PenaltyHungry:
		return "2일째 식사 기록이 없어요. 오늘 식사를 기록해보세요!"
	case domain.PenaltyStarving:
		return "3일째 식사 기록이 없어요. 빨리 식사를 기록해주세요!"
	case domain.PenaltyWeakened:
		return "5일 이상 식사 기록이 없어요. 먹찌가 약해지고 있습니다!"
	default:
		return ""
	}
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
