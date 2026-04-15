package usecase

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

// CharacterCollectionUsecase 먹찌 도감 유즈케이스 인터페이스
type CharacterCollectionUsecase interface {
	GetCharacterCollections(userID int64, page, limit int) ([]domain.CharacterCollection, int64, error)
}

type characterCollectionUsecaseImpl struct {
	repo repository.CharacterCollectionRepository
}

func NewCharacterCollectionUsecase(repo repository.CharacterCollectionRepository) CharacterCollectionUsecase {
	return &characterCollectionUsecaseImpl{repo: repo}
}

func (u *characterCollectionUsecaseImpl) GetCharacterCollections(userID int64, page, limit int) ([]domain.CharacterCollection, int64, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	if page <= 0 {
		page = 1
	}
	offset := (page - 1) * limit
	return u.repo.FindByUserID(userID, limit, offset)
}
