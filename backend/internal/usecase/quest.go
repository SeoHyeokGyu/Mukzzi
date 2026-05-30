package usecase

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

type QuestUsecase interface {
	GetMyQuests(ctx context.Context, userID int64, period string) ([]domain.UserQuest, error)
	HandleEvent(ctx context.Context, event domain.Event) ([]domain.QuestProgress, error)
	ClaimReward(ctx context.Context, userID int64, userQuestID int64) error
	AssignDailyQuests(ctx context.Context, userID int64) error
	AssignWeeklyQuests(ctx context.Context, userID int64) error
	AssignAchievementQuests(ctx context.Context, userID int64) error
	AssignTutorialQuest(ctx context.Context, userID int64) error
	AssignAllUsersDailyQuests(ctx context.Context) error
	AssignAllUsersWeeklyQuests(ctx context.Context) error
	ProcessExpiredQuests(ctx context.Context) error
}

type questUsecase struct {
	questRepo     domain.QuestRepository
	userRepo      repository.UserRepository
	characterRepo repository.CharacterRepository // 경험치 지급용
	mealRepo      repository.MealRepository      // 주간 퀘스트 체크용
	badgeRepo     repository.BadgeRepository     // 뱃지 지급용
	titleRepo     repository.TitleRepository     // 칭호 지급용
	eventBus      domain.EventBus
	db            *gorm.DB // 트랜잭션용
}

