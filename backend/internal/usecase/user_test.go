package usecase

import (
	"testing"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/go-redis/redismock/v9"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"gorm.io/gorm"
)

func TestUserUsecase_GetProfile(t *testing.T) {
	t.Run("프로필 조회 성공 - 비밀번호 마스킹 확인", func(t *testing.T) {
		mockRepo := new(MockUserRepository)
		dummyRDB, _ := redismock.NewClientMock()
		uc := NewUserUsecase(mockRepo, nil, nil, nil, nil, nil, nil, nil, dummyRDB, &gorm.DB{})

		mockUser := &domain.User{
			BaseDomain: domain.BaseDomain{ID: 1},
			Username:   "test",
			Password:   "hashed_password",
		}
		mockRepo.On("GetByID", int64(1)).Return(mockUser, nil)

		user, err := uc.GetProfile(1)

		assert.NoError(t, err)
		assert.Equal(t, "", user.Password)
		mockRepo.AssertExpectations(t)
	})
}

func TestUserUsecase_UpdateProfile(t *testing.T) {
	t.Run("프로필 수정 성공 - 닉네임 및 이미지", func(t *testing.T) {
		mockRepo := new(MockUserRepository)
		dummyRDB, _ := redismock.NewClientMock()
		uc := NewUserUsecase(mockRepo, nil, nil, nil, nil, nil, nil, nil, dummyRDB, &gorm.DB{})

		existingUser := &domain.User{
			BaseDomain:      domain.BaseDomain{ID: 1},
			Nickname:        "old",
			ProfileImageURL: "old.jpg",
		}
		mockRepo.On("GetByID", int64(1)).Return(existingUser, nil)
		mockRepo.On("Update", mock.Anything).Return(nil)

		err := uc.UpdateProfile(1, "new", "new.jpg")

		assert.NoError(t, err)
		assert.Equal(t, "new", existingUser.Nickname)
		assert.Equal(t, "new.jpg", existingUser.ProfileImageURL)
		mockRepo.AssertExpectations(t)
	})
}

func TestUserUsecase_UpdateBody(t *testing.T) {
	t.Run("신체 정보 업데이트 성공", func(t *testing.T) {
		mockRepo := new(MockUserRepository)
		dummyRDB, _ := redismock.NewClientMock()
		uc := NewUserUsecase(mockRepo, nil, nil, nil, nil, nil, nil, nil, dummyRDB, &gorm.DB{})

		mockRepo.On("CreateBody", mock.AnythingOfType("*domain.UserBody")).Return(nil)
		mockRepo.On("GetNutritionGoal", int64(1)).Return(nil, nil)

		err := uc.UpdateBody(1, 175.0, 70.0, domain.ActivityModerate)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})
}

func TestUserUsecase_DeleteAccount(t *testing.T) {
	t.Run("계정 삭제 성공", func(t *testing.T) {
		mockRepo := new(MockUserRepository)
		dummyRDB, _ := redismock.NewClientMock()
		uc := NewUserUsecase(mockRepo, nil, nil, nil, nil, nil, nil, nil, dummyRDB, &gorm.DB{})

		mockRepo.On("Delete", int64(1)).Return(nil)

		err := uc.DeleteAccount(1)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})
}

func TestUserUsecase_NutritionCalculation(t *testing.T) {
	t.Run("영양 목표 계산 로직 확인", func(t *testing.T) {
		mockRepo := new(MockUserRepository)
		uc := &userUsecase{userRepo: mockRepo}

		body := &domain.UserBody{
			Height:        180,
			Weight:        80,
			ActivityLevel: domain.ActivityModerate,
		}
		goal := &domain.UserNutritionGoal{
			Goal: domain.GoalMaintain,
		}

		uc.calculateNutritionTargets(body, goal)

		// BMR = 10*80 + 6.25*180 - 120 = 800 + 1125 - 120 = 1805
		// TDEE = 1805 * 1.375 = 2481.875
		assert.Greater(t, goal.DailyKcalTarget, 2400)
		assert.Greater(t, goal.DailyCarbsTarget, 0)
		assert.Greater(t, goal.DailyProteinTarget, 0)
		assert.Greater(t, goal.DailyFatTarget, 0)
	})
}
