package usecase

import (
	"context"
	"log"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

// MasteryTracker 마스터리 자동 갱신 인터페이스
type MasteryTracker interface {
	// OnMealCreated 식사 기록 생성 시 마스터리 eat_count를 증가시키고 grade를 갱신합니다.
	// 등급이 변경된 경우 변경 후 Mastery를 반환하며, 그렇지 않으면 nil을 반환합니다.
	OnMealCreated(ctx context.Context, userID, menuID int64) (*domain.Mastery, error)
}

type masteryTrackerImpl struct {
	masteryRepo repository.MasteryRepository
}

func NewMasteryTracker(masteryRepo repository.MasteryRepository) MasteryTracker {
	return &masteryTrackerImpl{masteryRepo: masteryRepo}
}

func (t *masteryTrackerImpl) OnMealCreated(_ context.Context, userID, menuID int64) (*domain.Mastery, error) {
	// menuID가 없는 수동 입력 식사는 마스터리 갱신 대상 아님
	if menuID == 0 {
		return nil, nil
	}

	prevGrade := domain.MasteryGrade("")

	// 기존 마스터리 조회 (등급 변경 감지용)
	existing, err := t.masteryRepo.FindByUserIDAndMenuID(userID, menuID)
	if err != nil {
		log.Printf("[MasteryTracker] FindByUserIDAndMenuID(user=%d, menu=%d) 오류: %v", userID, menuID, err)
		return nil, err
	}
	if existing != nil {
		prevGrade = existing.Grade
	}

	updated, err := t.masteryRepo.Upsert(userID, menuID, time.Now())
	if err != nil {
		log.Printf("[MasteryTracker] Upsert(user=%d, menu=%d) 오류: %v", userID, menuID, err)
		return nil, err
	}

	// 등급이 변경된 경우에만 반환 (호출자가 알림/뱃지 처리에 활용)
	if updated.Grade != prevGrade {
		log.Printf("[MasteryTracker] 마스터리 등급 변경: user=%d, menu=%d, %s -> %s",
			userID, menuID, prevGrade, updated.Grade)
		return updated, nil
	}

	return nil, nil
}
