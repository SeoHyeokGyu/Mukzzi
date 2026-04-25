package repository

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
)

type PreferenceRepository interface {
	// FindByUserIDAndMenuID 선호도 단건 조회 (없으면 nil)
	FindByUserIDAndMenuID(userID, menuID int64) (*domain.MenuPreference, error)

	// Upsert 선호도 등록 또는 업데이트
	Upsert(pref *domain.MenuPreference) error

	// Delete 선호도 제거
	Delete(userID, menuID int64) error
}

type preferenceRepositoryImpl struct {
	db *gorm.DB
}

func NewPreferenceRepository(db *gorm.DB) PreferenceRepository {
	return &preferenceRepositoryImpl{db: db}
}

func (r *preferenceRepositoryImpl) FindByUserIDAndMenuID(userID, menuID int64) (*domain.MenuPreference, error) {
	var pref domain.MenuPreference
	if err := r.db.
		Where("user_id = ? AND menu_id = ?", userID, menuID).
		First(&pref).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &pref, nil
}

func (r *preferenceRepositoryImpl) Upsert(pref *domain.MenuPreference) error {
	// soft delete된 레코드 포함해서 조회
	var existing domain.MenuPreference
	err := r.db.Unscoped().
		Where("user_id = ? AND menu_id = ?", pref.UserID, pref.MenuID).
		First(&existing).Error

	if err == gorm.ErrRecordNotFound {
		// 완전히 새 레코드
		return r.db.Create(pref).Error
	}
	if err != nil {
		return err
	}

	// soft delete된 레코드면 복구하면서 preference 값 업데이트
	return r.db.Unscoped().Model(&existing).Updates(map[string]interface{}{
		"deleted_at": nil,
		"preference": pref.Preference,
	}).Error
}

func (r *preferenceRepositoryImpl) Delete(userID, menuID int64) error {
	result := r.db.
		Where("user_id = ? AND menu_id = ?", userID, menuID).
		Delete(&domain.MenuPreference{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
