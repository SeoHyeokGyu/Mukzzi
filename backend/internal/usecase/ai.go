package usecase

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

// GeminiClient 는 외부 API 통신을 추상화한 인터페이스입니다 (테스트 Mocking용)
type GeminiClient interface {
	GenerateJSON(ctx context.Context, prompt string) (string, error)
	AnalyzeImageJSON(ctx context.Context, imageURL string, prompt string) (string, error)
}

type AnalyzeMealInput struct {
	UserID   int64
	ImageURL string
}

type AnalyzeMealOutput struct {
	MenuName     string  `json:"menu_name"`
	Category     string  `json:"category"`
	Calories     float64 `json:"calories"`
	Carbs        float64 `json:"carbs"`
	Protein      float64 `json:"protein"`
	Fat          float64 `json:"fat"`
	Fiber        float64 `json:"fiber"`
	Sodium       float64 `json:"sodium"`
	VitaminScore float64 `json:"vitamin_score"`
	Confidence   float64 `json:"confidence"`
}

type RecommendMealInput struct {
	UserID   int64
	MealType domain.MealType
}

type MealRecommendation struct {
	MenuName    string  `json:"menu_name"`
	Category    string  `json:"category"`
	Calories    float64 `json:"calories"`
	Description string  `json:"description"`
}

type RecommendMealOutput struct {
	Recommendations []MealRecommendation `json:"recommendations"`
	Reasoning       string               `json:"reasoning"`
}

type NutritionCoachingInput struct {
	UserID int64
	Date   string
}

type NutritionCoachingOutput struct {
	Summary      string   `json:"summary"`
	Score        int      `json:"score"`
	Strengths    []string `json:"strengths"`
	Improvements []string `json:"improvements"`
	Tips         []string `json:"tips"`
}

type AIUsecase interface {
	AnalyzeMealImage(ctx context.Context, input AnalyzeMealInput) (*AnalyzeMealOutput, error)
	RecommendMeal(ctx context.Context, input RecommendMealInput) (*RecommendMealOutput, error)
	GetNutritionCoaching(ctx context.Context, input NutritionCoachingInput) (*NutritionCoachingOutput, error)
}

type aiUsecase struct {
	geminiClient    GeminiClient
	dailyIntakeRepo repository.DailyIntakeRepository
	mealRepo        repository.MealRepository
	userRepo        repository.UserRepository
	preferenceRepo  repository.PreferenceRepository
}

func NewAIUsecase(
	client GeminiClient,
	dailyIntakeRepo repository.DailyIntakeRepository,
	mealRepo repository.MealRepository,
	userRepo repository.UserRepository,
	preferenceRepo repository.PreferenceRepository,
) AIUsecase {
	return &aiUsecase{
		geminiClient:    client,
		dailyIntakeRepo: dailyIntakeRepo,
		mealRepo:        mealRepo,
		userRepo:        userRepo,
		preferenceRepo:  preferenceRepo,
	}
}

func (u *aiUsecase) AnalyzeMealImage(ctx context.Context, input AnalyzeMealInput) (*AnalyzeMealOutput, error) {
	prompt := `주어진 사진의 음식을 분석해주세요.
한국 음식에 최적화하여 1인분 기준으로 다음 JSON 포맷에 맞게만 응답해주세요.
{
  "menu_name": "음식 이름",
  "category": "KOREAN | CHINESE | JAPANESE | WESTERN | SNACK | CAFE | OTHER",
  "calories": 1인분 칼로리(float),
  "carbs": 탄수화물 g(float),
  "protein": 단백질 g(float),
  "fat": 지방 g(float),
  "fiber": 식이섬유 g(float),
  "sodium": 나트륨 mg(float),
  "vitamin_score": 비타민 점수 1-10(float),
  "confidence": 인식 확신도 0.0-1.0(float)
}`

	jsonRes, err := u.geminiClient.AnalyzeImageJSON(ctx, input.ImageURL, prompt)
	if err != nil {
		return nil, fmt.Errorf("gemini analysis failed: %w", err)
	}

	var output AnalyzeMealOutput
	if err := json.Unmarshal([]byte(jsonRes), &output); err != nil {
		slog.Error("Failed to unmarshal AnalyzeMealOutput", slog.String("json", jsonRes))
		return nil, fmt.Errorf("failed to parse AI response: %w", err)
	}

	return &output, nil
}

