package usecase

import (
	"testing"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/go-redis/redismock/v9"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupEquipmentTest(t *testing.T) (*userUsecase, *gorm.DB, int64) {
	t.Helper()

	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	require.NoError(t, err)
	require.NoError(t, db.AutoMigrate(
		&domain.User{},
		&domain.Character{},
		&domain.Reward{},
		&domain.UserReward{},
		&domain.CharacterEquipment{},
	))

	user := domain.User{BaseDomain: domain.BaseDomain{ID: 101}, Username: "tester", Email: "tester@example.com", Password: "x", Nickname: "tester"}
	require.NoError(t, db.Create(&user).Error)

	char := domain.Character{BaseDomain: domain.BaseDomain{ID: 201}, UserID: user.ID, Name: "먹찌"}
	require.NoError(t, db.Create(&char).Error)

	rdb, _ := redismock.NewClientMock()
	uc := &userUsecase{
		characterRepo: repositoryBackedCharacterRepo{db: db},
		rdb:           rdb,
		db:            db,
	}

	return uc, db, user.ID
}

type repositoryBackedCharacterRepo struct {
	db *gorm.DB
}

func (r repositoryBackedCharacterRepo) GetByUserID(userID int64) (*domain.Character, error) {
	var char domain.Character
	err := r.db.Preload("Equipment.Reward").Where("user_id = ?", userID).First(&char).Error
	if err != nil {
		return nil, err
	}
	return &char, nil
}

func (r repositoryBackedCharacterRepo) Update(char *domain.Character) error {
	return r.db.Save(char).Error
}

func createOwnedReward(t *testing.T, db *gorm.DB, userID int64, id int64, slot domain.EquipmentSlot, code string) {
	t.Helper()

	reward := domain.Reward{
		BaseDomain:  domain.BaseDomain{ID: id},
		RewardType:  domain.RewardAccessory,
		Code:        code,
		Name:        code,
		Description: code,
		AssetURL:    code,
		RenderConfig: &domain.RewardRenderConfig{
			Slot:     slot,
			OffsetX:  0,
			OffsetY:  0,
			Scale:    0.5,
			Rotation: 0,
			ZIndex:   10,
		},
	}
	require.NoError(t, db.Create(&reward).Error)
	require.NoError(t, db.Create(&domain.UserReward{
		BaseDomain: domain.BaseDomain{ID: id + 1000},
		UserID:     userID,
		RewardID:   id,
		AchievedAt: time.Now(),
	}).Error)
}

func TestUserUsecase_EquipItemBySlot(t *testing.T) {
	t.Run("다른 슬롯에 여러 액세서리를 동시에 장착한다", func(t *testing.T) {
		uc, db, userID := setupEquipmentTest(t)
		createOwnedReward(t, db, userID, 301, domain.EquipmentSlotHead, "CAP")
		createOwnedReward(t, db, userID, 302, domain.EquipmentSlotFace, "GLASSES")

		headID := "301"
		faceID := "302"
		require.NoError(t, uc.EquipItem(userID, domain.EquipmentSlotHead, &headID))
		require.NoError(t, uc.EquipItem(userID, domain.EquipmentSlotFace, &faceID))

		var equipment []domain.CharacterEquipment
		require.NoError(t, db.Where("user_id = ?", userID).Order("slot ASC").Find(&equipment).Error)
		require.Len(t, equipment, 2)
		assert.Equal(t, domain.EquipmentSlotFace, equipment[0].Slot)
		assert.Equal(t, int64(302), equipment[0].RewardID)
		assert.Equal(t, domain.EquipmentSlotHead, equipment[1].Slot)
		assert.Equal(t, int64(301), equipment[1].RewardID)
	})

	t.Run("같은 슬롯 장착은 기존 아이템을 교체한다", func(t *testing.T) {
		uc, db, userID := setupEquipmentTest(t)
		createOwnedReward(t, db, userID, 401, domain.EquipmentSlotHead, "CAP")
		createOwnedReward(t, db, userID, 402, domain.EquipmentSlotHead, "CROWN")

		firstID := "401"
		secondID := "402"
		require.NoError(t, uc.EquipItem(userID, domain.EquipmentSlotHead, &firstID))
		require.NoError(t, uc.EquipItem(userID, domain.EquipmentSlotHead, &secondID))

		var equipment []domain.CharacterEquipment
		require.NoError(t, db.Where("user_id = ?", userID).Find(&equipment).Error)
		require.Len(t, equipment, 1)
		assert.Equal(t, domain.EquipmentSlotHead, equipment[0].Slot)
		assert.Equal(t, int64(402), equipment[0].RewardID)
	})

	t.Run("슬롯 해제는 다른 슬롯 장착을 유지한다", func(t *testing.T) {
		uc, db, userID := setupEquipmentTest(t)
		createOwnedReward(t, db, userID, 501, domain.EquipmentSlotHead, "CAP")
		createOwnedReward(t, db, userID, 502, domain.EquipmentSlotFace, "GLASSES")

		headID := "501"
		faceID := "502"
		require.NoError(t, uc.EquipItem(userID, domain.EquipmentSlotHead, &headID))
		require.NoError(t, uc.EquipItem(userID, domain.EquipmentSlotFace, &faceID))
		require.NoError(t, uc.EquipItem(userID, domain.EquipmentSlotHead, nil))

		var equipment []domain.CharacterEquipment
		require.NoError(t, db.Where("user_id = ?", userID).Find(&equipment).Error)
		require.Len(t, equipment, 1)
		assert.Equal(t, domain.EquipmentSlotFace, equipment[0].Slot)
		assert.Equal(t, int64(502), equipment[0].RewardID)
	})

	t.Run("요청 슬롯과 보상 슬롯이 다르면 거부한다", func(t *testing.T) {
		uc, db, userID := setupEquipmentTest(t)
		createOwnedReward(t, db, userID, 601, domain.EquipmentSlotHead, "CAP")

		rewardID := "601"
		err := uc.EquipItem(userID, domain.EquipmentSlotFace, &rewardID)

		assert.ErrorIs(t, err, ErrEquipmentSlotMismatch)
	})
}