func NewQuestUsecase(
	questRepo domain.QuestRepository,
	userRepo repository.UserRepository,
	characterRepo repository.CharacterRepository,
	mealRepo repository.MealRepository,
	badgeRepo repository.BadgeRepository,
	titleRepo repository.TitleRepository,
	eventBus domain.EventBus,
	db *gorm.DB,
) QuestUsecase {
	return &questUsecase{
		questRepo:     questRepo,
		userRepo:      userRepo,
		characterRepo: characterRepo,
		mealRepo:      mealRepo,
		badgeRepo:     badgeRepo,
		titleRepo:     titleRepo,
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

	filtered := []domain.UserQuest{}
	for _, q := range quests {
		if q.Quest != nil && string(q.Quest.Type) == period {
			filtered = append(filtered, q)
		}
	}
	return filtered, nil
}

func (u *questUsecase) HandleEvent(ctx context.Context, event domain.Event) ([]domain.QuestProgress, error) {
	var progressed []domain.QuestProgress

	// 1. 유저 단위 비관적 잠금 (Pessimistic Locking)
	// 동일 유저가 짧은 간격으로 식사를 기록하거나 여러 이벤트가 발생할 때, 
	// 퀘스트 진행도가 중복으로 올라가거나 덮어씌워지는 데이터 경합(Race Condition)을 방지합니다.
	err := u.db.Transaction(func(tx *gorm.DB) error {
		// 유저의 진행 중인 퀘스트 행들을 잠금 (FOR UPDATE)
		var userQuests []domain.UserQuest
		if err := tx.Set("gorm:query_option", "FOR UPDATE").
			Preload("Quest").
			Where("user_id = ? AND status = ?", event.UserID, domain.QuestStatusProgress).
			Find(&userQuests).Error; err != nil {
			return err
		}

		slog.Info("HandleEvent: 진행 중인 퀘스트 조회 결과", slog.Int64("user_id", event.UserID), slog.Int("count", len(userQuests)))

		for i := range userQuests {
			uq := &userQuests[i]
			shouldUpdate := false

			if uq.Quest == nil {
				slog.Warn("HandleEvent: Quest 정보가 Preload 되지 않음", slog.Int64("user_id", event.UserID), slog.Int64("user_quest_id", uq.ID))
				continue
			}

			switch event.Type {
			case domain.EventMealCreated:
				if uq.Quest.Category == domain.QuestCategoryMeal {
					slog.Info("HandleEvent: 식사 기록 이벤트 처리 중", slog.String("quest_code", uq.Quest.Code), slog.Int("current", uq.CurrentCount))
					
					if uq.Quest.Type == domain.QuestTypeWeekly && uq.Quest.Code == "WEEKLY_STEADY" {
						// [주간 퀘스트] 캐릭터의 실제 StreakDays와 동기화
						char, err := u.characterRepo.GetByUserID(event.UserID)
						if err == nil && char != nil {
							uq.CurrentCount = char.StreakDays
						}
					} else if uq.Quest.Type == domain.QuestTypeAchievement {
						// [업적] 누적 통계 기반 실시간 반영
						count, err := u.mealRepo.CountByUserID(event.UserID)
						if err == nil {
							uq.CurrentCount = int(count)
						}
					} else if uq.Quest.Code == "DAILY_BALANCED" {
						// [영양소 퀘스트] 영양 밸런스 체크
						if u.isMealBalanced(event.UserID, event.Payload) {
							uq.CurrentCount++
						} else {
							shouldUpdate = false // 밸런스 안 맞으면 업데이트 스킵
						}
					} else {
						// 일반적인 횟수 기반 퀘스트 (오늘의 첫 식사, 삼시세끼 등)
						uq.CurrentCount++
					}

					// 공통: 목표치 초과 방지 및 업데이트 플래그
					if uq.CurrentCount > uq.Quest.TargetCount {
						uq.CurrentCount = uq.Quest.TargetCount
					}
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
			case domain.EventLevelUp:
				// [성장 퀘스트] 특정 레벨 달성 체크
				if uq.Quest != nil && uq.Quest.Category == domain.QuestCategoryGrowth && uq.Quest.Code == "REACH_LEVEL" {
					newLevel, ok := event.Payload["new_level"].(int)
					if !ok {
						// 페이로드 타입 처리 (JSON 숫자 등)
						if val, ok := event.Payload["new_level"].(float64); ok {
							newLevel = int(val)
						}
					}
					if newLevel > 0 {
						uq.CurrentCount = newLevel
						shouldUpdate = true
					}
				}
			case domain.EventAppearanceChanged:
				// 외형 변경 이벤트 — 현재 퀘스트에서 별도 처리 없음
			}


			if shouldUpdate {
				// 완료 상태 전환 체크
				isNowCompleted := false
				if uq.CurrentCount >= uq.Quest.TargetCount {
					uq.Status = domain.QuestStatusCompleted
					isNowCompleted = true
				}

				// 결과 먼저 생성 (Preload된 정보를 사용해야 하므로)
				progressResult := domain.QuestProgress{
					QuestType:  string(uq.Quest.Type),
					QuestTitle: uq.Quest.Title,
					Progress:   uq.CurrentCount,
					Target:     uq.Quest.TargetCount,
					Completed:  uq.Status == domain.QuestStatusCompleted,
				}

				// 완료되었다면 이벤트 발행
				if isNowCompleted {
					u.eventBus.Publish(domain.Event{
						Type:      domain.EventQuestCompleted,
						UserID:    event.UserID,
						CreatedAt: time.Now(),
						Payload: map[string]interface{}{
							"quest_id":    uq.QuestID,
							"quest_title": uq.Quest.Title,
							"quest_type":  string(uq.Quest.Type),
						},
					})
				}

				// Preload된 객체 제거 후 저장 (데이터 일관성 보장)
				questDef := uq.Quest
				uq.Quest = nil
				if err := tx.Save(uq).Error; err != nil {
					return err
				}
				uq.Quest = questDef // 리스트 순회를 위해 복구

				progressed = append(progressed, progressResult)
			}
		}
		return nil
	})

	return progressed, err
}

// isMealBalanced 는 사용자의 하루 권장량 대비 현재 식사의 밸런스를 검증합니다.
func (u *questUsecase) isMealBalanced(userID int64, payload map[string]interface{}) bool {
	goal, err := u.userRepo.GetNutritionGoal(userID)
	if err != nil || goal == nil {
		return false
	}

	kcal, _ := payload["calories"].(float64)
	// 한 끼 권장 기준(1/3) 대비 +-50% 오차 범위 내면 밸런스 준수로 판정
	targetKcal := float64(goal.DailyKcalTarget) / 3.0
	if kcal < targetKcal*0.5 || kcal > targetKcal*1.5 {
		return false
	}
	return true
}

func (u *questUsecase) ClaimReward(ctx context.Context, userID int64, userQuestID int64) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		// 1. 보상 중복 수령 방지를 위해 해당 유저 퀘스트 행을 잠금
		var uq domain.UserQuest
		if err := tx.Set("gorm:query_option", "FOR UPDATE").
			Preload("Quest").
			First(&uq, userQuestID).Error; err != nil {
			return err
		}

		if uq.UserID != userID {
			return fmt.Errorf("권한이 없습니다")
		}

		if uq.Status != domain.QuestStatusCompleted {
			return fmt.Errorf("이미 수령했거나 완료되지 않은 퀘스트입니다")
		}

		// 2. 통합 보상 지급 처리 (Atomic)
		// 포인트 지급
		if uq.Quest.RewardPoint > 0 {
			if err := u.userRepo.AddPoint(userID, uq.Quest.RewardPoint); err != nil {
				return err
			}
		}

		// 경험치 지급 및 레벨업 처리
		if uq.Quest.RewardExp > 0 {
			char, err := u.characterRepo.GetByUserID(userID)
			if err != nil {
				return err
			}
			if char != nil {
				char.Exp += uq.Quest.RewardExp
				for char.Exp >= char.Level*100 {
					char.Exp -= char.Level * 100
					char.Level++
				}
				if err := u.characterRepo.Update(char); err != nil {
					return err
				}
			}
		}

		// 칭호 보상 지급
		if uq.Quest.RewardTitleID != nil {
			userTitle := &domain.UserTitle{
				UserID:     userID,
				TitleID:    *uq.Quest.RewardTitleID,
				AchievedAt: time.Now(),
			}
			if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(userTitle).Error; err != nil {
				return err
			}
		}

		// 뱃지 보상 지급
		if uq.Quest.RewardBadgeID != nil {
			userBadge := &domain.UserBadge{
				UserID:     userID,
				BadgeID:    *uq.Quest.RewardBadgeID,
				AcquiredAt: time.Now(),
			}
			if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(userBadge).Error; err != nil {
				return err
			}

			u.eventBus.Publish(domain.Event{
				Type:      domain.EventBadgeAcquired,
				UserID:    userID,
				CreatedAt: time.Now(),
				Payload:   map[string]interface{}{"badge_id": *uq.Quest.RewardBadgeID},
			})
		}

		// 코스메틱 아이템 보상 지급
		if uq.Quest.RewardItemID != nil {
			userReward := &domain.UserReward{
				UserID:     userID,
				RewardID:   *uq.Quest.RewardItemID,
				QuestID:    &uq.QuestID,
				AchievedAt: time.Now(),
			}
			if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(userReward).Error; err != nil {
				return err
			}
		}

		// 3. 상태 변경 (CLAIMED)
		uq.Status = domain.QuestStatusClaimed
		uq.Quest = nil // Preload된 객체로 인한 사이드 이펙트(quests 테이블 업데이트 시도) 방지
		return tx.Save(&uq).Error
	})
}

