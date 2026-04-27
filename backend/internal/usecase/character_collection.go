package usecase

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

// CharacterCollectionUsecase 먹찌 도감 유즈케이스 인터페이스
type CharacterCollectionUsecase interface {
	GetCharacterCollections(userID int64, page, limit int) ([]domain.CharacterCollection, int64, error)
	// RegisterAppearance 신규 외형 조합이면 도감에 등록. 반환값: 신규 등록 여부
	RegisterAppearance(userID int64, bodyType, muscle, skinTone, expression int) (bool, error)
}

type characterCollectionUsecaseImpl struct {
	repo repository.CharacterCollectionRepository
}

func NewCharacterCollectionUsecase(repo repository.CharacterCollectionRepository) CharacterCollectionUsecase {
	return &characterCollectionUsecaseImpl{repo: repo}
}

func (u *characterCollectionUsecaseImpl) RegisterAppearance(userID int64, bodyType, muscle, skinTone, expression int) (bool, error) {
	return u.repo.RegisterIfNew(userID, bodyType, muscle, skinTone, expression)
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
