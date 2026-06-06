package usecase

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"strconv"
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

var (
	ErrInvalidID             = errors.New("유효하지 않은 ID입니다")
	ErrInvalidSlot           = errors.New("유효하지 않은 장비 슬롯입니다")
	ErrRewardNotOwned        = errors.New("소유하지 않았거나 올바르지 않은 타입의 아이템입니다")
	ErrRewardNotEquippable   = errors.New("장착할 수 없는 보상입니다")
	ErrEquipmentSlotMismatch = errors.New("요청 슬롯과 보상 슬롯이 일치하지 않습니다")
	ErrCharacterNotFound     = errors.New("캐릭터를 찾을 수 없습니다")
)

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
	AddPoint(ctx context.Context, userID int64, amount int) error
	UpdateStreakOnMeal(userID int64, recordedAt time.Time) error
	RecalculateStreak(userID int64) error
	RecalculateAllUsersStreak() error
	RunInactivityPenalty() error
	SyncRankingToRedis(ctx context.Context) error
	RecalcAppearance(userID int64, date time.Time) (*domain.AppearanceChangedEvent, error)
	RunNutritionAchievementUpdate() error
	EquipItem(userID int64, slot domain.EquipmentSlot, rewardIDStr *string) error
}

type userUsecase struct {
	userRepo        repository.UserRepository
	mealRepo        repository.MealRepository
	dailyIntakeRepo repository.DailyIntakeRepository
	badgeRepo       repository.BadgeRepository
	charRepo        repository.CharacterCollectionRepository
	characterRepo   repository.CharacterRepository
	notificationUc  NotificationUsecase
	eventBus        domain.EventBus
	rdb             *redis.Client
	db              *gorm.DB
}

func NewUserUsecase(
	userRepo repository.UserRepository,
	mealRepo repository.MealRepository,
	dailyIntakeRepo repository.DailyIntakeRepository,
	badgeRepo repository.BadgeRepository,
	charRepo repository.CharacterCollectionRepository,
	characterRepo repository.CharacterRepository,
	notificationUc NotificationUsecase,
	eventBus domain.EventBus,
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
		eventBus:        eventBus,
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

	// 캐시 삭제 (비동기)
	go u.rdb.Del(context.Background(), fmt.Sprintf("user:profile:%d", id))
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

	// 정보 변경 시 프로필 캐시 삭제 (비동기)
	go u.rdb.Del(context.Background(), fmt.Sprintf("user:profile:%d", id))
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
				Name:          mukzziName,
				BodyType:      bodyType,
				Muscle:        muscle,
				SkinTone:      skinTone,
				Expression:    expression,
				PenaltyStatus: domain.PenaltyNormal,
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

		var capReward domain.Reward
		if err := tx.Where("code = ?", "CAP_ACCESSORY").First(&capReward).Error; err == nil {
			userReward := &domain.UserReward{
				UserID:     id,
				RewardID:   capReward.ID,
				AchievedAt: time.Now(),
			}
			if err := tx.Where(domain.UserReward{
				UserID:   id,
				RewardID: capReward.ID,
			}).FirstOrCreate(userReward).Error; err != nil {
				return err
			}
		}

		// 온보딩 완료 시 관련 캐시 무효화
		u.rdb.Del(context.Background(), fmt.Sprintf("user:char:%d", id))
		u.rdb.Del(context.Background(), fmt.Sprintf("user:profile:%d", id))

		// 첫 일일 퀘스트 즉시 할당을 위한 이벤트 발행
		u.eventBus.Publish(domain.Event{
			Type:      domain.EventUserOnboarded,
			UserID:    id,
			CreatedAt: time.Now(),
		})

		return nil
	})
}

const RankingWeeklyKey = "ranking:exp:weekly"

func (u *userUsecase) AddPoint(ctx context.Context, userID int64, amount int) error {
	return u.userRepo.AddPoint(userID, amount)
}

