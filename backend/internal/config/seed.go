package config

import (
	"errors"
	"fmt"
	"log/slog"
	"strings"
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
	if err := db.Exec("ALTER TABLE rewards ADD COLUMN IF NOT EXISTS render_config jsonb").Error; err != nil {
		slog.Error("rewards 테이블 render_config 컬럼 생성 실패", slog.Any("error", err))
		return
	}
	if err := db.Exec(`
		CREATE TABLE IF NOT EXISTS character_equipment (
			id bigint PRIMARY KEY,
			created_at timestamptz NOT NULL DEFAULT now(),
			updated_at timestamptz NOT NULL DEFAULT now(),
			deleted_at timestamptz,
			character_id bigint NOT NULL REFERENCES characters(id),
			user_id bigint NOT NULL REFERENCES users(id),
			slot varchar(20) NOT NULL,
			reward_id bigint NOT NULL REFERENCES rewards(id),
			equipped_at timestamptz NOT NULL DEFAULT now()
		)
	`).Error; err != nil {
		slog.Error("character_equipment 테이블 생성 실패", slog.Any("error", err))
		return
	}
	if err := db.Exec("CREATE INDEX IF NOT EXISTS idx_character_equipment_user_id ON character_equipment(user_id)").Error; err != nil {
		slog.Error("character_equipment user_id 인덱스 생성 실패", slog.Any("error", err))
		return
	}
	if err := db.Exec("CREATE UNIQUE INDEX IF NOT EXISTS idx_character_equipment_slot_active ON character_equipment(character_id, slot) WHERE deleted_at IS NULL").Error; err != nil {
		slog.Error("character_equipment 슬롯 유니크 인덱스 생성 실패", slog.Any("error", err))
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

	rewards := defaultRewards()

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
			existing.RenderConfig = r.RenderConfig
			if err := db.Save(&existing).Error; err != nil {
				slog.Error("보상 시드 업데이트 실패", slog.Any("error", err))
			}
		}
	}

	var accessories []domain.Reward
	if err := db.Where("reward_type = ?", domain.RewardAccessory).Find(&accessories).Error; err != nil {
		slog.Error("액세서리 목록 조회 실패", slog.Any("error", err))
		return
	}

	var users []domain.User
	if err := db.Find(&users).Error; err != nil {
		slog.Error("유저 목록 조회 실패", slog.Any("error", err))
		return
	}

	var userRewards []domain.UserReward
	for _, u := range users {
		for _, acc := range accessories {
			userRewards = append(userRewards, domain.UserReward{
				UserID:     u.ID,
				RewardID:   acc.ID,
				AchievedAt: time.Now(),
			})
		}
	}

	if len(userRewards) > 0 {
		if err := db.Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "user_id"}, {Name: "reward_id"}},
			DoNothing: true,
		}).CreateInBatches(&userRewards, 200).Error; err != nil {
			slog.Error("액세서리 일괄 지급 실패", slog.Any("error", err))
		}
	}

	backfillCharacterEquipment(db)

	slog.Info("보상 시드 및 기본 액세서리 지급 완료")
}

