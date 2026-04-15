package usecase

import (
	"fmt"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

// MasteryError 마스터리 관련 에러
type MasteryError struct {
	Code    string
	Message string
	Details string
}

func (e *MasteryError) Error() string {
	return fmt.Sprintf("[%s] %s: %s", e.Code, e.Message, e.Details)
}

// MasteryUsecase 마스터리 유즈케이스 인터페이스
type MasteryUsecase interface {
	// GetMasteries 사용자의 마스터리 목록 조회
	GetMasteries(userID int64, page, limit int) ([]domain.Mastery, int64, error)

	// GetMasteryByMenu 특정 메뉴의 마스터리 상세 조회
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
		return nil, 0, &MasteryError{
			Code:    "MASTERY_FETCH_ERROR",
			Message: "마스터리 목록을 조회하는 중에 오류가 발생했습니다.",
			Details: err.Error(),
		}
	}
	return masteries, total, nil
}

func (u *masteryUsecaseImpl) GetMasteryByMenu(userID, menuID int64) (*domain.Mastery, error) {
	mastery, err := u.masteryRepo.FindByUserIDAndMenuID(userID, menuID)
	if err != nil {
		return nil, &MasteryError{
			Code:    "MASTERY_FETCH_ERROR",
			Message: "마스터리 정보를 조회하는 중에 오류가 발생했습니다.",
			Details: err.Error(),
		}
	}
	return mastery, nil
}
