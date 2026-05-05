package dto

import (
	"fmt"
	"strconv"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
)

// ─────────────────────────────────────────
// Request DTO
// ─────────────────────────────────────────

// CreateMealRequest - POST /meals
type CreateMealRequest struct {
	MenuID      *string            `json:"menu_id"`
	MenuName    string             `json:"menu_name" binding:"required,min=1,max=100"`
	Category    string             `json:"category" binding:"required,oneof=KOREAN CHINESE JAPANESE WESTERN SNACK CAFE OTHER"`
	MealType    domain.MealType    `json:"meal_type" binding:"required,oneof=BREAKFAST LUNCH DINNER SNACK"`
	ServingSize float64            `json:"serving_size" binding:"required,min=0.5,max=5"`
	RecordedAt  string             `json:"recorded_at" binding:"required"`
	WeatherTag  *domain.WeatherTag `json:"weather_tag" binding:"omitempty,oneof=SUNNY CLOUDY RAINY SNOWY WINDY HOT COLD"`
	MoodTag     *domain.MoodTag    `json:"mood_tag" binding:"omitempty,oneof=GOOD TIRED STRESSED HUNGRY EXCITED SAD NORMAL"`
	Review      *string            `json:"review" binding:"omitempty,max=500"`
	Rating      *int               `json:"rating" binding:"omitempty,min=1,max=5"`
	FriendTags  []string           `json:"friend_tags"`
	ImageURL    *string            `json:"image_url"`
}

// UpdateMealRequest - PATCH /meals/:id
type UpdateMealRequest struct {
	MenuName    *string            `json:"menu_name" binding:"omitempty,min=1,max=100"`
	Category    *string            `json:"category" binding:"omitempty,oneof=KOREAN CHINESE JAPANESE WESTERN SNACK CAFE OTHER"`
	MealType    *string            `json:"meal_type" binding:"omitempty,oneof=BREAKFAST LUNCH DINNER SNACK"`
	ServingSize *float64           `json:"serving_size" binding:"omitempty,min=0.5,max=5"`
	RecordedAt  *string            `json:"recorded_at"`
	WeatherTag  *domain.WeatherTag `json:"weather_tag" binding:"omitempty,oneof=SUNNY CLOUDY RAINY SNOWY WINDY HOT COLD"`
	MoodTag     *domain.MoodTag    `json:"mood_tag" binding:"omitempty,oneof=GOOD TIRED STRESSED HUNGRY EXCITED SAD NORMAL"`
	Review      *string            `json:"review" binding:"omitempty,max=500"`
	Rating      *int               `json:"rating" binding:"omitempty,min=1,max=5"`
}

// MealListQuery - GET /meals query params
type MealListQuery struct {
	StartDate string `form:"start_date"`
	EndDate   string `form:"end_date"`
	MealType  string `form:"meal_type"`
	Cursor    string `form:"cursor"`
	Limit     int    `form:"limit"`
}

// WeeklyNutritionQuery - GET /nutrition/weekly query params
type WeeklyNutritionQuery struct {
	StartDate string `form:"start_date" binding:"required"`
}

// ─────────────────────────────────────────
// Response DTO
// ─────────────────────────────────────────

// NutritionResponse - 영양 정보 응답
type NutritionResponse struct {
	Calories     float64 `json:"calories"`
	Carbs        float64 `json:"carbs"`
	Protein      float64 `json:"protein"`
	Fat          float64 `json:"fat"`
	Sodium       float64 `json:"sodium"`
	Fiber        float64 `json:"fiber"`
	VitaminScore float64 `json:"vitamin_score"`
}

// MealResponse - 식사 기록 단건 응답
type MealResponse struct {
	ID          string             `json:"id"`
	MenuID      *string            `json:"menu_id,omitempty"`
	MenuName    string             `json:"menu_name"`
	Category    string             `json:"category"`
	MealType    string             `json:"meal_type"`
	ServingSize float64            `json:"serving_size"`
	RecordedAt  string             `json:"recorded_at"`
	WeatherTag  *string            `json:"weather_tag,omitempty"`
	MoodTag     *string            `json:"mood_tag,omitempty"`
	Review      *string            `json:"review,omitempty"`
	Rating      *int               `json:"rating,omitempty"`
	ImageURL    *string            `json:"image_url,omitempty"`
	Nutrition   *NutritionResponse `json:"nutrition,omitempty"`
	User        *UserResponse      `json:"user,omitempty"`
}

// CreateMealResponse - POST /meals 응답
type CreateMealResponse struct {
	Meal        MealResponse         `json:"meal"`
	SideEffects *SideEffectsResponse `json:"side_effects"`
}

type SideEffectsResponse struct {
	QuestsProgressed []QuestProgressResponse `json:"quests_progressed"`
	MasteryUpdated   *domain.MasteryUpdate   `json:"mastery_updated,omitempty"`
	GrantedBadges    []BadgeResponse         `json:"granted_badges,omitempty"`
	GrantedTitle     *TitleResponse          `json:"granted_title,omitempty"`
	ExpGained        int                     `json:"exp_gained"`
	LevelUp          *domain.LevelUpEvent    `json:"level_up,omitempty"`
}

// DailyNutritionResponse - GET /nutrition/today 응답
type DailyNutritionResponse struct {
	Date             string  `json:"date"`
	TotalCalories    float64 `json:"total_calories"`
	TotalCarbs       float64 `json:"total_carbs"`
	TotalProtein     float64 `json:"total_protein"`
	TotalFat         float64 `json:"total_fat"`
	TotalSodium      float64 `json:"total_sodium"`
	TotalFiber       float64 `json:"total_fiber"`
	VitaminScore     float64 `json:"vitamin_score"`
	MealCount        int     `json:"meal_count"`
	LastCalculatedAt string  `json:"last_calculated_at"`
}

