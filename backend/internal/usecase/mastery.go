package usecase

import (
	"fmt"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

// MasteryUsecase 마스터리 유즈케이스 인터페이스
type MasteryUsecase interface {
	GetMasteries(userID int64, page, limit int) ([]domain.Mastery, int64, error)
	GetMasteryByMenu(userID, menuID int64) (*domain.Mastery, error)
}

type masteryUsecaseImpl struct {
	masteryRepo repository.MasteryRepository
}

func NewMasteryUsecase(masteryRepo repository.MasteryRepository) MasteryUsecase {
	return &masteryUsecaseImpl{masteryRepo: masteryRepo}
}

func (u *masteryUsecaseImpl) GetMasteries(userID int64, page, limit int) ([]domain.Mastery, int64, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 50 {
		limit = 50
	}
	if page <= 0 {
		page = 1
	}
	offset := (page - 1) * limit

	masteries, total, err := u.masteryRepo.FindByUserID(userID, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("마스터리 목록 조회 실패: %w", err)
	}
	return masteries, total, nil
}

func (u *masteryUsecaseImpl) GetMasteryByMenu(userID, menuID int64) (*domain.Mastery, error) {
	mastery, err := u.masteryRepo.FindByUserIDAndMenuID(userID, menuID)
	if err != nil {
		return nil, fmt.Errorf("마스터리 조회 실패: %w", err)
	}
	return mastery, nil
}
