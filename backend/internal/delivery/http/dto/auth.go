package dto

import "github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"

// LoginRequest 는 로그인 요청 데이터를 정의합니다.
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// LoginResponse 는 로그인 성공 시 응답 데이터를 정의합니다.
type LoginResponse struct {
	Token string       `json:"token"`
	User  *domain.User `json:"user"`
}

// RegisterRequest 는 회원가입 요청 데이터를 정의합니다.
type RegisterRequest struct {
	Username string `json:"username" binding:"required"`
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
	Nickname string `json:"nickname"`
}
