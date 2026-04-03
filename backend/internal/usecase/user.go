package usecase

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
	"golang.org/x/crypto/bcrypt"
)

// UserUsecase 인터페이스는 사용자 프로필 관련 비즈니스 로직을 정의합니다.
type UserUsecase interface {
	GetProfile(id int64) (*domain.User, error)
	UpdateProfile(user *domain.User) error
	DeleteAccount(id int64) error
}

type userUsecase struct {
	userRepo repository.UserRepository
}

// NewUserUsecase 는 UserUsecase 인터페이스의 구현체를 반환합니다.
func NewUserUsecase(userRepo repository.UserRepository) UserUsecase {
	return &userUsecase{userRepo: userRepo}
}

func (u *userUsecase) GetProfile(id int64) (*domain.User, error) {
	user, err := u.userRepo.GetByID(id)
	if err != nil {
		return nil, err
	}
	user.Password = ""
	return user, nil
}

func (u *userUsecase) UpdateProfile(user *domain.User) error {
	// 기존 사용자 정보 조회
	existingUser, err := u.userRepo.GetByID(user.ID)
	if err != nil {
		return err
	}

	// 변경 사항 적용
	if user.Email != "" {
		existingUser.Email = user.Email
	}
	if user.Nickname != "" {
		existingUser.Nickname = user.Nickname
	}

	// 비밀번호 업데이트 요청이 있는 경우 해싱 처리
	if user.Password != "" {
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
		if err != nil {
			return err
		}
		existingUser.Password = string(hashedPassword)
	}

	return u.userRepo.Update(existingUser)
}

func (u *userUsecase) DeleteAccount(id int64) error {
	return u.userRepo.Delete(id)
}
