package usecase

import (
	"context"
	"testing"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockQuestRepository 는 QuestRepository 의 목 객체입니다.
type MockQuestRepository struct {
	mock.Mock
}

func (m *MockQuestRepository) GetByID(ctx context.Context, id int64) (*domain.QuestDefinition, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.QuestDefinition), args.Error(1)
}

func (m *MockQuestRepository) GetActiveQuestsByUserID(ctx context.Context, userID int64) ([]domain.UserQuest, error) {
	args := m.Called(ctx, userID)
	return args.Get(0).([]domain.UserQuest), args.Error(1)
}

func (m *MockQuestRepository) GetQuestDefinitionByCode(ctx context.Context, code string) (*domain.QuestDefinition, error) {
	args := m.Called(ctx, code)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.QuestDefinition), args.Error(1)
}

func (m *MockQuestRepository) UpdateUserQuest(ctx context.Context, uq *domain.UserQuest) error {
	return m.Called(ctx, uq).Error(0)
}

func (m *MockQuestRepository) CreateUserQuest(ctx context.Context, uq *domain.UserQuest) error {
	return m.Called(ctx, uq).Error(0)
}

func (m *MockQuestRepository) GetAvailableDailyQuests(ctx context.Context, limit int) ([]domain.QuestDefinition, error) {
	args := m.Called(ctx, limit)
	return args.Get(0).([]domain.QuestDefinition), args.Error(1)
}

func (m *MockQuestRepository) DeleteDailyQuestsByUserID(ctx context.Context, userID int64) error {
	return m.Called(ctx, userID).Error(0)
}

func (m *MockQuestRepository) GetUserQuestByID(ctx context.Context, id int64) (*domain.UserQuest, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.UserQuest), args.Error(1)
}

// MockUserUsecase 는 UserUsecase 의 목 객체입니다.
type MockUserUsecase struct {
	mock.Mock
}

func (m *MockUserUsecase) GetProfile(id int64) (*domain.User, error) {
	args := m.Called(id)
	return args.Get(0).(*domain.User), args.Error(1)
}
func (m *MockUserUsecase) GetStats(id int64) (*UserStats, error) {
	args := m.Called(id)
	return args.Get(0).(*UserStats), args.Error(1)
}
func (m *MockUserUsecase) UpdateProfile(id int64, nickname, profileImageURL string) error {
	return m.Called(id, nickname, profileImageURL).Error(0)
}
func (m *MockUserUsecase) UpdateBody(id int64, height, weight float64, activityLevel domain.ActivityLevel) error {
	return m.Called(id, height, weight, activityLevel).Error(0)
}
func (m *MockUserUsecase) UpdateNutritionGoal(id int64, goal domain.DietGoal) error {
	return m.Called(id, goal).Error(0)
}
func (m *MockUserUsecase) UpdateSettings(id int64, privacyLevel *domain.PrivacyLevel, notificationSettings any) error {
	return m.Called(id, privacyLevel, notificationSettings).Error(0)
}
func (m *MockUserUsecase) DeleteAccount(id int64) error { return m.Called(id).Error(0) }
func (m *MockUserUsecase) ProcessPhysicalDeletion() error { return m.Called().Error(0) }
func (m *MockUserUsecase) GetCharacter(id int64) (*domain.Character, error) {
	args := m.Called(id)
	return args.Get(0).(*domain.Character), args.Error(1)
}
func (m *MockUserUsecase) Search(query string) ([]domain.User, error) {
	args := m.Called(query)
	return args.Get(0).([]domain.User), args.Error(1)
}
func (m *MockUserUsecase) GetRecommendations(id int64) ([]domain.User, error) {
	args := m.Called(id)
	return args.Get(0).([]domain.User), args.Error(1)
}
func (m *MockUserUsecase) Onboarding(id int64, mukzziName string, h, w float64, al domain.ActivityLevel, g domain.DietGoal, bt, mu, st, ex int) error {
	return m.Called(id, mukzziName, h, w, al, g, bt, mu, st, ex).Error(0)
}
func (m *MockUserUsecase) AddExp(userID int64, amount int) (*AddExpResult, error) {
	args := m.Called(userID, amount)
	return args.Get(0).(*AddExpResult), args.Error(1)
}
func (m *MockUserUsecase) AddPoint(ctx context.Context, userID int64, amount int) error {
	return m.Called(ctx, userID, amount).Error(0)
}
func (m *MockUserUsecase) UpdateStreakOnMeal(userID int64, recordedAt time.Time) error {
	return m.Called(userID, recordedAt).Error(0)
}
func (m *MockUserUsecase) RunInactivityPenalty() error { return m.Called().Error(0) }
func (m *MockUserUsecase) SyncRankingToRedis(ctx context.Context) error { return m.Called(ctx).Error(0) }

