package usecase

import (
	"context"
	"testing"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// --- Mocks ---

type MockGeminiClient struct {
	mock.Mock
}

func (m *MockGeminiClient) GenerateJSON(ctx context.Context, prompt string) (string, error) {
	args := m.Called(ctx, prompt)
	return args.String(0), args.Error(1)
}

func (m *MockGeminiClient) AnalyzeImageJSON(ctx context.Context, imageURL string, prompt string) (string, error) {
	args := m.Called(ctx, imageURL, prompt)
	return args.String(0), args.Error(1)
}

type MockDailyIntakeRepo struct {
	mock.Mock
}

func (m *MockDailyIntakeRepo) FindByUserIDAndDate(userID int64, date time.Time) (*domain.DailyIntake, error) {
	args := m.Called(userID, date)
	if args.Get(0) != nil {
		return args.Get(0).(*domain.DailyIntake), args.Error(1)
	}
	return nil, args.Error(1)
}

func (m *MockDailyIntakeRepo) FindRecentByUserID(userID int64, limit int) ([]domain.DailyIntake, error) {
	args := m.Called(userID, limit)
	return args.Get(0).([]domain.DailyIntake), args.Error(1)
}

func (m *MockDailyIntakeRepo) CountStreakDays(userID int64) (int, error) {
	args := m.Called(userID)
	return args.Int(0), args.Error(1)
}

// --- Tests ---

func TestAIUsecase_AnalyzeMealImage(t *testing.T) {
	mockClient := new(MockGeminiClient)
	uc := NewAIUsecase(mockClient, nil, nil, nil, nil)

	ctx := context.Background()
	input := AnalyzeMealInput{
		UserID:   1,
		ImageURL: "http://example.com/food.jpg",
	}

	expectedJSON := `{
		"menu_name": "된장찌개",
		"category": "KOREAN",
		"calories": 250.5,
		"carbs": 15.0,
		"protein": 10.0,
		"fat": 5.0,
		"fiber": 2.0,
		"sodium": 600.0,
		"vitamin_score": 7.5,
		"confidence": 0.95
	}`

	mockClient.On("AnalyzeImageJSON", ctx, input.ImageURL, mock.AnythingOfType("string")).Return(expectedJSON, nil)

	output, err := uc.AnalyzeMealImage(ctx, input)

	assert.NoError(t, err)
	assert.NotNil(t, output)
	assert.Equal(t, "된장찌개", output.MenuName)
	assert.Equal(t, "KOREAN", output.Category)
	assert.Equal(t, 250.5, output.Calories)
	assert.Equal(t, 0.95, output.Confidence)

	mockClient.AssertExpectations(t)
}

func TestAIUsecase_RecommendMeal(t *testing.T) {
	mockClient := new(MockGeminiClient)
	mockDailyRepo := new(MockDailyIntakeRepo)
	uc := NewAIUsecase(mockClient, mockDailyRepo, nil, nil, nil)

	ctx := context.Background()
	input := RecommendMealInput{
		UserID:   1,
		MealType: domain.MealTypeLunch,
	}

	today := time.Now()
	// Mock daily intake
	mockDailyRepo.On("FindByUserIDAndDate", int64(1), mock.MatchedBy(func(d time.Time) bool {
		return d.Year() == today.Year() && d.YearDay() == today.YearDay()
	})).Return(&domain.DailyIntake{TotalCalories: 400.0}, nil)

	expectedJSON := `{
		"recommendations": [
			{
				"menu_name": "비빔밥",
				"category": "KOREAN",
				"calories": 500,
				"description": "야채가 풍부하여 좋습니다."
			}
		],
		"reasoning": "점심으로 적절한 탄단지 비율"
	}`

	mockClient.On("GenerateJSON", ctx, mock.MatchedBy(func(prompt string) bool {
		// 프롬프트에 식사 타입과 400kcal가 포함되어 있는지 확인
		return true 
	})).Return(expectedJSON, nil)

	output, err := uc.RecommendMeal(ctx, input)

	assert.NoError(t, err)
	assert.NotNil(t, output)
	assert.Equal(t, "점심으로 적절한 탄단지 비율", output.Reasoning)
	assert.Len(t, output.Recommendations, 1)
	assert.Equal(t, "비빔밥", output.Recommendations[0].MenuName)

	mockClient.AssertExpectations(t)
	mockDailyRepo.AssertExpectations(t)
}

func TestAIUsecase_GetNutritionCoaching(t *testing.T) {
	mockClient := new(MockGeminiClient)
	mockDailyRepo := new(MockDailyIntakeRepo)
	uc := NewAIUsecase(mockClient, mockDailyRepo, nil, nil, nil)

	ctx := context.Background()
	input := NutritionCoachingInput{
		UserID: 1,
		Date:   "2026-05-30",
	}
	dateObj, _ := time.Parse(time.DateOnly, input.Date)

	mockDailyRepo.On("FindByUserIDAndDate", int64(1), dateObj).
		Return(&domain.DailyIntake{
			TotalCalories: 1500,
			TotalProtein:  50,
			MealCount:     3,
		}, nil)

	expectedJSON := `{
		"summary": "단백질이 조금 부족합니다.",
		"score": 85,
		"strengths": ["세 끼를 모두 챙겨먹음"],
		"improvements": ["단백질 부족"],
		"tips": ["닭가슴살을 추가해보세요"]
	}`

	mockClient.On("GenerateJSON", ctx, mock.AnythingOfType("string")).Return(expectedJSON, nil)

	output, err := uc.GetNutritionCoaching(ctx, input)

	assert.NoError(t, err)
	assert.NotNil(t, output)
	assert.Equal(t, 85, output.Score)
	assert.Equal(t, "단백질이 조금 부족합니다.", output.Summary)
	assert.Len(t, output.Tips, 1)

	mockClient.AssertExpectations(t)
	mockDailyRepo.AssertExpectations(t)
}
