package config

import (
	"testing"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestDefaultRewardsCapUsesFullCanvasOverlayConfig(t *testing.T) {
	rewards := defaultRewards()

	var cap *domain.Reward
	for i := range rewards {
		if rewards[i].Code == "CAP_ACCESSORY" {
			cap = &rewards[i]
			break
		}
	}

	require.NotNil(t, cap)
	require.NotNil(t, cap.RenderConfig)
	assert.Equal(t, domain.EquipmentSlotHead, cap.RenderConfig.Slot)
	assert.Equal(t, 0.0, cap.RenderConfig.OffsetX)
	assert.Equal(t, 0.0, cap.RenderConfig.OffsetY)
	assert.Equal(t, 1.0, cap.RenderConfig.Scale)
	assert.Equal(t, 0.0, cap.RenderConfig.Rotation)
	assert.Equal(t, 30, cap.RenderConfig.ZIndex)
}
