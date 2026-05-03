package config

import (
	"log/slog"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
)

func SeedQuests(db *gorm.DB) {
	quests := []domain.QuestDefinition{
		// 일일 퀘스트 (DAILY)
		{
			Code:        "DAILY_MEAL_1",
			Type:        domain.QuestTypeDaily,
			Category:    domain.QuestCategoryMeal,
			Title:       "오늘의 첫 기록",
			Description: "오늘 첫 식사를 기록해보세요.",
			TargetCount: 1,
			RewardPoint: 10,
			RewardExp:   20,
			IsActive:    true,
		},
		{
			Code:        "DAILY_MEAL_3",
			Type:        domain.QuestTypeDaily,
			Category:    domain.QuestCategoryMeal,
			Title:       "삼시세끼 달성",
			Description: "오늘 3번의 식사를 모두 기록해보세요.",
			TargetCount: 3,
			RewardPoint: 30,
			RewardExp:   50,
			IsActive:    true,
		},
		{
			Code:        "NUDGE_FRIEND",
			Type:        domain.QuestTypeDaily,
			Category:    domain.QuestCategorySocial,
			Title:       "친구 응원하기",
			Description: "배고픈 친구에게 응원을 보내보세요.",
			TargetCount: 1,
			RewardPoint: 5,
			RewardExp:   10,
			IsActive:    true,
		},
		{
			Code:        "WRITE_GUESTBOOK",
			Type:        domain.QuestTypeDaily,
			Category:    domain.QuestCategorySocial,
			Title:       "따뜻한 한마디",
			Description: "친구 방명록에 글을 남겨보세요.",
			TargetCount: 1,
			RewardPoint: 5,
			RewardExp:   10,
			IsActive:    true,
		},

		// 주간 퀘스트 (WEEKLY)
		{
			Code:        "WEEKLY_STEADY",
			Type:        domain.QuestTypeWeekly,
			Category:    domain.QuestCategoryMeal,
			Title:       "꾸준한 기록러",
			Description: "일주일 동안 매일 1회 이상 식사를 기록하세요.",
			TargetCount: 7,
			RewardPoint: 100,
			RewardExp:   200,
			IsActive:    true,
		},

		// 업적 (ACHIEVEMENT)
		{
			Code:        "ACHIEVE_MEAL_100",
			Type:        domain.QuestTypeAchievement,
			Category:    domain.QuestCategoryMeal,
			Title:       "백 끼의 장인",
			Description: "누적 100번의 식사를 기록했습니다.",
			TargetCount: 100,
			RewardPoint: 500,
			RewardExp:   1000,
			IsActive:    true,
		},
	}

	result := db.Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "code"}},
		UpdateAll: true,
	}).Create(&quests)

	if result.Error != nil {
		slog.Error("퀘스트 시드 데이터 삽입 실패", slog.Any("error", result.Error))
		return
	}

	slog.Info("퀘스트 시드 완료", slog.Int64("inserted", result.RowsAffected))
}
