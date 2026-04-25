package usecase

import (
	"context"
	"errors"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
	"gorm.io/gorm"
)

type PreferenceUsecase interface {
	// Set 선호도 설정 (이미 있으면 업데이트)
	Set(ctx context.Context, input domain.SetPreferenceInput) error

	// Remove 선호도 제거 (없으면 무시)
	Remove(ctx context.Context, userID, menuID int64) error
}

type preferenceUsecaseImpl struct {
	preferenceRepository repository.PreferenceRepository
	menuRepository       repository.MenuRepository
}

func NewPreferenceUsecase(
	preferenceRepository repository.PreferenceRepository,
	menuRepository repository.MenuRepository,
) PreferenceUsecase {
	return &preferenceUsecaseImpl{
		preferenceRepository: preferenceRepository,
		menuRepository:       menuRepository,
	}
}

func (u *preferenceUsecaseImpl) Set(ctx context.Context, input domain.SetPreferenceInput) error {
	// 메뉴 존재 확인
	menu, err := u.menuRepository.FindByID(input.MenuID)
	if err != nil {
		return err
	}
	if menu == nil {
		return errors.New("menu not found")
	}

	return u.preferenceRepository.Upsert(&domain.MenuPreference{
		UserID:     input.UserID,
		MenuID:     input.MenuID,
		Preference: input.Preference,
	})
}

func (u *preferenceUsecaseImpl) Remove(ctx context.Context, userID, menuID int64) error {
	err := u.preferenceRepository.Delete(userID, menuID)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil
	}
	return err
}
