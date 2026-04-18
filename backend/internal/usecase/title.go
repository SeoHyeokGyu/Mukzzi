package usecase

import (
	"errors"
	"fmt"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

var ErrTitleNotOwned = errors.New("보유하지 않은 칭호입니다")

// TitleUsecase 칭호 유즈케이스 인터페이스
type TitleUsecase interface {
	GetTitles(userID int64) ([]domain.Title, map[int64]*domain.UserTitle, *int64, error)
	EquipTitle(userID int64, titleID *int64) error
}

type titleUsecaseImpl struct {
	titleRepo repository.TitleRepository
	userRepo  repository.UserRepository
}

func NewTitleUsecase(titleRepo repository.TitleRepository, userRepo repository.UserRepository) TitleUsecase {
	return &titleUsecaseImpl{
		titleRepo: titleRepo,
		userRepo:  userRepo,
	}
}

func (u *titleUsecaseImpl) GetTitles(userID int64) ([]domain.Title, map[int64]*domain.UserTitle, *int64, error) {
	titles, err := u.titleRepo.FindAll()
	if err != nil {
		return nil, nil, nil, fmt.Errorf("칭호 목록 조회 실패: %w", err)
	}

	userTitles, err := u.titleRepo.FindUserTitles(userID)
	if err != nil {
		return nil, nil, nil, fmt.Errorf("사용자 칭호 조회 실패: %w", err)
	}

	acquiredMap := make(map[int64]*domain.UserTitle, len(userTitles))
	for i := range userTitles {
		acquiredMap[userTitles[i].TitleID] = &userTitles[i]
	}

	user, err := u.userRepo.GetByID(userID)
	if err != nil {
		return nil, nil, nil, fmt.Errorf("사용자 정보 조회 실패: %w", err)
	}

	return titles, acquiredMap, user.EquippedTitleID, nil
}

func (u *titleUsecaseImpl) EquipTitle(userID int64, titleID *int64) error {
	if titleID == nil {
		return u.userRepo.UpdateEquippedTitle(userID, nil)
	}

	userTitle, err := u.titleRepo.FindUserTitleByID(userID, *titleID)
	if err != nil {
		return fmt.Errorf("칭호 정보 조회 실패: %w", err)
	}
	if userTitle == nil {
		return ErrTitleNotOwned
	}

	return u.userRepo.UpdateEquippedTitle(userID, titleID)
}
