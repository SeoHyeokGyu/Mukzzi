package usecase

import (
	"context"
	"testing"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockBadgeRepository 는 BadgeRepository 인터페이스의 모핑 객체입니다.
type MockBadgeRepository struct {
	mock.Mock
}

func (m *MockBadgeRepository) FindAllBadges(limit int, offset int) ([]domain.Badge, error) {
	args := m.Called(limit, offset)
	return args.Get(0).([]domain.Badge), args.Error(1)
}

func (m *MockBadgeRepository) CountAllBadges() (int64, error) {
	args := m.Called()
	return args.Get(0).(int64), args.Error(1)
}

func (m *MockBadgeRepository) FindUserAcquiredBadges(userID int64) ([]domain.UserBadge, error) {
	args := m.Called(userID)
	return args.Get(0).([]domain.UserBadge), args.Error(1)
}

func (m *MockBadgeRepository) FindBadgeByID(badgeID int64) (*domain.Badge, error) {
	args := m.Called(badgeID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.Badge), args.Error(1)
}

func (m *MockBadgeRepository) CreateUserBadge(userBadge *domain.UserBadge) error {
	args := m.Called(userBadge)
	return args.Error(0)
}

func (m *MockBadgeRepository) FindUserBadgeByID(userID, badgeID int64) (*domain.UserBadge, error) {
	args := m.Called(userID, badgeID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.UserBadge), args.Error(1)
}

func (m *MockBadgeRepository) FindBadgeByCode(code string) (*domain.Badge, error) {
	args := m.Called(code)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.Badge), args.Error(1)
}

func (m *MockBadgeRepository) FindUnacquiredBadges(userID int64, limit, offset int) ([]domain.Badge, error) {
	args := m.Called(userID, limit, offset)
	return args.Get(0).([]domain.Badge), args.Error(1)
}

func (m *MockBadgeRepository) CountUserAcquiredBadges(userID int64) (int64, error) {
	args := m.Called(userID)
	return args.Get(0).(int64), args.Error(1)
}

func TestBadgeUsecase_GetBadges(t *testing.T) {
	mockRepo := new(MockBadgeRepository)
	uc := NewBadgeUsecase(mockRepo)

	now := time.Now()
	allBadges := []domain.Badge{
		{BaseDomain: domain.BaseDomain{ID: 1}, Code: "BADGE_1", Name: "뱃지 1"},
		{BaseDomain: domain.BaseDomain{ID: 2}, Code: "BADGE_2", Name: "뱃지 2"},
	}

	t.Run("뱃지 목록 조회 성공 - 획득 정보 포함", func(t *testing.T) {
		userID := int64(100)
		acquiredBadges := []domain.UserBadge{
			{UserID: userID, BadgeID: 1, AcquiredAt: now},
		}

		mockRepo.On("FindAllBadges", 21, 0).Return(allBadges, nil)
		mockRepo.On("FindUserAcquiredBadges", userID).Return(acquiredBadges, nil)

		result, err := uc.GetBadges(context.Background(), domain.GetBadgesQuery{
			UserID:          userID,
			IncludeAcquired: true,
			Limit:           20,
		})

		assert.NoError(t, err)
		assert.Len(t, result.Badges, 2)
		assert.Contains(t, result.AcquiredMap, int64(1))
		assert.NotContains(t, result.AcquiredMap, int64(2))
		mockRepo.AssertExpectations(t)
	})

	t.Run("미획득 뱃지만 필터링하여 조회", func(t *testing.T) {
		userID := int64(100)
		acquiredBadges := []domain.UserBadge{
			{UserID: userID, BadgeID: 1, AcquiredAt: now},
		}

		mockRepo.On("FindAllBadges", 21, 0).Return(allBadges, nil)
		mockRepo.On("FindUserAcquiredBadges", userID).Return(acquiredBadges, nil)

		result, err := uc.GetBadges(context.Background(), domain.GetBadgesQuery{
			UserID:          userID,
			IncludeAcquired: false, // 획득한 뱃지 제외
			Limit:           20,
		})

		assert.NoError(t, err)
		assert.Len(t, result.Badges, 1)
		assert.Equal(t, int64(2), result.Badges[0].ID)
	})
}
