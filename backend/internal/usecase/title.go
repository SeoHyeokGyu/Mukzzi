package usecase

import (
	"errors"
	"fmt"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

// TitleError 칭호 관련 에러
type TitleError struct {
	Code    string
	Message string
	Details string
}

func (e *TitleError) Error() string {
	return fmt.Sprintf("[%s] %s: %s", e.Code, e.Message, e.Details)
}

// ErrTitleNotOwned 보유하지 않은 칭호 장착 시도
var ErrTitleNotOwned = errors.New("보유하지 않은 칭호입니다")

// TitleUsecase 칭호 유즈케이스 인터페이스
type TitleUsecase interface {
	// GetTitles 전체 칭호 목록 조회 (획득/미획득 포함)
	GetTitles(userID int64) ([]domain.Title, map[int64]*domain.UserTitle, *int64, error)

	// EquipTitle 칭호 장착 또는 해제 (titleID nil이면 해제)
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
		return nil, nil, nil, &TitleError{
			Code:    "TITLE_FETCH_ERROR",
			Message: "칭호 목록을 조회하는 중에 오류가 발생했습니다.",
			Details: err.Error(),
		}
	}

	userTitles, err := u.titleRepo.FindUserTitles(userID)
	if err != nil {
		return nil, nil, nil, &TitleError{
			Code:    "USER_TITLE_FETCH_ERROR",
			Message: "사용자의 칭호 정보를 조회하는 중에 오류가 발생했습니다.",
			Details: err.Error(),
		}
	}

	acquiredMap := make(map[int64]*domain.UserTitle, len(userTitles))
	for i := range userTitles {
		acquiredMap[userTitles[i].TitleID] = &userTitles[i]
	}

	// 현재 장착 중인 칭호 ID
	user, err := u.userRepo.GetByID(userID)
	if err != nil {
		return nil, nil, nil, &TitleError{
			Code:    "USER_FETCH_ERROR",
			Message: "사용자 정보를 조회하는 중에 오류가 발생했습니다.",
			Details: err.Error(),
		}
	}

	return titles, acquiredMap, user.EquippedTitleID, nil
}

func (u *titleUsecaseImpl) EquipTitle(userID int64, titleID *int64) error {
	// 해제 요청이면 바로 처리
	if titleID == nil {
		return u.userRepo.UpdateEquippedTitle(userID, nil)
	}

	// 보유 여부 확인
	userTitle, err := u.titleRepo.FindUserTitleByID(userID, *titleID)
	if err != nil {
		return &TitleError{
			Code:    "TITLE_FETCH_ERROR",
			Message: "칭호 정보를 조회하는 중에 오류가 발생했습니다.",
			Details: err.Error(),
		}
	}
	if userTitle == nil {
		return ErrTitleNotOwned
	}

	return u.userRepo.UpdateEquippedTitle(userID, titleID)
}
