package usecase

import (
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

// AuthUsecase 는 인증 관련 비즈니스 로직을 정의합니다.
type AuthUsecase interface {
	Register(user *domain.User) (*domain.User, error)
	Login(username, password string) (string, *domain.User, error)
}

type authUsecase struct {
	userRepo repository.UserRepository
}

// NewAuthUsecase 는 AuthUsecase 의 새로운 인스턴스를 생성합니다.
func NewAuthUsecase(userRepo repository.UserRepository) AuthUsecase {
	return &authUsecase{userRepo: userRepo}
}

// Register 는 새로운 사용자를 등록합니다.
func (u *authUsecase) Register(user *domain.User) (*domain.User, error) {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}
	user.Password = string(hashedPassword)

	if err := u.userRepo.Create(user); err != nil {
		return nil, err
	}

	return user, nil
}

// Login 은 사용자 인증을 수행하고 JWT 토큰을 반환합니다.
func (u *authUsecase) Login(username, password string) (string, *domain.User, error) {
	user, err := u.userRepo.GetByUsername(username)
	if err != nil {
		return "", nil, errors.New("아이디 또는 비밀번호가 일치하지 않습니다.")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password)); err != nil {
		return "", nil, errors.New("아이디 또는 비밀번호가 일치하지 않습니다.")
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": fmt.Sprintf("%d", user.ID),
		"exp":     time.Now().Add(time.Hour * 24).Unix(),
	})

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "mukzzi-secret"
	}

	tokenString, err := token.SignedString([]byte(jwtSecret))
	if err != nil {
		return "", nil, err
	}

	return tokenString, user, nil
}