// MockCharacterRepository 는 CharacterRepository 의 목 객체입니다.
type MockCharacterRepository struct {
	mock.Mock
}

func (m *MockCharacterRepository) GetByUserID(userID int64) (*domain.Character, error) {
	args := m.Called(userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.Character), args.Error(1)
}

func (m *MockCharacterRepository) Update(char *domain.Character) error {
	return m.Called(char).Error(0)
}

func TestQuestUsecase_HandleEvent(t *testing.T) {
	ctx := context.Background()
	userID := int64(1)

	t.Run("식사 기록 이벤트 시 관련 퀘스트 진행도 증가", func(t *testing.T) {
		mockRepo := new(MockQuestRepository)
		mockCharRepo := new(MockCharacterRepository)
		uc := NewQuestUsecase(mockRepo, nil, mockCharRepo, nil, nil)

		event := domain.Event{
			Type:   domain.EventMealCreated,
			UserID: userID,
		}

		userQuests := []domain.UserQuest{
			{
				UserID:       userID,
				QuestID:      101,
				CurrentCount: 0,
				Status:       domain.QuestStatusProgress,
				Quest: &domain.QuestDefinition{
					BaseDomain:  domain.BaseDomain{ID: 101},
					Category:    domain.QuestCategoryMeal,
					TargetCount: 3,
					Type:        domain.QuestTypeDaily,
				},
			},
		}

		mockRepo.On("GetActiveQuestsByUserID", ctx, userID).Return(userQuests, nil)
		mockRepo.On("UpdateUserQuest", ctx, mock.Anything).Return(nil)

		progress, err := uc.HandleEvent(ctx, event)

		assert.NoError(t, err)
		assert.Len(t, progress, 1)
		assert.Equal(t, 1, progress[0].Progress)
		assert.False(t, progress[0].Completed)
		mockRepo.AssertExpectations(t)
	})

	t.Run("퀘스트 목표 달성 시 상태 변경", func(t *testing.T) {
		mockRepo := new(MockQuestRepository)
		mockCharRepo := new(MockCharacterRepository)
		uc := NewQuestUsecase(mockRepo, nil, mockCharRepo, nil, nil)

		event := domain.Event{
			Type:   domain.EventMealCreated,
			UserID: userID,
		}

		userQuests := []domain.UserQuest{
			{
				UserID:       userID,
				QuestID:      101,
				CurrentCount: 2,
				Status:       domain.QuestStatusProgress,
				Quest: &domain.QuestDefinition{
					BaseDomain:  domain.BaseDomain{ID: 101},
					Category:    domain.QuestCategoryMeal,
					TargetCount: 3,
					Type:        domain.QuestTypeDaily,
				},
			},
		}

		mockRepo.On("GetActiveQuestsByUserID", ctx, userID).Return(userQuests, nil)
		mockRepo.On("UpdateUserQuest", ctx, mock.MatchedBy(func(uq *domain.UserQuest) bool {
			return uq.Status == domain.QuestStatusCompleted
		})).Return(nil)

		progress, err := uc.HandleEvent(ctx, event)

		assert.NoError(t, err)
		assert.True(t, progress[0].Completed)
		mockRepo.AssertExpectations(t)
	})
}

func TestQuestUsecase_ClaimReward(t *testing.T) {
	t.Run("보상 수령 성공 - 포인트 및 경험치 지급", func(t *testing.T) {
		// 실제로는 Transaction 메서드를 모킹하거나, sqlmock 등을 사용해야 함.
	})
}

func TestQuestUsecase_AssignDailyQuests(t *testing.T) {
	ctx := context.Background()
	userID := int64(1)

	t.Run("일일 퀘스트 할당 성공", func(t *testing.T) {
		mockRepo := new(MockQuestRepository)
		uc := NewQuestUsecase(mockRepo, nil, nil, nil, nil)

		pool := []domain.QuestDefinition{
			{BaseDomain: domain.BaseDomain{ID: 1}, Code: "Q1"},
			{BaseDomain: domain.BaseDomain{ID: 2}, Code: "Q2"},
			{BaseDomain: domain.BaseDomain{ID: 3}, Code: "Q3"},
		}

		mockRepo.On("DeleteDailyQuestsByUserID", ctx, userID).Return(nil)
		mockRepo.On("GetAvailableDailyQuests", ctx, 3).Return(pool, nil)
		mockRepo.On("CreateUserQuest", ctx, mock.Anything).Return(nil).Times(3)

		err := uc.AssignDailyQuests(ctx, userID)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})
}


