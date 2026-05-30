package dto

import "github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"

type EquipItemRequest struct {
	Slot     domain.EquipmentSlot `json:"slot" binding:"omitempty,oneof=BACKGROUND BACK BODY HAND FACE HEAD AURA"`
	RewardID *string              `json:"reward_id"`

	// Deprecated: legacy single-slot fields kept for transition.
	BackgroundID *string `json:"background_id"`
	AccessoryID  *string `json:"accessory_id"`
}

type CharacterResponse struct {
	ID                       int64                                  `json:"id,string"`
	UserID                   int64                                  `json:"user_id,string"`
	Name                     string                                 `json:"name"`
	BodyType                 int                                    `json:"body_type"`
	Muscle                   int                                    `json:"muscle"`
	SkinTone                 int                                    `json:"skin_tone"`
	Expression               int                                    `json:"expression"`
	PenaltyStatus            domain.PenaltyStatus                   `json:"penalty_status"`
	Level                    int                                    `json:"level"`
	Exp                      int                                    `json:"exp"`
	StreakDays               int                                    `json:"streak_days"`
	NutritionAchievementDays int                                    `json:"nutrition_achievement_days"`
	EquippedBackground       *domain.Reward                         `json:"equipped_background,omitempty"`
	EquippedAccessory        *domain.Reward                         `json:"equipped_accessory,omitempty"`
	Equipment                map[domain.EquipmentSlot]domain.Reward `json:"equipment"`
}

func ToCharacterResponse(char *domain.Character) CharacterResponse {
	equipment := make(map[domain.EquipmentSlot]domain.Reward, len(char.Equipment))
	for _, item := range char.Equipment {
		equipment[item.Slot] = item.Reward
	}

	return CharacterResponse{
		ID:                       char.ID,
		UserID:                   char.UserID,
		Name:                     char.Name,
		BodyType:                 char.BodyType,
		Muscle:                   char.Muscle,
		SkinTone:                 char.SkinTone,
		Expression:               char.Expression,
		PenaltyStatus:            char.PenaltyStatus,
		Level:                    char.Level,
		Exp:                      char.Exp,
		StreakDays:               char.StreakDays,
		NutritionAchievementDays: char.NutritionAchievementDays,
		EquippedBackground:       char.EquippedBackground,
		EquippedAccessory:        char.EquippedAccessory,
		Equipment:                equipment,
	}
}
