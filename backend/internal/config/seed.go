package config

import (
	"errors"
	"log/slog"
	"time"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
)

func SeedTitles(db *gorm.DB) {
	titles := []domain.Title{
		{
			Code:        "MASTERY_ARTISAN",
			Name:        "먹찌 장인",
			Description: "하나의 메뉴를 20회 이상 기록했습니다.",
		},
		{
			Code:        "MASTERY_MASTER",
			Name:        "먹찌 마스터",
			Description: "하나의 메뉴를 50회 이상 기록했습니다.",
		},
	}

	result := db.Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "code"}},
		DoNothing: true,
	}).Create(&titles)

	if result.Error != nil {
		slog.Error("칭호 시드 데이터 삽입 실패", slog.Any("error", result.Error))
		return
	}

	slog.Info("칭호 시드 완료", slog.Int64("inserted", result.RowsAffected))
}

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
		{
			Code:        "ACHIEVE_MEAL_100",
			Name:        "백 끼의 장인",
			Description: "누적 100번의 식사를 기록했습니다.",
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

func SeedRewards(db *gorm.DB) {
	// 0. ALTER TABLE을 사용해 code 컬럼이 없는 경우 단순 컬럼으로 먼저 생성 (unique index 미생성 상태)
	if err := db.Exec("ALTER TABLE rewards ADD COLUMN IF NOT EXISTS code varchar(50)").Error; err != nil {
		slog.Error("rewards 테이블 code 컬럼 생성 실패", slog.Any("error", err))
		return
	}

	// 1. 기존 데이터 백필 (Code 컬럼이 누락/비어있는 데이터 보정)
	// 기존 보상 데이터의 ID 및 컨텐츠 가치를 보존하기 위해 REWARD_<ID> 로 백필합니다.
	var itemsWithoutCode []domain.Reward
	if err := db.Where("code IS NULL OR code = ''").Find(&itemsWithoutCode).Error; err == nil {
		for _, item := range itemsWithoutCode {
			item.Code = "REWARD_" + item.IDString()
			if err := db.Save(&item).Error; err != nil {
				slog.Error("기본 데이터 백필 업데이트 실패", slog.Int64("id", item.ID), slog.Any("error", err))
			}
		}
	}

	// 2. 백필 완료 후 UNIQUE INDEX를 수동 생성하여 유니크 제약 오류를 방지합니다.
	if err := db.Exec("CREATE UNIQUE INDEX IF NOT EXISTS idx_rewards_code ON rewards(code)").Error; err != nil {
		slog.Error("rewards code unique 인덱스 생성 실패", slog.Any("error", err))
		return
	}

	rewards := []domain.Reward{
		{
			RewardType:  domain.RewardAccessory,
			Code:        "CAP_ACCESSORY",
			Name:        "먹찌 캡",
			Description: "먹찌 캐릭터가 착용하는 캡 모자입니다.",
			AssetURL:    "cap",
		},
	}

	for _, r := range rewards {
		var existing domain.Reward
		if err := db.Where("code = ?", r.Code).First(&existing).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				if err := db.Create(&r).Error; err != nil {
					slog.Error("보상 시드 생성 실패", slog.Any("error", err))
				}
			} else {
				slog.Error("보상 조회 실패", slog.Any("error", err))
			}
		} else {
			existing.Name = r.Name
			existing.Description = r.Description
			existing.AssetURL = r.AssetURL
			existing.RewardType = r.RewardType
			if err := db.Save(&existing).Error; err != nil {
				slog.Error("보상 시드 업데이트 실패", slog.Any("error", err))
			}
		}
	}

	var capReward domain.Reward
	if err := db.Where("code = ?", "CAP_ACCESSORY").First(&capReward).Error; err != nil {
		slog.Error("캡 액세서리 조회 실패", slog.Any("error", err))
		return
	}

	var users []domain.User
	if err := db.Find(&users).Error; err != nil {
		slog.Error("유저 목록 조회 실패", slog.Any("error", err))
		return
	}

	for _, u := range users {
		userReward := domain.UserReward{
			UserID:     u.ID,
			RewardID:   capReward.ID,
			AchievedAt: time.Now(),
		}
		if err := db.Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "user_id"}, {Name: "reward_id"}},
			DoNothing: true,
		}).Create(&userReward).Error; err != nil {
			slog.Error("캡 액세서리 지급 실패", slog.Int64("user_id", u.ID), slog.Any("error", err))
		}
	}

	slog.Info("보상 시드 및 기본 액세서리 지급 완료")
}
