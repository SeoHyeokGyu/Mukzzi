package usecase

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"gorm.io/gorm"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

type QuestUsecase interface {
	GetMyQuests(ctx context.Context, userID int64, period string) ([]domain.UserQuest, error)
	HandleEvent(ctx context.Context, event domain.Event) ([]domain.QuestProgress, error)
	ClaimReward(ctx context.Context, userID int64, userQuestID int64) error
	AssignDailyQuests(ctx context.Context, userID int64) error
	AssignAllUsersDailyQuests(ctx context.Context) error
}

type questUsecase struct {
	questRepo     domain.QuestRepository
	userRepo      repository.UserRepository
	characterRepo repository.CharacterRepository // 경험치 지급용
	eventBus      domain.EventBus
	db            *gorm.DB // 트랜잭션용
}

func NewQuestUsecase(
	questRepo domain.QuestRepository,
	userRepo repository.UserRepository,
	characterRepo repository.CharacterRepository,
	eventBus domain.EventBus,
	db *gorm.DB,
) QuestUsecase {
	return &questUsecase{
		questRepo:     questRepo,
		userRepo:      userRepo,
		characterRepo: characterRepo,
		eventBus:      eventBus,
		db:            db,
	}
}

func (u *questUsecase) GetMyQuests(ctx context.Context, userID int64, period string) ([]domain.UserQuest, error) {
	quests, err := u.questRepo.GetActiveQuestsByUserID(ctx, userID)
	if err != nil {
		return nil, err
	}

	if period == "" {
		return quests, nil
	}

	var filtered []domain.UserQuest
	for _, q := range quests {
		if string(q.Quest.Type) == period {
			filtered = append(filtered, q)
		}
	}
	return filtered, nil
}

func (u *questUsecase) HandleEvent(ctx context.Context, event domain.Event) ([]domain.QuestProgress, error) {
	// 1. 유저의 진행 중인 퀘스트 조회
	userQuests, err := u.questRepo.GetActiveQuestsByUserID(ctx, event.UserID)
	if err != nil {
		return nil, err
	}

	var progressed []domain.QuestProgress

	// 2. 이벤트 유형에 따른 퀘스트 필터링 및 업데이트
	for i := range userQuests {
		uq := &userQuests[i]
		if uq.Status != domain.QuestStatusProgress {
			continue
		}

		shouldUpdate := false
		switch event.Type {
		case domain.EventMealCreated:
			if uq.Quest.Category == domain.QuestCategoryMeal {
				uq.CurrentCount++
				shouldUpdate = true
			}
		case domain.EventFriendNudged:
			if uq.Quest.Category == domain.QuestCategorySocial && uq.Quest.Code == "NUDGE_FRIEND" {
				uq.CurrentCount++
				shouldUpdate = true
			}
		case domain.EventGuestbookPosted:
			if uq.Quest.Category == domain.QuestCategorySocial && uq.Quest.Code == "WRITE_GUESTBOOK" {
				uq.CurrentCount++
				shouldUpdate = true
			}
		}

		if shouldUpdate {
			// 완료 여부 판정
			if uq.CurrentCount >= uq.Quest.TargetCount {
				uq.Status = domain.QuestStatusCompleted
			}

			if err := u.questRepo.UpdateUserQuest(ctx, uq); err != nil {
				slog.Error("퀘스트 업데이트 실패", slog.Any("error", err))
				continue
			}

			progressed = append(progressed, domain.QuestProgress{
				QuestType: string(uq.Quest.Type),
				Progress:  uq.CurrentCount,
				Target:    uq.Quest.TargetCount,
				Completed: uq.Status == domain.QuestStatusCompleted,
			})
		}
	}

	return progressed, nil
}

func (u *questUsecase) ClaimReward(ctx context.Context, userID int64, userQuestID int64) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		// 1. 퀘스트 조회
		uq, err := u.questRepo.GetUserQuestByID(ctx, userQuestID)
		if err != nil {
			return err
		}

		if uq.UserID != userID {
			return fmt.Errorf("권한이 없습니다")
		}

		if uq.Status != domain.QuestStatusCompleted {
			return fmt.Errorf("이미 수령했거나 완료되지 않은 퀘스트입니다")
		}

		// 2. 보상 지급
		// 포인트 지급
		if uq.Quest.RewardPoint > 0 {
			if err := u.userRepo.AddPoint(userID, uq.Quest.RewardPoint); err != nil {
				return err
			}
		}

		// 경험치 지급
		if uq.Quest.RewardExp > 0 {
			char, err := u.characterRepo.GetByUserID(userID)
			if err != nil {
				return err
			}
			if char != nil {
				char.Exp += uq.Quest.RewardExp
				// 레벨업 공식: 레벨 N의 필요 EXP = 100 × N (선형 증가)
				for char.Exp >= char.Level*100 {
					char.Exp -= char.Level * 100
					char.Level++
				}
				if err := u.characterRepo.Update(char); err != nil {
					return err
				}
			}
		}

		// 3. 상태 변경
		uq.Status = domain.QuestStatusClaimed
		return u.questRepo.UpdateUserQuest(ctx, uq)
	})
}

func (u *questUsecase) AssignDailyQuests(ctx context.Context, userID int64) error {
	// 1. 기존 일일 퀘스트 삭제
	if err := u.questRepo.DeleteDailyQuestsByUserID(ctx, userID); err != nil {
		return err
	}

	// 2. 랜덤 퀘스트 3개 조회
	pool, err := u.questRepo.GetAvailableDailyQuests(ctx, 3)
	if err != nil {
		return err
	}

	now := time.Now()
	// 다음날 새벽 5시 계산
	expiresAt := time.Date(now.Year(), now.Month(), now.Day(), 5, 0, 0, 0, now.Location())
	if now.Hour() >= 5 {
		expiresAt = expiresAt.AddDate(0, 0, 1)
	}

	// 3. 부여
	for _, q := range pool {
		uq := domain.UserQuest{
			UserID:     userID,
			QuestID:    q.ID,
			Status:     domain.QuestStatusProgress,
			AssignedAt: now,
			ExpiresAt:  expiresAt,
		}
		if err := u.questRepo.CreateUserQuest(ctx, &uq); err != nil {
			return err
		}
	}

	return nil
}

func (u *questUsecase) AssignAllUsersDailyQuests(ctx context.Context) error {
	slog.Info("모든 유저에게 일일 퀘스트 할당 시작")
	// 1. 모든 유저 조회
	var userIDs []int64
	if err := u.db.Model(&domain.User{}).Pluck("id", &userIDs).Error; err != nil {
		return err
	}

	// 2. 유저별 할당
	for _, userID := range userIDs {
		if err := u.AssignDailyQuests(ctx, userID); err != nil {
			slog.Error("유저 일일 퀘스트 할당 실패", slog.Int64("user_id", userID), slog.Any("error", err))
		}
	}

	slog.Info("모든 유저에게 일일 퀘스트 할당 완료", slog.Int("count", len(userIDs)))
	return nil
}
