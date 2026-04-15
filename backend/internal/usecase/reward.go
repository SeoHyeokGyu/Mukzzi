package usecase

import (
	"fmt"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

// RewardError 보상 관련 에러
type RewardError struct {
	Code    string
	Message string
	Details string
}

func (e *RewardError) Error() string {
	return fmt.Sprintf("[%s] %s: %s", e.Code, e.Message, e.Details)
}

// RewardUsecase 보상 유즈케이스 인터페이스
type RewardUsecase interface {
	// GetRewards 전체 보상 아이템 목록 조회 (획득/미획득 포함)
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
		return nil, nil, &RewardError{
			Code:    "REWARD_FETCH_ERROR",
			Message: "보상 목록을 조회하는 중에 오류가 발생했습니다.",
			Details: err.Error(),
		}
	}

	userRewards, err := u.rewardRepo.FindUserRewards(userID)
	if err != nil {
		return nil, nil, &RewardError{
			Code:    "USER_REWARD_FETCH_ERROR",
			Message: "사용자의 보상 정보를 조회하는 중에 오류가 발생했습니다.",
			Details: err.Error(),
		}
	}

	acquiredMap := make(map[int64]*domain.UserReward, len(userRewards))
	for i := range userRewards {
		acquiredMap[userRewards[i].RewardID] = &userRewards[i]
	}

	return rewards, acquiredMap, nil
}
