package config

import (
	"log/slog"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
)

func SeedBadges(db *gorm.DB) {
	badges := []domain.Badge{
		{
			Code:        "FIRST_MEAL",
			Name:        "첫 한 끼",
			Description: "처음으로 식사를 기록했습니다.",
		},
		{
			Code:        "THREE_MEALS_A_DAY",
			Name:        "삼시세끼",
			Description: "하루 3끼를 모두 기록했습니다.",
		},
		{
			Code:        "STREAK_7",
			Name:        "7일 연속",
			Description: "7일 연속으로 식사를 기록했습니다.",
		},
		{
			Code:        "STREAK_30",
			Name:        "한 달 개근",
			Description: "30일 연속으로 식사를 기록했습니다.",
		},
		{
			Code:        "MENU_EXPLORER",
			Name:        "메뉴 탐험가",
			Description: "서로 다른 메뉴 50종을 기록했습니다.",
		},
		{
			Code:        "BALANCE_MASTER",
			Name:        "균형 마스터",
			Description: "7일 연속으로 영양 균형을 달성했습니다.",
		},
		{
			Code:        "COLLECTION_50",
			Name:        "도감 수집가",
			Description: "먹찌 도감 50종을 달성했습니다.",
		},
		{
			Code:        "COLLECTION_ALL",
			Name:        "완전 도감",
			Description: "먹찌 도감 625종을 모두 달성했습니다.",
		},
	}

	result := db.Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "code"}},
		DoNothing: true,
	}).Create(&badges)

	if result.Error != nil {
		slog.Error("뱃지 시드 데이터 삽입 실패", slog.Any("error", result.Error))
		return
	}

	slog.Info("뱃지 시드 완료", slog.Int64("inserted", result.RowsAffected))
}
