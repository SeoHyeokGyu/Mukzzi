package repository

import (
	"errors"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

// ─────────────────────────────────────────
// MealRepository 인터페이스 (badge + meal_record 통합)
// ─────────────────────────────────────────

type MealRepository interface {
	// badge_granter에서 사용
	CountByUserID(userID int64) (int64, error)
	CountDistinctMenuByUserID(userID int64) (int64, error)

	// meal_record에서 사용
	Create(meal *domain.MealRecord) error
	FindByID(id int64) (*domain.MealRecord, error)
	FindByUserID(userID int64, filter domain.MealListFilter) ([]domain.MealRecord, int64, error)
	FindFriendMeals(friendIDs []int64, filter domain.MealListFilter) ([]domain.MealRecord, int64, error)
	Update(meal *domain.MealRecord) error
	Delete(id int64, userID int64) error
}

type mealRepository struct {
	db *gorm.DB
}

func NewMealRepository(db *gorm.DB) MealRepository {
	return &mealRepository{db: db}
}

// ── badge_granter 용 ──

func (r *mealRepository) CountByUserID(userID int64) (int64, error) {
	var count int64
	if err := r.db.Model(&domain.MealRecord{}).
		Where("user_id = ? AND deleted_at IS NULL", userID).
		Count(&count).Error; err != nil {
		return 0, err
	}
	return count, nil
}

func (r *mealRepository) CountDistinctMenuByUserID(userID int64) (int64, error) {
	var count int64
	if err := r.db.Model(&domain.MealRecord{}).
		Where("user_id = ? AND deleted_at IS NULL", userID).
		Distinct("menu_name").
		Count(&count).Error; err != nil {
		return 0, err
	}
	return count, nil
}

// ── meal_record 용 ──

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

func (r *mealRepository) FindFriendMeals(friendIDs []int64, filter domain.MealListFilter) ([]domain.MealRecord, int64, error) {
	if len(friendIDs) == 0 {
		return []domain.MealRecord{}, 0, nil
	}

	query := r.db.Model(&domain.MealRecord{}).
		Where("user_id IN ? AND deleted_at IS NULL", friendIDs)

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
		Preload("User").
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
	parsedDate, err := time.Parse(time.DateOnly, date)
	if err != nil {
		return nil, err
	}
	var di domain.DailyIntake
	err = r.db.Where("user_id = ? AND date = ?", userID, parsedDate).First(&di).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &di, err
}

func (r *nutritionRepository) FindWeeklyIntakes(userID int64, startDate string, endDate string) ([]domain.DailyIntake, error) {
	start, err := time.Parse(time.DateOnly, startDate)
	if err != nil {
		return nil, err
	}
	end, err := time.Parse(time.DateOnly, endDate)
	if err != nil {
		return nil, err
	}
	var intakes []domain.DailyIntake
	err = r.db.
		Where("user_id = ? AND date >= ? AND date <= ?", userID, start, end).
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
// UpsertDailyIntakeInTx (트랜잭션 내부 헬퍼)
// ─────────────────────────────────────────

func UpsertDailyIntakeInTx(tx *gorm.DB, userID int64, dateKey string, n *domain.Nutrition) error {
	parsedDate, err := time.Parse(time.DateOnly, dateKey)
	if err != nil {
		return err
	}

	var existing domain.DailyIntake
	err = tx.
		Set("gorm:query_option", "FOR UPDATE").
		Where("user_id = ? AND date = ?", userID, parsedDate).
		First(&existing).Error

	if errors.Is(err, gorm.ErrRecordNotFound) {
		newIntake := domain.DailyIntake{
			UserID:        userID,
			Date:          parsedDate,
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
// MealDateKey (05:00 KST 기준 날짜 헬퍼)
// ─────────────────────────────────────────

func MealDateKey(t time.Time) string {
	kst := time.FixedZone("KST", 9*60*60)
	local := t.In(kst)
	if local.Hour() < 5 {
		local = local.AddDate(0, 0, -1)
	}
	return local.Format(time.DateOnly)
}
