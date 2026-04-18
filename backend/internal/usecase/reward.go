package usecase

import (
	"fmt"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

// RewardUsecase 보상 유즈케이스 인터페이스
type RewardUsecase interface {
	GetRewards(userID int64) ([]domain.Reward, map[int64]*domain.UserReward, error)
}

type rewardUsecaseImpl struct {
	rewardRepo repository.RewardRepository
}

func NewRewardUsecase(rewardRepo repository.RewardRepository) RewardUsecase {
	return &rewardUsecaseImpl{rewardRepo: rewardRepo}
}

func (u *rewardUsecaseImpl) GetRewards(userID int64) ([]domain.Reward, map[int64]*domain.UserReward, error) {
	rewards, err := u.rewardRepo.FindAll()
	if err != nil {
		return nil, nil, fmt.Errorf("보상 목록 조회 실패: %w", err)
	}

	userRewards, err := u.rewardRepo.FindUserRewards(userID)
	if err != nil {
		return nil, nil, fmt.Errorf("사용자 보상 조회 실패: %w", err)
	}

	acquiredMap := make(map[int64]*domain.UserReward, len(userRewards))
	for i := range userRewards {
		acquiredMap[userRewards[i].RewardID] = &userRewards[i]
	}

	return rewards, acquiredMap, nil
}
