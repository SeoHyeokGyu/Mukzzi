package repository

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
)

type CharacterRepository interface {
	GetByUserID(userID int64) (*domain.Character, error)
	Update(character *domain.Character) error
}

type characterRepository struct {
	db *gorm.DB
}

func NewCharacterRepository(db *gorm.DB) CharacterRepository {
	return &characterRepository{db: db}
}

func (r *characterRepository) GetByUserID(userID int64) (*domain.Character, error) {
	var char domain.Character
	err := r.db.Where("user_id = ?", userID).First(&char).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &char, nil
}

func (r *characterRepository) Update(char *domain.Character) error {
	return r.db.Save(char).Error
}
