package repository

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
)

// MealRepository 식사 기록 저장소 인터페이스
type MealRepository interface {
	// CountByUserID 사용자의 전체 식사 기록 수
	CountByUserID(userID int64) (int64, error)

	// CountDistinctMenuByUserID 사용자가 기록한 서로 다른 메뉴 수
	CountDistinctMenuByUserID(userID int64) (int64, error)
}

type mealRepositoryImpl struct {
	db *gorm.DB
}

func NewMealRepository(db *gorm.DB) MealRepository {
	return &mealRepositoryImpl{db: db}
}

func (r *mealRepositoryImpl) CountByUserID(userID int64) (int64, error) {
	var count int64
	if err := r.db.Model(&domain.MealRecord{}).
		Where("user_id = ?", userID).
		Count(&count).Error; err != nil {
		return 0, err
	}
	return count, nil
}

func (r *mealRepositoryImpl) CountDistinctMenuByUserID(userID int64) (int64, error) {
	var count int64
	if err := r.db.Model(&domain.MealRecord{}).
		Where("user_id = ?", userID).
		Distinct("menu_name").
		Count(&count).Error; err != nil {
		return 0, err
	}
	return count, nil
}
