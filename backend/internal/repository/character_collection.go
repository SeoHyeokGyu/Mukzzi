package repository

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
)

// CharacterCollectionRepository 먹찌 도감 저장소 인터페이스
type CharacterCollectionRepository interface {
	// CountByUserID 사용자가 달성한 외형 종류 수
	CountByUserID(userID int64) (int64, error)

	// FindByUserID 사용자가 달성한 외형 목록 조회
	FindByUserID(userID int64, limit, offset int) ([]domain.CharacterCollection, int64, error)
}

type characterCollectionRepositoryImpl struct {
	db *gorm.DB
}

func NewCharacterCollectionRepository(db *gorm.DB) CharacterCollectionRepository {
	return &characterCollectionRepositoryImpl{db: db}
}

func (r *characterCollectionRepositoryImpl) CountByUserID(userID int64) (int64, error) {
	var count int64
	if err := r.db.Model(&domain.CharacterCollection{}).
		Where("user_id = ?", userID).
		Count(&count).Error; err != nil {
		return 0, err
	}
	return count, nil
}

func (r *characterCollectionRepositoryImpl) FindByUserID(userID int64, limit, offset int) ([]domain.CharacterCollection, int64, error) {
	var collections []domain.CharacterCollection
	var total int64

	if err := r.db.Model(&domain.CharacterCollection{}).
		Where("user_id = ?", userID).
		Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if err := r.db.Where("user_id = ?", userID).
		Order("id DESC").
		Limit(limit).
		Offset(offset).
		Find(&collections).Error; err != nil {
		return nil, 0, err
	}

	return collections, total, nil
}