func (u *questUsecase) AssignDailyQuests(ctx context.Context, userID int64) error {
	// 1. 기존 일일 퀘스트 삭제
	if err := u.questRepo.DeleteQuestsByUserIDAndType(ctx, userID, domain.QuestTypeDaily); err != nil {
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

func (u *questUsecase) AssignWeeklyQuests(ctx context.Context, userID int64) error {
	// 1. 기존 주간 퀘스트 삭제
	if err := u.questRepo.DeleteQuestsByUserIDAndType(ctx, userID, domain.QuestTypeWeekly); err != nil {
		return err
	}

	// 2. 활성 주간 퀘스트 조회
	pool, err := u.questRepo.GetAvailableQuestsByType(ctx, domain.QuestTypeWeekly)
	if err != nil {
		return err
	}

	now := time.Now()
	// 다음주 월요일 새벽 5시 계산
	daysUntilMonday := (int(time.Monday) - int(now.Weekday()) + 7) % 7
	if daysUntilMonday == 0 && now.Hour() >= 5 {
		daysUntilMonday = 7
	}
	expiresAt := time.Date(now.Year(), now.Month(), now.Day(), 5, 0, 0, 0, now.Location()).AddDate(0, 0, daysUntilMonday)

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

func (u *questUsecase) AssignAchievementQuests(ctx context.Context, userID int64) error {
	// 1. 모든 업적 조회
	pool, err := u.questRepo.GetAvailableQuestsByType(ctx, domain.QuestTypeAchievement)
	if err != nil {
		return err
	}

	now := time.Now()
	// 업적은 만료 없음 (먼 미래)
	expiresAt := now.AddDate(100, 0, 0)

	// 현재 누적 식사 수 조회
	mealCount, _ := u.mealRepo.CountByUserID(userID)

	// 2. 부여 (이미 있는 경우 제외 - FirstOrCreate 또는 에러 무시)
	for _, q := range pool {
		uq := domain.UserQuest{
			UserID:       userID,
			QuestID:      q.ID,
			Status:       domain.QuestStatusProgress,
			CurrentCount: int(mealCount),
			AssignedAt:   now,
			ExpiresAt:    expiresAt,
		}

		// 초기 조건 달성 체크
		if uq.CurrentCount >= q.TargetCount {
			uq.Status = domain.QuestStatusCompleted
		}

		if err := u.questRepo.CreateUserQuest(ctx, &uq); err != nil {
			// 중복 에러 무시 (이미 할당된 업적)
			continue
		}
	}

	return nil
}

func (u *questUsecase) AssignTutorialQuest(ctx context.Context, userID int64) error {
	// 튜토리얼 퀘스트 정의 (시드 데이터에 있다고 가정: 'TUTORIAL_FIRST_MEAL')
	q, err := u.questRepo.GetQuestDefinitionByCode(ctx, "TUTORIAL_FIRST_MEAL")
	if err != nil {
		return err
	}

	now := time.Now()
	uq := domain.UserQuest{
		UserID:     userID,
		QuestID:    q.ID,
		Status:     domain.QuestStatusProgress,
		AssignedAt: now,
		ExpiresAt:  now.AddDate(0, 0, 7), // 7일 내 완료 유도
	}
	return u.questRepo.CreateUserQuest(ctx, &uq)
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

func (u *questUsecase) AssignAllUsersWeeklyQuests(ctx context.Context) error {
	slog.Info("모든 유저에게 주간 퀘스트 할당 시작")
	var userIDs []int64
	if err := u.db.Model(&domain.User{}).Pluck("id", &userIDs).Error; err != nil {
		return err
	}

	for _, userID := range userIDs {
		if err := u.AssignWeeklyQuests(ctx, userID); err != nil {
			slog.Error("유저 주간 퀘스트 할당 실패", slog.Int64("user_id", userID), slog.Any("error", err))
		}
	}

	slog.Info("모든 유저에게 주간 퀘스트 할당 완료", slog.Int("count", len(userIDs)))
	return nil
}

func (u *questUsecase) ProcessExpiredQuests(ctx context.Context) error {
	slog.Info("만료된 퀘스트 정리 작업 시작")
	count, err := u.questRepo.UpdateExpiredQuests(ctx, time.Now())
	if err != nil {
		return err
	}
	slog.Info("만료된 퀘스트 정리 작업 완료", slog.Int64("count", count))
	return nil
}