func defaultRewards() []domain.Reward {
	return []domain.Reward{
		{
			RewardType:  domain.RewardAccessory,
			Code:        "CAP_ACCESSORY",
			Name:        "먹찌 캡",
			Description: "먹찌 캐릭터가 착용하는 캡 모자입니다.",
			AssetURL:    "cap",
			RenderConfig: &domain.RewardRenderConfig{
				Slot:     domain.EquipmentSlotHead,
				OffsetX:  0,
				OffsetY:  0,
				Scale:    1,
				Rotation: 0,
				ZIndex:   30,
			},
		},
		{
			RewardType:  domain.RewardAccessory,
			Code:        "EXPLORER_GLASSES",
			Name:        "탐험가 안경",
			Description: "다양한 식단을 탐험한 먹찌를 위한 안경입니다.",
			AssetURL:    "glasses",
			RenderConfig: &domain.RewardRenderConfig{
				Slot:     domain.EquipmentSlotFace,
				OffsetX:  0,
				OffsetY:  -0.05,
				Scale:    0.78,
				Rotation: 0,
				ZIndex:   35,
			},
		},
		{
			RewardType:  domain.RewardAccessory,
			Code:        "BALANCE_CROWN",
			Name:        "균형의 왕관",
			Description: "영양 균형을 지켜낸 먹찌에게 주어지는 왕관입니다.",
			AssetURL:    "crown",
			RenderConfig: &domain.RewardRenderConfig{
				Slot:     domain.EquipmentSlotHead,
				OffsetX:  0,
				OffsetY:  -0.27,
				Scale:    0.34,
				Rotation: 0,
				ZIndex:   32,
			},
		},
		{
			RewardType:  domain.RewardAccessory,
			Code:        "FRIENDSHIP_SCARF",
			Name:        "우정의 머플러",
			Description: "오랜 시간 함께해 온 먹찌를 위한 따뜻한 머플러입니다.",
			AssetURL:    "scarf",
			RenderConfig: &domain.RewardRenderConfig{
				Slot:     domain.EquipmentSlotBack,
				OffsetX:  0,
				OffsetY:  0,
				Scale:    1,
				Rotation: 0,
				ZIndex:   10,
			},
		},
		{
			RewardType:  domain.RewardAccessory,
			Code:        "COLLECTOR_BAG",
			Name:        "수집가 배낭",
			Description: "다양한 외형을 수집한 먹찌가 메는 배낭입니다.",
			AssetURL:    "bag",
			RenderConfig: &domain.RewardRenderConfig{
				Slot:     domain.EquipmentSlotBack,
				OffsetX:  0,
				OffsetY:  0,
				Scale:    1,
				Rotation: 0,
				ZIndex:   -5,
			},
		},
		{
			RewardType:  domain.RewardAccessory,
			Code:        "LEGENDARY_AURA",
			Name:        "전설의 오라",
			Description: "최종 형태를 달성한 먹찌에게서 뿜어져 나오는 오라입니다.",
			AssetURL:    "aura",
			RenderConfig: &domain.RewardRenderConfig{
				Slot:     domain.EquipmentSlotAura,
				OffsetX:  0,
				OffsetY:  0,
				Scale:    1,
				Rotation: 0,
				ZIndex:   -10,
			},
		},
		{
			RewardType:  domain.RewardAccessory,
			Code:        "COOK_HAT_ACCESSORY",
			Name:        "요리사 모자",
			Description: "먹찌가 착용하는 멋진 요리사 모자입니다.",
			AssetURL:    "cook_hat",
			RenderConfig: &domain.RewardRenderConfig{
				Slot:     domain.EquipmentSlotHead,
				OffsetX:  0,
				OffsetY:  0,
				Scale:    1.0,
				Rotation: 0,
				ZIndex:   30,
			},
		},
		{
			RewardType:  domain.RewardAccessory,
			Code:        "DONUT_ACCESSORY",
			Name:        "맛있는 도넛",
			Description: "먹찌가 손에 들고 먹는 달콤한 핑크 도넛입니다.",
			AssetURL:    "donut",
			RenderConfig: &domain.RewardRenderConfig{
				Slot:     domain.EquipmentSlotHand,
				OffsetX:  0,
				OffsetY:  0,
				Scale:    1.0,
				Rotation: 0,
				ZIndex:   25,
			},
		},
		{
			RewardType:  domain.RewardAccessory,
			Code:        "KITCHEN_BACKGROUND",
			Name:        "주방 배경",
			Description: "먹찌가 요리하는 아늑한 주방 배경입니다.",
			AssetURL:    "background_kitchen",
			RenderConfig: &domain.RewardRenderConfig{
				Slot:     domain.EquipmentSlotBackground,
				OffsetX:  0,
				OffsetY:  0,
				Scale:    1.0,
				Rotation: 0,
				ZIndex:   -20,
			},
		},
		{
			RewardType:  domain.RewardAccessory,
			Code:        "NIGHT_BACKGROUND",
			Name:        "야경 배경",
			Description: "밤하늘과 도시 야경이 보이는 창문 배경입니다.",
			AssetURL:    "background_night",
			RenderConfig: &domain.RewardRenderConfig{
				Slot:     domain.EquipmentSlotBackground,
				OffsetX:  0,
				OffsetY:  0,
				Scale:    1.0,
				Rotation: 0,
				ZIndex:   -20,
			},
		},
		{
			RewardType:  domain.RewardAccessory,
			Code:        "WOODEN_SPOON_ACCESSORY",
			Name:        "나무 숟가락",
			Description: "먹찌가 손에 쥐는 친환경 나무 숟가락입니다.",
			AssetURL:    "wooden_spoon",
			RenderConfig: &domain.RewardRenderConfig{
				Slot:     domain.EquipmentSlotHand,
				OffsetX:  0,
				OffsetY:  0,
				Scale:    1.0,
				Rotation: 0,
				ZIndex:   25,
			},
		},
	}
}

