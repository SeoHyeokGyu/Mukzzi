package repository

import (
	"errors"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

// ─────────────────────────────────────────
// MealRepository
// ─────────────────────────────────────────

type MealRepository interface {
	Create(meal *domain.MealRecord) error
	FindByID(id int64) (*domain.MealRecord, error)
	FindByUserID(userID int64, filter domain.MealListFilter) ([]domain.MealRecord, int64, error)
	Update(meal *domain.MealRecord) error
	Delete(id int64, userID int64) error
}

type mealRepository struct {
	db *gorm.DB
}

func NewMealRepository(db *gorm.DB) MealRepository {
	return &mealRepository{db: db}
}

func (r *mealRepository) Create(meal *domain.MealRecord) error {
	return r.db.Create(meal).Error
}

func (r *mealRepository) FindByID(id int64) (*domain.MealRecord, error) {
	var meal domain.MealRecord
	err := r.db.
		Preload("Nutrition").
		Preload("FriendTags").
		Preload("Menu").
		Where("id = ? AND deleted_at IS NULL", id).
		First(&meal).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &meal, err
}

func (r *mealRepository) FindByUserID(userID int64, filter domain.MealListFilter) ([]domain.MealRecord, int64, error) {
	query := r.db.Model(&domain.MealRecord{}).
		Where("user_id = ? AND deleted_at IS NULL", userID)

	if filter.StartDate != "" {
		query = query.Where("recorded_at >= ?", filter.StartDate)
	}
	if filter.EndDate != "" {
		query = query.Where("recorded_at < ?", filter.EndDate+" 23:59:59")
	}
	if filter.MealType != "" {
		query = query.Where("meal_type = ?", filter.MealType)
	}
	if filter.Cursor > 0 {
		query = query.Where("id < ?", filter.Cursor)
	}

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	limit := filter.Limit
	if limit <= 0 {
		limit = 20
	}

	var meals []domain.MealRecord
	err := query.
		Preload("Nutrition").
		Order("recorded_at DESC, id DESC").
		Limit(limit).
		Find(&meals).Error

	return meals, total, err
}

func (r *mealRepository) Update(meal *domain.MealRecord) error {
	return r.db.Model(meal).
		Where("id = ? AND user_id = ? AND deleted_at IS NULL", meal.ID, meal.UserID).
		Updates(meal).Error
}

func (r *mealRepository) Delete(id int64, userID int64) error {
	result := r.db.
		Where("id = ? AND user_id = ? AND deleted_at IS NULL", id, userID).
		Delete(&domain.MealRecord{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// ─────────────────────────────────────────
// NutritionRepository
// ─────────────────────────────────────────

type NutritionRepository interface {
	FindDailyIntake(userID int64, date string) (*domain.DailyIntake, error)
	FindWeeklyIntakes(userID int64, startDate string, endDate string) ([]domain.DailyIntake, error)
}

type nutritionRepository struct {
	db *gorm.DB
}

func NewNutritionRepository(db *gorm.DB) NutritionRepository {
	return &nutritionRepository{db: db}
}

func (r *nutritionRepository) FindDailyIntake(userID int64, date string) (*domain.DailyIntake, error) {
	var di domain.DailyIntake
	err := r.db.Where("user_id = ? AND date = ?", userID, date).First(&di).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &di, err
}

func (r *nutritionRepository) FindWeeklyIntakes(userID int64, startDate string, endDate string) ([]domain.DailyIntake, error) {
	var intakes []domain.DailyIntake
	err := r.db.
		Where("user_id = ? AND date >= ? AND date <= ?", userID, startDate, endDate).
		Order("date ASC").
		Find(&intakes).Error
	return intakes, err
}

// ─────────────────────────────────────────
// MealFriendTagRepository
// ─────────────────────────────────────────

type MealFriendTagRepository interface {
	Create(tag *domain.MealFriendTag) error
	AcceptTag(mealID int64, taggedUserID int64) error
}

type mealFriendTagRepository struct {
	db *gorm.DB
}

func NewMealFriendTagRepository(db *gorm.DB) MealFriendTagRepository {
	return &mealFriendTagRepository{db: db}
}

func (r *mealFriendTagRepository) Create(tag *domain.MealFriendTag) error {
	return r.db.Create(tag).Error
}

func (r *mealFriendTagRepository) AcceptTag(mealID int64, taggedUserID int64) error {
	result := r.db.Model(&domain.MealFriendTag{}).
		Where("meal_id = ? AND tagged_user_id = ? AND status = ?",
			mealID, taggedUserID, domain.FriendTagPending).
		Update("status", domain.FriendTagAccepted)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// ─────────────────────────────────────────
// upsertDailyIntake (트랜잭션 내부 전용)
// ─────────────────────────────────────────

// UpsertDailyIntakeInTx - usecase 트랜잭션 내에서 직접 호출하는 헬퍼
func UpsertDailyIntakeInTx(tx *gorm.DB, userID int64, dateKey string, n *domain.Nutrition) error {
	var existing domain.DailyIntake
	err := tx.
		Set("gorm:query_option", "FOR UPDATE").
		Where("user_id = ? AND date = ?", userID, dateKey).
		First(&existing).Error

	if errors.Is(err, gorm.ErrRecordNotFound) {
		newIntake := domain.DailyIntake{
			UserID:        userID,
			Date:          dateKey,
			TotalCalories: n.Calories,
			TotalCarbs:    n.Carbs,
			TotalProtein:  n.Protein,
			TotalFat:      n.Fat,
			TotalSodium:   n.Sodium,
			TotalFiber:    n.Fiber,
			VitaminScore:  n.VitaminScore,
			MealCount:     1,
		}
		return tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&newIntake).Error
	}
	if err != nil {
		return err
	}

	return tx.Model(&existing).Updates(map[string]interface{}{
		"total_calories": gorm.Expr("total_calories + ?", n.Calories),
		"total_carbs":    gorm.Expr("total_carbs + ?", n.Carbs),
		"total_protein":  gorm.Expr("total_protein + ?", n.Protein),
		"total_fat":      gorm.Expr("total_fat + ?", n.Fat),
		"total_sodium":   gorm.Expr("total_sodium + ?", n.Sodium),
		"total_fiber":    gorm.Expr("total_fiber + ?", n.Fiber),
		"meal_count":     gorm.Expr("meal_count + 1"),
	}).Error
}

// ─────────────────────────────────────────
// 날짜 경계 헬퍼 (05:00 KST 기준)
// ─────────────────────────────────────────

func MealDateKey(t time.Time) string {
	kst := time.FixedZone("KST", 9*60*60)
	local := t.In(kst)
	if local.Hour() < 5 {
		local = local.AddDate(0, 0, -1)
	}
	return local.Format("2006-01-02")
}
