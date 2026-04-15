package repository

import (
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

// MasteryRepository 마스터리 저장소 인터페이스
type MasteryRepository interface {
	// FindByUserID 사용자의 마스터리 목록 조회
	FindByUserID(userID int64, limit, offset int) ([]domain.Mastery, int64, error)

	// FindByUserIDAndMenuID 특정 메뉴의 마스터리 조회
	FindByUserIDAndMenuID(userID, menuID int64) (*domain.Mastery, error)

	// Upsert 마스터리 생성 또는 eat_count/grade 갱신
	Upsert(userID, menuID int64, now time.Time) (*domain.Mastery, error)
}

type masteryRepositoryImpl struct {
	db *gorm.DB
}

func NewMasteryRepository(db *gorm.DB) MasteryRepository {
	return &masteryRepositoryImpl{db: db}
}

func (r *masteryRepositoryImpl) FindByUserID(userID int64, limit, offset int) ([]domain.Mastery, int64, error) {
	var masteries []domain.Mastery
	var total int64

	if err := r.db.Model(&domain.Mastery{}).
		Where("user_id = ?", userID).
		Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if err := r.db.Preload("Menu").
		Where("user_id = ?", userID).
		Order("eat_count DESC").
		Limit(limit).
		Offset(offset).
		Find(&masteries).Error; err != nil {
		return nil, 0, err
	}

	return masteries, total, nil
}

func (r *masteryRepositoryImpl) FindByUserIDAndMenuID(userID, menuID int64) (*domain.Mastery, error) {
	var mastery domain.Mastery
	if err := r.db.Preload("Menu").
		Where("user_id = ? AND menu_id = ?", userID, menuID).
		First(&mastery).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &mastery, nil
}

// Upsert eat_count를 1 증가시키고 grade를 갱신합니다. SELECT FOR UPDATE로 동시성을 제어합니다.
func (r *masteryRepositoryImpl) Upsert(userID, menuID int64, now time.Time) (*domain.Mastery, error) {
	var mastery domain.Mastery

	err := r.db.Transaction(func(tx *gorm.DB) error {
		// 비관적 잠금으로 기존 레코드 조회
		result := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
			Where("user_id = ? AND menu_id = ?", userID, menuID).
			First(&mastery)

		if result.Error == gorm.ErrRecordNotFound {
			// 신규 생성
			mastery = domain.Mastery{
				UserID:       userID,
				MenuID:       menuID,
				EatCount:     1,
				Grade:        domain.CalcMasteryGrade(1),
				FirstEatenAt: now,
				LastEatenAt:  now,
			}
			return tx.Create(&mastery).Error
		}
		if result.Error != nil {
			return result.Error
		}

		// 기존 레코드 갱신
		mastery.EatCount++
		mastery.Grade = domain.CalcMasteryGrade(mastery.EatCount)
		mastery.LastEatenAt = now
		return tx.Save(&mastery).Error
	})

	if err != nil {
		return nil, err
	}
	return &mastery, nil
}