// RecalcAppearance date 날짜의 당일 섭취량을 바탕으로 캐릭터 파츠를 재계산하고 저장한다.
func (u *userUsecase) RecalcAppearance(userID int64, date time.Time) (*domain.AppearanceChangedEvent, error) {
	dateOnly := date.UTC().Truncate(24 * time.Hour)
	intake, err := u.dailyIntakeRepo.FindByUserIDAndDate(userID, dateOnly)
	if err != nil {
		return nil, fmt.Errorf("daily intake 조회 실패: %w", err)
	}

	goal, err := u.userRepo.GetNutritionGoal(userID)
	if err != nil {
		return nil, fmt.Errorf("영양 목표 조회 실패: %w", err)
	}

	event := CalcAppearance(intake, goal)
	if event == nil {
		return nil, nil
	}

	char, err := u.characterRepo.GetByUserID(userID)
	if err != nil {
		return nil, fmt.Errorf("캐릭터 조회 실패: %w", err)
	}
	if char == nil {
		return nil, nil
	}

	if char.BodyType == event.BodyType &&
		char.Muscle == event.Muscle &&
		char.SkinTone == event.SkinTone &&
		char.Expression == event.Expression {
		event.Changed = false
		return event, nil
	}

	char.BodyType = event.BodyType
	char.Muscle = event.Muscle
	char.SkinTone = event.SkinTone
	char.Expression = event.Expression
	if err := u.characterRepo.Update(char); err != nil {
		return nil, fmt.Errorf("캐릭터 파츠 업데이트 실패: %w", err)
	}

	delCtx, cancel := context.WithTimeout(context.Background(), 200*time.Millisecond)
	defer cancel()
	u.rdb.Del(delCtx, fmt.Sprintf("user:char:%d", userID))

	return event, nil
}

// RunNutritionAchievementUpdate 전날 영양 밸런스 달성 여부를 판정하고
// 달성한 유저의 nutrition_achievement_days를 1 증가시킨다.
func (u *userUsecase) RunNutritionAchievementUpdate() error {
	kst := time.FixedZone("KST", 9*60*60)
	yesterday := time.Now().In(kst).Truncate(24*time.Hour).AddDate(0, 0, -1)

	type row struct {
		UserID int64
	}
	var users []row
	if err := u.db.Table("daily_intakes").
		Select("user_id").
		Where("date = ? AND meal_count > 0", yesterday).
		Scan(&users).Error; err != nil {
		return fmt.Errorf("daily_intakes 조회 실패: %w", err)
	}

	for _, r := range users {
		intake, err := u.dailyIntakeRepo.FindByUserIDAndDate(r.UserID, yesterday)
		if err != nil || intake == nil {
			continue
		}
		goal, err := u.userRepo.GetNutritionGoal(r.UserID)
		if err != nil || goal == nil {
			continue
		}
		if !isNutritionBalanced(intake, goal) {
			continue
		}
		if err := u.db.Model(&domain.Character{}).
			Where("user_id = ?", r.UserID).
			UpdateColumn("nutrition_achievement_days", gorm.Expr("nutrition_achievement_days + 1")).Error; err != nil {
			slog.Error("nutrition_achievement_days 갱신 실패",
				slog.Int64("user_id", r.UserID), slog.Any("error", err))
		}
	}
	return nil
}

// isNutritionBalanced C/P/F 모두 권장 범위 내에 있으면 true를 반환한다.
func isNutritionBalanced(intake *domain.DailyIntake, goal *domain.UserNutritionGoal) bool {
	goalKcal := float64(goal.DailyKcalTarget)
	if goalKcal == 0 || intake.TotalCalories < goalKcal*0.7 {
		return false
	}
	macroCal := intake.TotalCarbs*4 + intake.TotalProtein*4 + intake.TotalFat*9
	if macroCal == 0 {
		return false
	}
	carbsRatio := intake.TotalCarbs * 4 / macroCal * 100
	proteinRatio := intake.TotalProtein * 4 / macroCal * 100
	fatRatio := intake.TotalFat * 9 / macroCal * 100
	return carbsRatio >= 55 && carbsRatio <= 65 &&
		proteinRatio >= 15 && proteinRatio <= 20 &&
		fatRatio >= 20 && fatRatio <= 30
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

	// 05:00 KST 기준 "서비스 날짜" 계산
	getServiceDate := func(t time.Time) time.Time {
		return t.In(loc).Add(-5 * time.Hour).Truncate(24 * time.Hour)
	}

	today := getServiceDate(recordedAt)

	if char.LastRecordedAt != nil {
		lastDay := getServiceDate(*char.LastRecordedAt)
		yesterday := today.AddDate(0, 0, -1)

		switch {
		case lastDay.Equal(today):
			// 같은 날 이미 기록함. 패널티 상태만 복구하고 종료
			if char.PenaltyStatus == domain.PenaltyNormal {
				return nil
			}
		case lastDay.Equal(yesterday):
			char.StreakDays++
		default:
			// 연속이 끊김
			char.StreakDays = 1
		}
	} else {
		char.StreakDays = 1
	}

	char.LastRecordedAt = &recordedAt
	char.PenaltyStatus = domain.PenaltyNormal
	return u.characterRepo.Update(char)
}

