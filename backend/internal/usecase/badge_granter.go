package usecase

import (
	"context"
	"log"
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
	check   func(ctx context.Context, g *badgeGranterImpl, userID int64) (bool, error)
}

// registeredCheckers 등록된 모든 뱃지 체커
var registeredCheckers = []badgeChecker{
	{
		code:    "FIRST_MEAL",
		trigger: EventMealCreated,
		check:   checkFirstMeal,
	},
	{
		code:    "THREE_MEALS_A_DAY",
		trigger: EventMealCreated,
		check:   checkThreeMealsADay,
	},
	{
		code:    "STREAK_7",
		trigger: EventMealCreated,
		check: func(ctx context.Context, g *badgeGranterImpl, userID int64) (bool, error) {
			return g.checkStreak(userID, 7)
		},
	},
	{
		code:    "STREAK_30",
		trigger: EventMealCreated,
		check: func(ctx context.Context, g *badgeGranterImpl, userID int64) (bool, error) {
			return g.checkStreak(userID, 30)
		},
	},
	{
		code:    "MENU_EXPLORER",
		trigger: EventMealCreated,
		check:   checkMenuExplorer,
	},
	{
		code:    "BALANCE_MASTER",
		trigger: EventAppearanceRecalculated,
		check:   checkBalanceMaster,
	},
	{
		code:    "COLLECTION_50",
		trigger: EventAppearanceRecalculated,
		check: func(ctx context.Context, g *badgeGranterImpl, userID int64) (bool, error) {
			return g.checkCollectionCount(userID, 50)
		},
	},
	{
		code:    "COLLECTION_ALL",
		trigger: EventAppearanceRecalculated,
		check: func(ctx context.Context, g *badgeGranterImpl, userID int64) (bool, error) {
			return g.checkCollectionCount(userID, totalAppearanceCombinations)
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
			log.Printf("[BadgeGranter] FindBadgeByCode(%s) 오류: %v", checker.code, err)
			continue
		}
		if badge == nil {
			// 시드 데이터에 뱃지가 없으면 스킵
			continue
		}

		// 이미 보유한 뱃지면 스킵
		existing, err := g.badgeRepo.FindUserBadgeByID(userID, badge.ID)
		if err != nil {
			log.Printf("[BadgeGranter] FindUserBadgeByID(user=%d, badge=%s) 오류: %v", userID, checker.code, err)
			continue
		}
		if existing != nil {
			continue
		}

		// 조건 체크
		ok, err := checker.check(ctx, g, userID)
		if err != nil {
			log.Printf("[BadgeGranter] 조건 체크(%s, user=%d) 오류: %v", checker.code, userID, err)
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
			log.Printf("[BadgeGranter] CreateUserBadge(%s, user=%d) 오류: %v", checker.code, userID, err)
			continue
		}

		granted = append(granted, *badge)
		log.Printf("[BadgeGranter] 뱃지 부여: code=%s, userID=%d", checker.code, userID)
	}

	return granted, nil
}

// --- 개별 체커 함수 ---

// checkFirstMeal 첫 식사 기록 뱃지
func checkFirstMeal(_ context.Context, g *badgeGranterImpl, userID int64) (bool, error) {
	count, err := g.mealRepo.CountByUserID(userID)
	if err != nil {
		return false, err
	}
	return count == 1, nil
}

// checkThreeMealsADay 하루 3끼 완료 뱃지
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

// checkMenuExplorer 서로 다른 메뉴 50종 기록 뱃지
func checkMenuExplorer(_ context.Context, g *badgeGranterImpl, userID int64) (bool, error) {
	count, err := g.mealRepo.CountDistinctMenuByUserID(userID)
	if err != nil {
		return false, err
	}
	return count >= 50, nil
}

// checkBalanceMaster 영양 밸런스 7일 연속 달성 뱃지
// daily_intakes.is_balanced 는 AppearanceRecalculate Cron(05:10)에서 설정됩니다.
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

// checkStreak N일 연속 기록 뱃지 (STREAK_7, STREAK_30 공용)
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

// checkCollectionCount 먹찌 도감 N종 달성 뱃지 (COLLECTION_50, COLLECTION_ALL 공용)
func (g *badgeGranterImpl) checkCollectionCount(userID int64, target int64) (bool, error) {
	count, err := g.collectionRepo.CountByUserID(userID)
	if err != nil {
		return false, err
	}
	return count >= target, nil
}

// mealDate KST 05:00 기준으로 식사 날짜를 반환합니다.
func mealDate(t time.Time) time.Time {
	kst := time.FixedZone("KST", 9*60*60)
	now := t.In(kst)
	if now.Hour() < 5 {
		now = now.AddDate(0, 0, -1)
	}
	return time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
}