func backfillCharacterEquipment(db *gorm.DB) {
	var chars []domain.Character
	if err := db.Find(&chars).Error; err != nil {
		slog.Error("캐릭터 장비 백필 대상 조회 실패", slog.Any("error", err))
		return
	}

	var existingEquipments []domain.CharacterEquipment
	if err := db.Find(&existingEquipments).Error; err != nil {
		slog.Error("기존 캐릭터 장비 목록 조회 실패", slog.Any("error", err))
		return
	}

	existingMap := make(map[string]int64)
	for _, eq := range existingEquipments {
		key := fmt.Sprintf("%d_%s", eq.CharacterID, eq.Slot)
		existingMap[key] = eq.RewardID
	}

	var toCreate []domain.CharacterEquipment
	var toUpdate []domain.CharacterEquipment

	now := time.Now()
	for _, char := range chars {
		if char.EquippedAccessoryID != nil {
			key := fmt.Sprintf("%d_%s", char.ID, domain.EquipmentSlotHead)
			rewardID, ok := existingMap[key]
			if !ok {
				toCreate = append(toCreate, domain.CharacterEquipment{
					CharacterID: char.ID,
					UserID:      char.UserID,
					Slot:        domain.EquipmentSlotHead,
					RewardID:    *char.EquippedAccessoryID,
					EquippedAt:  now,
				})
			} else if rewardID != *char.EquippedAccessoryID {
				toUpdate = append(toUpdate, domain.CharacterEquipment{
					CharacterID: char.ID,
					UserID:      char.UserID,
					Slot:        domain.EquipmentSlotHead,
					RewardID:    *char.EquippedAccessoryID,
					EquippedAt:  now,
				})
			}
		}
		if char.EquippedBackgroundID != nil {
			key := fmt.Sprintf("%d_%s", char.ID, domain.EquipmentSlotBackground)
			rewardID, ok := existingMap[key]
			if !ok {
				toCreate = append(toCreate, domain.CharacterEquipment{
					CharacterID: char.ID,
					UserID:      char.UserID,
					Slot:        domain.EquipmentSlotBackground,
					RewardID:    *char.EquippedBackgroundID,
					EquippedAt:  now,
				})
			} else if rewardID != *char.EquippedBackgroundID {
				toUpdate = append(toUpdate, domain.CharacterEquipment{
					CharacterID: char.ID,
					UserID:      char.UserID,
					Slot:        domain.EquipmentSlotBackground,
					RewardID:    *char.EquippedBackgroundID,
					EquippedAt:  now,
				})
			}
		}
	}

	if len(toCreate) > 0 {
		if err := db.CreateInBatches(&toCreate, 200).Error; err != nil {
			slog.Error("캐릭터 장비 백필 벌크 생성 실패", slog.Any("error", err))
		}
	}

	for _, eq := range toUpdate {
		if err := db.Model(&domain.CharacterEquipment{}).
			Where("character_id = ? AND slot = ?", eq.CharacterID, eq.Slot).
			Update("reward_id", eq.RewardID).Error; err != nil {
			slog.Error("캐릭터 장비 백필 개별 갱신 실패", slog.Int64("character_id", eq.CharacterID), slog.String("slot", string(eq.Slot)), slog.Any("error", err))
		}
	}
}