func (u *userUsecase) RecalculateStreak(userID int64) error {
	// 1. 해당 유저의 모든 식사 기록 일자 조회 (05:00 기준)
	var dates []time.Time
	// internal/repository/meal.go 에 정의된 쿼리 활용 (여기서는 db 직접 사용)
	err := u.db.Raw(`
		SELECT DISTINCT DATE_TRUNC('day', recorded_at - INTERVAL '5 hours') as service_date 
		FROM meal_records 
		WHERE user_id = ? AND deleted_at IS NULL
		ORDER BY service_date DESC`, userID).Scan(&dates).Error
	if err != nil {
		return err
	}

	char, err := u.characterRepo.GetByUserID(userID)
	if err != nil || char == nil {
		return err
	}

	if len(dates) == 0 {
		char.StreakDays = 0
		return u.characterRepo.Update(char)
	}

	// 2. 연속 일수 계산
	loc, _ := time.LoadLocation("Asia/Seoul")
	if loc == nil {
		loc = time.Local
	}
	today := time.Now().In(loc).Add(-5 * time.Hour).Truncate(24 * time.Hour)
	yesterday := today.AddDate(0, 0, -1)

	streak := 0
	lastCheck := today

	// 첫 번째 기록이 오늘이거나 어제여야 스트릭이 유지됨
	firstRecordDate := dates[0].In(time.UTC).Truncate(24 * time.Hour)
	if !firstRecordDate.Equal(today) && !firstRecordDate.Equal(yesterday) {
		char.StreakDays = 0
		return u.characterRepo.Update(char)
	}

	lastCheck = firstRecordDate
	streak = 1

	for i := 1; i < len(dates); i++ {
		currentDate := dates[i].In(time.UTC).Truncate(24 * time.Hour)
		expectedDate := lastCheck.AddDate(0, 0, -1)

		if currentDate.Equal(expectedDate) {
			streak++
			lastCheck = currentDate
		} else {
			break
		}
	}

	char.StreakDays = streak
	return u.characterRepo.Update(char)
}

