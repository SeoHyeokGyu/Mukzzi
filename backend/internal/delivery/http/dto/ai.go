package dto

import "github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"

// ─────────────────────────────────────────
// Request DTO
// ─────────────────────────────────────────

type AnalyzeMealRequest struct {
	ImageURL string `json:"image_url" binding:"required,url"`
}

type RecommendMealRequest struct {
	MealType domain.MealType `json:"meal_type" binding:"required,oneof=BREAKFAST LUNCH DINNER SNACK"`
}

type NutritionCoachingRequest struct {
	Date string `json:"date" binding:"omitempty"` // YYYY-MM-DD
}

// ─────────────────────────────────────────
// Response DTO (Usecase Output과 구조가 같으므로 직접 사용하거나 재정의 가능합니다)
// ─────────────────────────────────────────
