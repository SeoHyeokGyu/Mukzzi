package usecase

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
	"github.com/redis/go-redis/v9"
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
	rdb             *redis.Client
}

func NewAIUsecase(
	client GeminiClient,
	dailyIntakeRepo repository.DailyIntakeRepository,
	mealRepo repository.MealRepository,
	userRepo repository.UserRepository,
	preferenceRepo repository.PreferenceRepository,
	rdb *redis.Client,
) AIUsecase {
	return &aiUsecase{
		geminiClient:    client,
		dailyIntakeRepo: dailyIntakeRepo,
		mealRepo:        mealRepo,
		userRepo:        userRepo,
		preferenceRepo:  preferenceRepo,
		rdb:             rdb,
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
	todayStr := time.Now().Format("2006-01-02")
	cacheKey := fmt.Sprintf("ai:recommend:%d:%s:%s", input.UserID, input.MealType, todayStr)

	// 1. Redis 캐시 조회
	if u.rdb != nil {
		if val, err := u.rdb.Get(ctx, cacheKey).Result(); err == nil {
			var cachedOutput RecommendMealOutput
			if err := json.Unmarshal([]byte(val), &cachedOutput); err == nil {
				slog.Info("AI 식단 추천 캐시 Hit", slog.Int64("user_id", input.UserID), slog.String("meal_type", string(input.MealType)))
				return &cachedOutput, nil
			}
		}
	}

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

	// 2. Redis 캐시 저장
	if u.rdb != nil {
		if cacheVal, err := json.Marshal(output); err == nil {
			now := time.Now()
			midnight := time.Date(now.Year(), now.Month(), now.Day(), 23, 59, 59, 0, now.Location())
			ttl := midnight.Sub(now)
			if ttl < 5*time.Minute {
				ttl = 24 * time.Hour
			}
			_ = u.rdb.Set(ctx, cacheKey, cacheVal, ttl).Err()
			slog.Info("AI 식단 추천 캐시 Set", slog.Int64("user_id", input.UserID), slog.String("meal_type", string(input.MealType)), slog.Duration("ttl", ttl))
		}
	}

	return &output, nil
}

func (u *aiUsecase) GetNutritionCoaching(ctx context.Context, input NutritionCoachingInput) (*NutritionCoachingOutput, error) {
	if input.Date == "" {
		input.Date = time.Now().Format(time.DateOnly)
	}

	cacheKey := fmt.Sprintf("ai:coaching:%d:%s", input.UserID, input.Date)

	// 1. Redis 캐시 조회
	if u.rdb != nil {
		if val, err := u.rdb.Get(ctx, cacheKey).Result(); err == nil {
			var cachedOutput NutritionCoachingOutput
			if err := json.Unmarshal([]byte(val), &cachedOutput); err == nil {
				slog.Info("AI 영양 코칭 캐시 Hit", slog.Int64("user_id", input.UserID), slog.String("date", input.Date))
				return &cachedOutput, nil
			}
		}
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

	var jsonRes string
	var coachingErr error

	if u.geminiClient != nil {
		jsonRes, coachingErr = u.geminiClient.GenerateJSON(ctx, prompt)
	} else {
		coachingErr = fmt.Errorf("gemini client is nil")
	}

	if coachingErr != nil {
		slog.Warn("Gemini API 호출 실패, 룰 기반 영양 코칭 Fallback 실행", slog.Any("error", coachingErr))
		return u.generateFallbackCoaching(input.UserID, dailyIntake), nil
	}

	var output NutritionCoachingOutput
	if err := json.Unmarshal([]byte(jsonRes), &output); err != nil {
		slog.Warn("Gemini 응답 파싱 실패, 룰 기반 영양 코칭 Fallback 실행", slog.Any("error", err))
		return u.generateFallbackCoaching(input.UserID, dailyIntake), nil
	}

	// 2. Redis 캐시 저장
	if u.rdb != nil {
		if cacheVal, err := json.Marshal(output); err == nil {
			var ttl time.Duration
			now := time.Now()
			todayStr := now.Format(time.DateOnly)
			if input.Date == todayStr {
				midnight := time.Date(now.Year(), now.Month(), now.Day(), 23, 59, 59, 0, now.Location())
				ttl = midnight.Sub(now)
				if ttl < 5*time.Minute {
					ttl = 24 * time.Hour
				}
			} else {
				ttl = 24 * time.Hour
			}
			_ = u.rdb.Set(ctx, cacheKey, cacheVal, ttl).Err()
			slog.Info("AI 영양 코칭 캐시 Set", slog.Int64("user_id", input.UserID), slog.String("date", input.Date), slog.Duration("ttl", ttl))
		}
	}

	return &output, nil
}

func (u *aiUsecase) generateFallbackCoaching(userID int64, intake *domain.DailyIntake) *NutritionCoachingOutput {
	// 1. 목표 수치 획득 (실패 시 기본값 사용)
	targetKcal := 2000
	targetCarbs := 300
	targetProtein := 60
	targetFat := 50

	if u.userRepo != nil {
		if goal, err := u.userRepo.GetNutritionGoal(userID); err == nil && goal != nil {
			if goal.DailyKcalTarget > 0 {
				targetKcal = goal.DailyKcalTarget
			}
			if goal.DailyCarbsTarget > 0 {
				targetCarbs = goal.DailyCarbsTarget
			}
			if goal.DailyProteinTarget > 0 {
				targetProtein = goal.DailyProteinTarget
			}
			if goal.DailyFatTarget > 0 {
				targetFat = goal.DailyFatTarget
			}
		}
	}

	// 2. 섭취량 대비 도달도 계산
	kcalRatio := intake.TotalCalories / float64(targetKcal)
	carbsRatio := intake.TotalCarbs / float64(targetCarbs)
	proteinRatio := intake.TotalProtein / float64(targetProtein)
	fatRatio := intake.TotalFat / float64(targetFat)

	// 점수 계산 (기본 100점에서 시작해서 목표에서 벗어날 때마다 감점)
	score := 100.0

	// 칼로리 감점 (적절 범위: 80% ~ 110%)
	if kcalRatio < 0.8 {
		score -= (0.8 - kcalRatio) * 50
	} else if kcalRatio > 1.1 {
		score -= (kcalRatio - 1.1) * 50
	}

	// 탄수화물 감점 (적절 범위: 70% ~ 120%)
	if carbsRatio < 0.7 {
		score -= (0.7 - carbsRatio) * 20
	} else if carbsRatio > 1.2 {
		score -= (carbsRatio - 1.2) * 20
	}

	// 단백질 감점 (적절 범위: 80% ~ 130%)
	if proteinRatio < 0.8 {
		score -= (0.8 - proteinRatio) * 30
	} else if proteinRatio > 1.3 {
		score -= (proteinRatio - 1.3) * 15
	}

	// 지방 감점 (적절 범위: 70% ~ 120%)
	if fatRatio < 0.7 {
		score -= (0.7 - fatRatio) * 20
	} else if fatRatio > 1.2 {
		score -= (fatRatio - 1.2) * 30
	}

	if score < 10 {
		score = 10
	}
	if score > 100 {
		score = 100
	}

	// 평가 요약 및 장/단점 생성
	var summary string
	var strengths []string
	var improvements []string
	var tips []string

	// 칼로리 기준 요약
	if kcalRatio >= 0.8 && kcalRatio <= 1.1 {
		summary = "오늘 칼로리 섭취량이 목표 대비 아주 적절합니다!"
		strengths = append(strengths, "목표 칼로리 준수")
	} else if kcalRatio < 0.8 {
		summary = "목표 칼로리보다 적게 드셨네요. 좀 더 챙겨 드세요."
		improvements = append(improvements, "칼로리 부족")
		tips = append(tips, "규칙적으로 세 끼 챙기기")
	} else {
		summary = "목표 칼로리를 초과했습니다. 조절이 필요해요."
		improvements = append(improvements, "칼로리 과다")
		tips = append(tips, "간식이나 음료 줄이기")
	}

	// 탄수화물
	if carbsRatio >= 0.7 && carbsRatio <= 1.2 {
		strengths = append(strengths, "탄수화물 적정 섭취")
	} else if carbsRatio < 0.7 {
		improvements = append(improvements, "탄수화물 부족")
		tips = append(tips, "바나나, 고구마 간식 활용")
	} else {
		improvements = append(improvements, "탄수화물 과다")
		tips = append(tips, "정제 탄수화물 줄이기")
	}

	// 단백질
	if proteinRatio >= 0.8 && proteinRatio <= 1.3 {
		strengths = append(strengths, "충분한 단백질 섭취")
	} else if proteinRatio < 0.8 {
		improvements = append(improvements, "단백질 부족")
		tips = append(tips, "닭가슴살, 계란 추가하기")
	} else {
		strengths = append(strengths, "단백질 풍부하게 섭취")
	}

	// 지방
	if fatRatio >= 0.7 && fatRatio <= 1.2 {
		// pass
	} else if fatRatio < 0.7 {
		improvements = append(improvements, "지방 부족")
		tips = append(tips, "견과류, 올리브유 섭취")
	} else {
		improvements = append(improvements, "지방 과다")
		tips = append(tips, "튀긴 음식 줄이기")
	}

	// 팁이 부족한 경우 기본 팁 제공
	if len(tips) == 0 {
		tips = append(tips, "수분 섭취를 충분히 해주세요")
		tips = append(tips, "내일도 가볍게 산책해보세요")
	}

	// 강점과 약점 개수 제한
	if len(strengths) > 2 {
		strengths = strengths[:2]
	}
	if len(improvements) > 2 {
		improvements = improvements[:2]
	}
	if len(tips) > 2 {
		tips = tips[:2]
	}

	return &NutritionCoachingOutput{
		Summary:      summary,
		Score:        int(score),
		Strengths:    strengths,
		Improvements: improvements,
		Tips:         tips,
	}
}