// WeeklyNutritionItem - 주간 영양 응답의 날짜별 항목
type WeeklyNutritionItem struct {
	Date          string  `json:"date"`
	TotalCalories float64 `json:"total_calories"`
	TotalCarbs    float64 `json:"total_carbs"`
	TotalProtein  float64 `json:"total_protein"`
	TotalFat      float64 `json:"total_fat"`
	MealCount     int     `json:"meal_count"`
}

// ─────────────────────────────────────────
// Mapper 함수
// ─────────────────────────────────────────

func ToMealResponse(m *domain.MealRecord) MealResponse {
	resp := MealResponse{
		ID:          strconv.FormatInt(m.ID, 10),
		MenuName:    m.MenuName,
		Category:    m.Category,
		MealType:    string(m.MealType),
		ServingSize: m.ServingSize,
		RecordedAt:  m.RecordedAt.Format(time.RFC3339),
		Review:      m.Review,
		Rating:      m.Rating,
		ImageURL:    m.ImageURL,
	}
	if m.MenuID != nil {
		id := strconv.FormatInt(*m.MenuID, 10)
		resp.MenuID = &id
	}
	if m.WeatherTag != nil {
		s := string(*m.WeatherTag)
		resp.WeatherTag = &s
	}
	if m.MoodTag != nil {
		s := string(*m.MoodTag)
		resp.MoodTag = &s
	}
	if m.Nutrition != nil {
		resp.Nutrition = &NutritionResponse{
			Calories:     m.Nutrition.Calories,
			Carbs:        m.Nutrition.Carbs,
			Protein:      m.Nutrition.Protein,
			Fat:          m.Nutrition.Fat,
			Sodium:       m.Nutrition.Sodium,
			Fiber:        m.Nutrition.Fiber,
			VitaminScore: m.Nutrition.VitaminScore,
		}
	}
	if m.User != nil {
		u := ToUserResponse(m.User)
		resp.User = &u
	}
	return resp
}

func ToDailyNutritionResponse(di *domain.DailyIntake) DailyNutritionResponse {
	return DailyNutritionResponse{
		Date:             di.Date.Format(time.DateOnly),
		TotalCalories:    di.TotalCalories,
		TotalCarbs:       di.TotalCarbs,
		TotalProtein:     di.TotalProtein,
		TotalFat:         di.TotalFat,
		TotalSodium:      di.TotalSodium,
		TotalFiber:       di.TotalFiber,
		VitaminScore:     di.VitaminScore,
		MealCount:        di.MealCount,
		LastCalculatedAt: di.UpdatedAt.Format(time.RFC3339),
	}
}

func ToWeeklyNutritionItem(di domain.DailyIntake) WeeklyNutritionItem {
	return WeeklyNutritionItem{
		Date:          di.Date.Format(time.DateOnly),
		TotalCalories: di.TotalCalories,
		TotalCarbs:    di.TotalCarbs,
		TotalProtein:  di.TotalProtein,
		TotalFat:      di.TotalFat,
		MealCount:     di.MealCount,
	}
}

func ToSideEffectsResponse(se *domain.MealSideEffects) *SideEffectsResponse {
	if se == nil {
		return nil
	}

	badges := make([]BadgeResponse, len(se.GrantedBadges))
	for i, b := range se.GrantedBadges {
		badges[i] = BadgeResponse{
			ID:          b.ID,
			Code:        b.Code,
			Name:        b.Name,
			Description: b.Description,
			IconURL:     b.IconURL,
			Acquired:    true,
		}
	}

	resp := &SideEffectsResponse{
		QuestsProgressed: ToQuestProgressListResponse(se.QuestsProgressed),
		MasteryUpdated:   se.MasteryUpdated,
		GrantedBadges:    badges,
		ExpGained:        se.ExpGained,
		LevelUp:          se.LevelUp,
	}

	if se.GrantedTitle != nil {
		resp.GrantedTitle = &TitleResponse{
			ID:          se.GrantedTitle.ID,
			Code:        se.GrantedTitle.Code,
			Name:        se.GrantedTitle.Name,
			Description: se.GrantedTitle.Description,
			Acquired:    true,
			IsEquipped:  false,
		}
	}

	return resp
}

// ToCreateMealInput - Request DTO → usecase Input 변환
func ToCreateMealInput(req CreateMealRequest, userID int64) (usecase.CreateMealInput, error) {
	recordedAt, err := time.Parse(time.RFC3339, req.RecordedAt)
	if err != nil {
		return usecase.CreateMealInput{}, fmt.Errorf("recorded_at 형식이 올바르지 않습니다: %w", err)
	}

	input := usecase.CreateMealInput{
		UserID:      userID,
		MenuName:    req.MenuName,
		Category:    req.Category,
		MealType:    req.MealType,
		ServingSize: req.ServingSize,
		RecordedAt:  recordedAt,
		WeatherTag:  req.WeatherTag,
		MoodTag:     req.MoodTag,
		Review:      req.Review,
		Rating:      req.Rating,
		IsManual:    req.MenuID == nil,
		ImageURL:    req.ImageURL,
	}

	if req.MenuID != nil {
		id, err := strconv.ParseInt(*req.MenuID, 10, 64)
		if err != nil {
			return usecase.CreateMealInput{}, fmt.Errorf("menu_id가 올바르지 않습니다: %w", err)
		}
		input.MenuID = &id
	}

	for _, fid := range req.FriendTags {
		id, err := strconv.ParseInt(fid, 10, 64)
		if err != nil {
			return usecase.CreateMealInput{}, fmt.Errorf("friend_tag id가 올바르지 않습니다: %w", err)
		}
		input.FriendTags = append(input.FriendTags, id)
	}

	return input, nil
}