func (u *aiUsecase) RecommendMeal(ctx context.Context, input RecommendMealInput) (*RecommendMealOutput, error) {
	today := time.Now()
	dailyIntake, err := u.dailyIntakeRepo.FindByUserIDAndDate(input.UserID, today)
	
	// 에러 무시 (기록이 없을 수 있음)
	var currentKcal float64 = 0
	if err == nil && dailyIntake != nil {
		currentKcal = dailyIntake.TotalCalories
	}

	prompt := fmt.Sprintf(`사용자의 다음 끼니(%s)를 추천해주세요. 
오늘 현재 섭취한 칼로리는 약 %.0fkcal 입니다.
부족한 영양을 채울 수 있는 건강한 식단 2가지와, 가볍게 영양을 보충할 수 있는 간식 1가지를 포함하여 총 3가지를 추천해주세요.
단, 스마트폰 화면에서 한눈에 읽기 편하도록 매우 간결하고 짧게 작성해주세요.

다음 JSON 포맷에 맞게만 응답해주세요:
{
  "recommendations": [
    {
      "menu_name": "메뉴 이름",
      "category": "KOREAN | CHINESE | JAPANESE | WESTERN | SNACK | CAFE | OTHER",
      "calories": 예상 칼로리(float),
      "description": "추천 이유 (20자 이내의 아주 짧은 1문장)"
    }
  ],
  "reasoning": "전체 추천에 대한 종합적인 이유 (40자 이내의 짧은 1문장)"
}`, input.MealType, currentKcal)

	jsonRes, err := u.geminiClient.GenerateJSON(ctx, prompt)
	if err != nil {
		return nil, fmt.Errorf("gemini recommendation failed: %w", err)
	}

	var output RecommendMealOutput
	if err := json.Unmarshal([]byte(jsonRes), &output); err != nil {
		return nil, fmt.Errorf("failed to parse AI response: %w", err)
	}

	return &output, nil
}

func (u *aiUsecase) GetNutritionCoaching(ctx context.Context, input NutritionCoachingInput) (*NutritionCoachingOutput, error) {
	if input.Date == "" {
		input.Date = time.Now().Format(time.DateOnly)
	}

	dateObj, err := time.Parse(time.DateOnly, input.Date)
	if err != nil {
		return nil, fmt.Errorf("invalid date format")
	}

	dailyIntake, err := u.dailyIntakeRepo.FindByUserIDAndDate(input.UserID, dateObj)
	if err != nil || dailyIntake == nil {
		return nil, fmt.Errorf("해당일의 식사 기록이 없어 코칭을 받을 수 없습니다")
	}

	prompt := fmt.Sprintf(`사용자의 오늘 하루 식단에 대한 영양 코칭을 작성해주세요.
오늘 섭취량:
칼로리: %.0f kcal
탄수화물: %.0f g
단백질: %.0f g
지방: %.0f g
식사 횟수: %d 번

단, 스마트폰 화면에서 한눈에 읽기 편하도록 핵심만 매우 간결하고 짧게 요약해서 작성해주세요.

다음 JSON 포맷에 맞게만 응답해주세요:
{
  "summary": "오늘 식단의 전반적인 평가 (30자 이내의 짧은 1문장)",
  "score": 1-100 사이의 건강 점수(int),
  "strengths": ["잘한 점 1 (15자 이내)", "잘한 점 2 (15자 이내)"],
  "improvements": ["아쉬운 점 1 (15자 이내)", "아쉬운 점 2 (15자 이내)"],
  "tips": ["내일을 위한 팁 1 (20자 이내)", "내일을 위한 팁 2 (20자 이내)"]
}`, dailyIntake.TotalCalories, dailyIntake.TotalCarbs, dailyIntake.TotalProtein, dailyIntake.TotalFat, dailyIntake.MealCount)

	jsonRes, err := u.geminiClient.GenerateJSON(ctx, prompt)
	if err != nil {
		return nil, fmt.Errorf("gemini coaching failed: %w", err)
	}

	var output NutritionCoachingOutput
	if err := json.Unmarshal([]byte(jsonRes), &output); err != nil {
		return nil, fmt.Errorf("failed to parse AI response: %w", err)
	}

	return &output, nil
}