func (u *userUsecase) RecalculateAllUsersStreak() error {
	var userIDs []int64
	if err := u.db.Model(&domain.User{}).Pluck("id", &userIDs).Error; err != nil {
		return err
	}

	for _, id := range userIDs {
		if err := u.RecalculateStreak(id); err != nil {
			slog.Error("스트릭 재계산 실패", slog.Int64("user_id", id), slog.Any("error", err))
		}
	}
	return nil
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

	if len(chars) == 0 {
		return nil
	}

	zs := make([]redis.Z, len(chars))
	for i, char := range chars {
		zs[i] = redis.Z{
			Score:  float64(char.NutritionAchievementDays),
			Member: fmt.Sprintf("%d", char.UserID),
		}
	}

	err := u.rdb.ZAdd(ctx, RankingWeeklyKey, zs...).Err()
	if err != nil {
		slog.Error("Redis 랭킹 ZAdd 일괄 추가 실패", slog.Any("error", err))
		return err
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

// EquipItem 캐릭터 장비 슬롯 장착 및 해제 비즈니스 로직
func (u *userUsecase) EquipItem(userID int64, slot domain.EquipmentSlot, rewardIDStr *string) error {
	if !isValidEquipmentSlot(slot) {
		return ErrInvalidSlot
	}

	char, err := u.characterRepo.GetByUserID(userID)
	if err != nil {
		return err
	}
	if char == nil {
		return ErrCharacterNotFound
	}

	if rewardIDStr == nil || *rewardIDStr == "" {
		err := u.db.Transaction(func(tx *gorm.DB) error {
			if err := tx.Where("character_id = ? AND slot = ?", char.ID, slot).
				Delete(&domain.CharacterEquipment{}).Error; err != nil {
				return err
			}
			return syncLegacyEquipmentColumn(tx, char.ID, slot, nil)
		})
		if err != nil {
			return err
		}
		u.invalidateCharacterCaches(userID)
		return nil
	}

	rewardID, err := strconv.ParseInt(*rewardIDStr, 10, 64)
	if err != nil {
		return ErrInvalidID
	}

	var reward domain.Reward
	if err := u.db.First(&reward, rewardID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrInvalidID
		}
		return err
	}
	if !isEquippableReward(reward.RewardType) || reward.RenderConfig == nil {
		return ErrRewardNotEquippable
	}
	if reward.RenderConfig.Slot != slot {
		return ErrEquipmentSlotMismatch
	}

	var count int64
	if err := u.db.Table("user_rewards").
		Where("user_id = ? AND reward_id = ?", userID, rewardID).
		Count(&count).Error; err != nil {
		return err
	}
	if count == 0 {
		return ErrRewardNotOwned
	}

	err = u.db.Transaction(func(tx *gorm.DB) error {
		var existing domain.CharacterEquipment
		err = tx.Where("character_id = ? AND slot = ?", char.ID, slot).First(&existing).Error
		if errors.Is(err, gorm.ErrRecordNotFound) {
			equipment := domain.CharacterEquipment{
				CharacterID: char.ID,
				UserID:      userID,
				Slot:        slot,
				RewardID:    rewardID,
				EquippedAt:  time.Now(),
			}
			if err := tx.Create(&equipment).Error; err != nil {
				return err
			}
			return syncLegacyEquipmentColumn(tx, char.ID, slot, &rewardID)
		}
		if err != nil {
			return err
		}

		existing.RewardID = rewardID
		existing.EquippedAt = time.Now()
		if err := tx.Save(&existing).Error; err != nil {
			return err
		}
		return syncLegacyEquipmentColumn(tx, char.ID, slot, &rewardID)
	})
	if err != nil {
		return err
	}
	u.invalidateCharacterCaches(userID)
	return nil
}

func syncLegacyEquipmentColumn(tx *gorm.DB, charID int64, slot domain.EquipmentSlot, rewardID *int64) error {
	switch slot {
	case domain.EquipmentSlotHead:
		return tx.Model(&domain.Character{}).Where("id = ?", charID).
			Update("equipped_accessory_id", rewardID).Error
	case domain.EquipmentSlotBackground:
		return tx.Model(&domain.Character{}).Where("id = ?", charID).
			Update("equipped_background_id", rewardID).Error
	default:
		return nil
	}
}

func isValidEquipmentSlot(slot domain.EquipmentSlot) bool {
	switch slot {
	case domain.EquipmentSlotBackground,
		domain.EquipmentSlotBack,
		domain.EquipmentSlotBody,
		domain.EquipmentSlotHand,
		domain.EquipmentSlotFace,
		domain.EquipmentSlotHead,
		domain.EquipmentSlotAura:
		return true
	default:
		return false
	}
}

func isEquippableReward(rewardType domain.RewardType) bool {
	switch rewardType {
	case domain.RewardBackground, domain.RewardAccessory, domain.RewardEffect, domain.RewardMotion:
		return true
	default:
		return false
	}
}

func (u *userUsecase) invalidateCharacterCaches(userID int64) {
	if u.rdb == nil {
		return
	}
	ctx := context.Background()
	u.rdb.Del(ctx, fmt.Sprintf("user:profile:%d", userID))
	u.rdb.Del(ctx, fmt.Sprintf("user:char:%d", userID))
}