func BackfillMenuAllergies(db *gorm.DB) {
	var menus []domain.Menu
	// allergies가 비어있거나 NULL인 메뉴만 조회
	if err := db.Where("allergies = '' OR allergies IS NULL").Find(&menus).Error; err != nil {
		slog.Error("기존 메뉴 조회 실패 (알레르기 백필용)", slog.Any("error", err))
		return
	}

	if len(menus) == 0 {
		return
	}

	slog.Info("기존 메뉴 알레르기 백필 시작", slog.Int("count", len(menus)))

	db.Transaction(func(tx *gorm.DB) error {
		for _, m := range menus {
			var list []string
			name := m.Name

			if strings.Contains(name, "우유") || strings.Contains(name, "치즈") || strings.Contains(name, "라떼") || strings.Contains(name, "요거트") || strings.Contains(name, "버터") ||
				strings.Contains(strings.ToLower(name), "milk") || strings.Contains(strings.ToLower(name), "cheese") || strings.Contains(strings.ToLower(name), "yogurt") || strings.Contains(strings.ToLower(name), "butter") {
				list = append(list, "우유")
			}
			if strings.Contains(name, "땅콩") || strings.Contains(name, "피넛") || strings.Contains(strings.ToLower(name), "peanut") {
				list = append(list, "땅콩")
			}
			if strings.Contains(name, "새우") || strings.Contains(name, "쉬림프") || strings.Contains(strings.ToLower(name), "shrimp") {
				list = append(list, "새우")
			}
			if strings.Contains(name, "계란") || strings.Contains(name, "달걀") || strings.Contains(name, "에그") || strings.Contains(name, "메추리") || strings.Contains(strings.ToLower(name), "egg") {
				list = append(list, "계란")
			}
			if strings.Contains(name, "밀가루") || strings.Contains(name, "빵") || strings.Contains(name, "면") || strings.Contains(name, "파스타") || strings.Contains(name, "국수") ||
				strings.Contains(strings.ToLower(name), "wheat") || strings.Contains(strings.ToLower(name), "bread") || strings.Contains(strings.ToLower(name), "pasta") || strings.Contains(strings.ToLower(name), "noodle") {
				list = append(list, "밀")
			}
			if strings.Contains(name, "대두") || strings.Contains(name, "두부") || strings.Contains(name, "콩") || strings.Contains(name, "된장") || strings.Contains(name, "간장") ||
				strings.Contains(strings.ToLower(name), "soy") || strings.Contains(strings.ToLower(name), "tofu") {
				list = append(list, "대두")
			}
			if strings.Contains(name, "게장") || strings.Contains(name, "꽃게") || strings.Contains(name, "크랩") || strings.Contains(strings.ToLower(name), "crab") {
				list = append(list, "게")
			}
			if strings.Contains(name, "돼지") || strings.Contains(name, "돈가스") || strings.Contains(name, "삼겹살") || strings.Contains(name, "포크") ||
				strings.Contains(strings.ToLower(name), "pork") || strings.Contains(strings.ToLower(name), "bacon") {
				list = append(list, "돼지고기")
			}
			if strings.Contains(name, "복숭아") || strings.Contains(name, "피치") || strings.Contains(strings.ToLower(name), "peach") {
				list = append(list, "복숭아")
			}
			if strings.Contains(name, "토마토") || strings.Contains(name, "케찹") || strings.Contains(strings.ToLower(name), "tomato") {
				list = append(list, "토마토")
			}

			if len(list) > 0 {
				m.Allergies = strings.Join(list, ",")
				tx.Model(&domain.Menu{}).Where("id = ?", m.ID).Update("allergies", m.Allergies)
			}
		}
		return nil
	})

	slog.Info("기존 메뉴 알레르기 백필 완료")
}
