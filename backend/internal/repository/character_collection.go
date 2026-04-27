package repository

import (
	"errors"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
)

// CharacterCollectionRepository 먹찌 도감 저장소 인터페이스
type CharacterCollectionRepository interface {
	CountByUserID(userID int64) (int64, error)
	FindByUserID(userID int64, limit, offset int) ([]domain.CharacterCollection, int64, error)
	Create(collection *domain.CharacterCollection) error
	// RegisterIfNew 신규 외형 조합이면 도감에 등록. 반환값: 신규 등록 여부
	RegisterIfNew(userID int64, bodyType, muscle, skinTone, expression int) (bool, error)
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

func (r *characterCollectionRepositoryImpl) Create(collection *domain.CharacterCollection) error {
	return r.db.Create(collection).Error
}

func (r *characterCollectionRepositoryImpl) RegisterIfNew(userID int64, bodyType, muscle, skinTone, expression int) (bool, error) {
	var existing domain.CharacterCollection
	err := r.db.Where(&domain.CharacterCollection{
		UserID:     userID,
		BodyType:   bodyType,
		Muscle:     muscle,
		SkinTone:   skinTone,
		Expression: expression,
	}).First(&existing).Error

	if err == nil {
		return false, nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return false, err
	}

	col := &domain.CharacterCollection{
		UserID:     userID,
		BodyType:   bodyType,
		Muscle:     muscle,
		SkinTone:   skinTone,
		Expression: expression,
		AchievedAt: time.Now(),
	}
	return true, r.db.Create(col).Error
}
