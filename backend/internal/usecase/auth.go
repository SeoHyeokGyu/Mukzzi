package usecase

import (
	"context"
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
	"github.com/golang-jwt/jwt/v5"
	"github.com/redis/go-redis/v9"
	"golang.org/x/crypto/bcrypt"
)

// AuthUsecase 는 인증 관련 비즈니스 로직을 정의합니다.
type AuthUsecase interface {
	Register(user *domain.User) (*domain.User, error)
	Login(username, email, password string) (string, string, *domain.User, error)
	Logout(userID string) error
}

type authUsecase struct {
	userRepo repository.UserRepository
	rdb      *redis.Client
}

// NewAuthUsecase 는 AuthUsecase 의 새로운 인스턴스를 생성합니다.
func NewAuthUsecase(userRepo repository.UserRepository, rdb *redis.Client) AuthUsecase {
	return &authUsecase{
		userRepo: userRepo,
		rdb:      rdb,
	}
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
func (u *authUsecase) Login(username, email, password string) (string, string, *domain.User, error) {
	var user *domain.User
	var err error

	if email != "" {
		user, err = u.userRepo.GetByEmail(email)
	} else {
		user, err = u.userRepo.GetByUsername(username)
	}

	if err != nil || user == nil {
		return "", "", nil, errors.New("아이디(이메일) 또는 비밀번호가 일치하지 않습니다.")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password)); err != nil {
		return "", "", nil, errors.New("아이디 또는 비밀번호가 일치하지 않습니다.")
	}

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "mukzzi-secret"
	}

	userIDStr := fmt.Sprintf("%d", user.ID)

	// Access Token (1시간)
	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": userIDStr,
		"exp":     time.Now().Add(time.Hour).Unix(),
	})
	accessTokenString, err := accessToken.SignedString([]byte(jwtSecret))
	if err != nil {
		return "", "", nil, err
	}

	// Refresh Token (14일)
	refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": userIDStr,
		"exp":     time.Now().Add(time.Hour * 24 * 14).Unix(),
	})
	refreshTokenString, err := refreshToken.SignedString([]byte(jwtSecret))
	if err != nil {
		return "", "", nil, err
	}

	// Redis에 Refresh Token 저장 (키: refresh_token:{user_id})
	ctx := context.Background()
	err = u.rdb.Set(ctx, fmt.Sprintf("refresh_token:%s", userIDStr), refreshTokenString, time.Hour*24*14).Err()
	if err != nil {
		return "", "", nil, err
	}

	return accessTokenString, refreshTokenString, user, nil
}

func (u *authUsecase) Logout(userID string) error {
	ctx := context.Background()
	return u.rdb.Del(ctx, fmt.Sprintf("refresh_token:%s", userID)).Err()
}
