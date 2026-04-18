package repository

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
)

// RewardRepository 보상 저장소 인터페이스
type RewardRepository interface {
	// FindAll 전체 보상 아이템 목록 조회
	FindAll() ([]domain.Reward, error)

	// FindUserRewards 사용자가 획득한 보상 목록 조회
	FindUserRewards(userID int64) ([]domain.UserReward, error)

	// CreateUserReward 보상 지급
	CreateUserReward(userReward *domain.UserReward) error
}

type rewardRepositoryImpl struct {
	db *gorm.DB
}

func NewRewardRepository(db *gorm.DB) RewardRepository {
	return &rewardRepositoryImpl{db: db}
}

func (r *rewardRepositoryImpl) FindAll() ([]domain.Reward, error) {
	var rewards []domain.Reward
	if err := r.db.Order("reward_type ASC, id ASC").Find(&rewards).Error; err != nil {
		return nil, err
	}
	return rewards, nil
}

func (r *rewardRepositoryImpl) FindUserRewards(userID int64) ([]domain.UserReward, error) {
	var userRewards []domain.UserReward
	if err := r.db.Preload("Reward").
		Where("user_id = ?", userID).
		Order("id DESC").
		Find(&userRewards).Error; err != nil {
		return nil, err
	}
	return userRewards, nil
}

func (r *rewardRepositoryImpl) CreateUserReward(userReward *domain.UserReward) error {
	return r.db.Create(userReward).Error
}
