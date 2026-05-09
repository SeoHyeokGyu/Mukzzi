package usecase

import (
	"context"
	"log/slog"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

// BadgeGrantEvent 뱃지 체크를 트리거하는 이벤트
type BadgeGrantEvent string

const (
	// EventMealCreated 식사 기록 생성 시 트리거
	EventMealCreated BadgeGrantEvent = "MEAL_CREATED"

	// EventAppearanceRecalculated 캐릭터 외형 재계산(Cron 05:10) 시 트리거
	EventAppearanceRecalculated BadgeGrantEvent = "APPEARANCE_RECALCULATED"
)

// 먹찌 외형 전체 조합 수: 체형(5) x 근육(5) x 피부색(5) x 표정(5)
const totalAppearanceCombinations = 625

// BadgeGranter 뱃지 자동 부여 인터페이스
type BadgeGranter interface {
	// CheckAndGrant 이벤트에 해당하는 뱃지 조건을 확인하고 미획득 뱃지를 부여합니다.
	// 새로 부여된 뱃지 목록을 반환합니다.
	CheckAndGrant(ctx context.Context, userID int64, event BadgeGrantEvent) ([]domain.Badge, error)
	
	// GetProgress 특정 뱃지의 현재 진행도와 목표치를 반환합니다.
	GetProgress(ctx context.Context, userID int64, code string) (int, int, error)
}

type badgeGranterImpl struct {
	badgeRepo      repository.BadgeRepository
	mealRepo       repository.MealRepository
	dailyRepo      repository.DailyIntakeRepository
	collectionRepo repository.CharacterCollectionRepository
}

func NewBadgeGranter(
	badgeRepo repository.BadgeRepository,
	mealRepo repository.MealRepository,
	dailyRepo repository.DailyIntakeRepository,
	collectionRepo repository.CharacterCollectionRepository,
) BadgeGranter {
	return &badgeGranterImpl{
		badgeRepo:      badgeRepo,
		mealRepo:       mealRepo,
		dailyRepo:      dailyRepo,
		collectionRepo: collectionRepo,
	}
}

// badgeChecker 개별 뱃지 체커 정의
type badgeChecker struct {
	code    string
	trigger BadgeGrantEvent
	target  int
	check   func(ctx context.Context, g *badgeGranterImpl, userID int64) (bool, error)
	progress func(ctx context.Context, g *badgeGranterImpl, userID int64) (int, error)
}

// registeredCheckers 등록된 모든 뱃지 체커
var registeredCheckers = []badgeChecker{
	{
		code:    "FIRST_MEAL",
		trigger: EventMealCreated,
		target:  1,
		check:   checkFirstMeal,
		progress: func(ctx context.Context, g *badgeGranterImpl, userID int64) (int, error) {
			count, err := g.mealRepo.CountByUserID(userID)
			return int(count), err
		},
	},
	{
		code:    "THREE_MEALS_A_DAY",
		trigger: EventMealCreated,
		target:  3,
		check:   checkThreeMealsADay,
		progress: func(ctx context.Context, g *badgeGranterImpl, userID int64) (int, error) {
			today := mealDate(time.Now())
			intake, err := g.dailyRepo.FindByUserIDAndDate(userID, today)
			if err != nil || intake == nil { return 0, err }
			return intake.MealCount, nil
		},
	},
	{
		code:    "STREAK_7",
		trigger: EventMealCreated,
		target:  7,
		check: func(ctx context.Context, g *badgeGranterImpl, userID int64) (bool, error) {
			return g.checkStreak(userID, 7)
		},
		progress: func(ctx context.Context, g *badgeGranterImpl, userID int64) (int, error) {
			return g.getCurrentStreak(userID), nil
		},
	},
	{
		code:    "STREAK_30",
		trigger: EventMealCreated,
		target:  30,
		check: func(ctx context.Context, g *badgeGranterImpl, userID int64) (bool, error) {
			return g.checkStreak(userID, 30)
		},
		progress: func(ctx context.Context, g *badgeGranterImpl, userID int64) (int, error) {
			return g.getCurrentStreak(userID), nil
		},
	},
	{
		code:    "MENU_EXPLORER",
		trigger: EventMealCreated,
		target:  50,
		check:   checkMenuExplorer,
		progress: func(ctx context.Context, g *badgeGranterImpl, userID int64) (int, error) {
			count, err := g.mealRepo.CountDistinctMenuByUserID(userID)
			return int(count), err
		},
	},
	{
		code:    "BALANCE_MASTER",
		trigger: EventAppearanceRecalculated,
		target:  7,
		check:   checkBalanceMaster,
		progress: func(ctx context.Context, g *badgeGranterImpl, userID int64) (int, error) {
			// 현재 영양 밸런스 연속 일수 계산 (간략화)
			return 0, nil 
		},
	},
	{
		code:    "COLLECTION_50",
		trigger: EventAppearanceRecalculated,
		target:  50,
		check: func(ctx context.Context, g *badgeGranterImpl, userID int64) (bool, error) {
			return g.checkCollectionCount(userID, 50)
		},
		progress: func(ctx context.Context, g *badgeGranterImpl, userID int64) (int, error) {
			count, err := g.collectionRepo.CountByUserID(userID)
			return int(count), err
		},
	},
	{
		code:    "COLLECTION_ALL",
		trigger: EventAppearanceRecalculated,
		target:  totalAppearanceCombinations,
		check: func(ctx context.Context, g *badgeGranterImpl, userID int64) (bool, error) {
			return g.checkCollectionCount(userID, totalAppearanceCombinations)
		},
		progress: func(ctx context.Context, g *badgeGranterImpl, userID int64) (int, error) {
			count, err := g.collectionRepo.CountByUserID(userID)
			return int(count), err
		},
	},
	{
		code:    "ACHIEVE_MEAL_100",
		trigger: EventMealCreated,
		target:  100,
		check: func(ctx context.Context, g *badgeGranterImpl, userID int64) (bool, error) {
			count, err := g.mealRepo.CountByUserID(userID)
			return count >= 100, err
		},
		progress: func(ctx context.Context, g *badgeGranterImpl, userID int64) (int, error) {
			count, err := g.mealRepo.CountByUserID(userID)
			return int(count), err
		},
	},
}

// CheckAndGrant 이벤트에 해당하는 뱃지를 체크하고 부여합니다.
func (g *badgeGranterImpl) CheckAndGrant(ctx context.Context, userID int64, event BadgeGrantEvent) ([]domain.Badge, error) {
	var granted []domain.Badge

	for _, checker := range registeredCheckers {
		if checker.trigger != event {
			continue
		}

		badge, err := g.badgeRepo.FindBadgeByCode(checker.code)
		if err != nil {
			slog.Error("뱃지 정보 조회 실패", slog.String("code", checker.code), slog.Any("error", err))
			continue
		}
		if badge == nil {
			continue
		}

		// 이미 보유한 뱃지면 스킵
		existing, err := g.badgeRepo.FindUserBadgeByID(userID, badge.ID)
		if err != nil {
			slog.Error("사용자 뱃지 보유 여부 확인 실패", slog.Int64("user_id", userID), slog.String("code", checker.code), slog.Any("error", err))
			continue
		}
		if existing != nil {
			continue
		}

		// 조건 체크
		ok, err := checker.check(ctx, g, userID)
		if err != nil {
			slog.Error("뱃지 조건 체크 실패", slog.String("code", checker.code), slog.Int64("user_id", userID), slog.Any("error", err))
			continue
		}
		if !ok {
			continue
		}

		// 뱃지 부여
		userBadge := &domain.UserBadge{
			UserID:     userID,
			BadgeID:    badge.ID,
			AcquiredAt: time.Now(),
		}
		if err := g.badgeRepo.CreateUserBadge(userBadge); err != nil {
			slog.Error("사용자 뱃지 부여 실패", slog.String("code", checker.code), slog.Int64("user_id", userID), slog.Any("error", err))
			continue
		}

		granted = append(granted, *badge)
		slog.Info("뱃지 부여 완료", slog.String("code", checker.code), slog.Int64("user_id", userID))
	}

	return granted, nil
}

func (g *badgeGranterImpl) GetProgress(ctx context.Context, userID int64, code string) (int, int, error) {
	for _, checker := range registeredCheckers {
		if checker.code == code {
			progress := 0
			var err error
			if checker.progress != nil {
				progress, err = checker.progress(ctx, g, userID)
				if err != nil {
					return 0, checker.target, err
				}
			}
			return progress, checker.target, nil
		}
	}
	return 0, 0, nil
}

// --- 개별 체커 함수 ---

func checkFirstMeal(_ context.Context, g *badgeGranterImpl, userID int64) (bool, error) {
	count, err := g.mealRepo.CountByUserID(userID)
	if err != nil {
		return false, err
	}
	return count >= 1, nil
}

func checkThreeMealsADay(_ context.Context, g *badgeGranterImpl, userID int64) (bool, error) {
	today := mealDate(time.Now())
	intake, err := g.dailyRepo.FindByUserIDAndDate(userID, today)
	if err != nil {
		return false, err
	}
	if intake == nil {
		return false, nil
	}
	return intake.MealCount >= 3, nil
}

func checkMenuExplorer(_ context.Context, g *badgeGranterImpl, userID int64) (bool, error) {
	count, err := g.mealRepo.CountDistinctMenuByUserID(userID)
	if err != nil {
		return false, err
	}
	return count >= 50, nil
}

func checkBalanceMaster(_ context.Context, g *badgeGranterImpl, userID int64) (bool, error) {
	intakes, err := g.dailyRepo.FindRecentByUserID(userID, 7)
	if err != nil {
		return false, err
	}
	if len(intakes) < 7 {
		return false, nil
	}

	today := mealDate(time.Now())
	for i, di := range intakes {
		expected := today.AddDate(0, 0, -i)
		diDate := time.Date(di.Date.Year(), di.Date.Month(), di.Date.Day(), 0, 0, 0, 0, time.UTC)
		if !diDate.Equal(expected) || !di.IsBalanced {
			return false, nil
		}
	}
	return true, nil
}

func (g *badgeGranterImpl) getCurrentStreak(userID int64) int {
	// 실제 뱃지용 스트릭 로직 (간략화)
	return 0 
}

func (g *badgeGranterImpl) checkStreak(userID int64, days int) (bool, error) {
	intakes, err := g.dailyRepo.FindRecentByUserID(userID, days)
	if err != nil {
		return false, err
	}
	if len(intakes) < days {
		return false, nil
	}

	today := mealDate(time.Now())
	for i, di := range intakes {
		expected := today.AddDate(0, 0, -i)
		diDate := time.Date(di.Date.Year(), di.Date.Month(), di.Date.Day(), 0, 0, 0, 0, time.UTC)
		if !diDate.Equal(expected) || di.MealCount == 0 {
			return false, nil
		}
	}
	return true, nil
}

func (g *badgeGranterImpl) checkCollectionCount(userID int64, target int64) (bool, error) {
	count, err := g.collectionRepo.CountByUserID(userID)
	if err != nil {
		return false, err
	}
	return count >= target, nil
}

func mealDate(t time.Time) time.Time {
	kst := time.FixedZone("KST", 9*60*60)
	now := t.In(kst)
	if now.Hour() < 5 {
		now = now.AddDate(0, 0, -1)
	}
	return time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
}
