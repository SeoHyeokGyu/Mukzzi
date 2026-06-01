package config

import (
	"testing"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestDefaultRewardsCapUsesFullCanvasOverlayConfig(t *testing.T) {
	rewards := defaultRewards()

	reward := findDefaultReward(t, rewards, "CAP_ACCESSORY")
	require.NotNil(t, reward.RenderConfig)
	assert.Equal(t, domain.EquipmentSlotHead, reward.RenderConfig.Slot)
	assert.Equal(t, 0.0, reward.RenderConfig.OffsetX)
	assert.Equal(t, 0.0, reward.RenderConfig.OffsetY)
	assert.Equal(t, 1.0, reward.RenderConfig.Scale)
	assert.Equal(t, 0.0, reward.RenderConfig.Rotation)
	assert.Equal(t, 30, reward.RenderConfig.ZIndex)
}

func TestDefaultRewardsUseCalibratedCharacterLayerConfigs(t *testing.T) {
	rewards := defaultRewards()

	tests := []struct {
		code     string
		slot     domain.EquipmentSlot
		offsetX  float64
		offsetY  float64
		scale    float64
		rotation float64
		zIndex   int
	}{
		{
			code:     "EXPLORER_GLASSES",
			slot:     domain.EquipmentSlotFace,
			offsetX:  0,
			offsetY:  -0.05,
			scale:    0.78,
			rotation: 0,
			zIndex:   35,
		},
		{
			code:     "BALANCE_CROWN",
			slot:     domain.EquipmentSlotHead,
			offsetX:  0,
			offsetY:  -0.27,
			scale:    0.34,
			rotation: 0,
			zIndex:   32,
		},
		{
			code:     "FRIENDSHIP_SCARF",
			slot:     domain.EquipmentSlotBack,
			offsetX:  0,
			offsetY:  0,
			scale:    1,
			rotation: 0,
			zIndex:   10,
		},
		{
			code:     "COLLECTOR_BAG",
			slot:     domain.EquipmentSlotBack,
			offsetX:  0,
			offsetY:  0,
			scale:    1,
			rotation: 0,
			zIndex:   -5,
		},
		{
			code:     "LEGENDARY_AURA",
			slot:     domain.EquipmentSlotAura,
			offsetX:  0,
			offsetY:  0,
			scale:    1,
			rotation: 0,
			zIndex:   -10,
		},
	}

	for _, tt := range tests {
		t.Run(tt.code, func(t *testing.T) {
			reward := findDefaultReward(t, rewards, tt.code)
			require.NotNil(t, reward.RenderConfig)
			assert.Equal(t, tt.slot, reward.RenderConfig.Slot)
			assert.Equal(t, tt.offsetX, reward.RenderConfig.OffsetX)
			assert.Equal(t, tt.offsetY, reward.RenderConfig.OffsetY)
			assert.Equal(t, tt.scale, reward.RenderConfig.Scale)
			assert.Equal(t, tt.rotation, reward.RenderConfig.Rotation)
			assert.Equal(t, tt.zIndex, reward.RenderConfig.ZIndex)
		})
	}
}

func findDefaultReward(
	t *testing.T,
	rewards []domain.Reward,
	code string,
) *domain.Reward {
	t.Helper()

	for i := range rewards {
		if rewards[i].Code == code {
			return &rewards[i]
		}
	}

	t.Fatalf("default reward %q not found", code)
	return nil
}
