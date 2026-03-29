package handler

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/dto"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
)

// AuthHandler 는 인증 관련 HTTP 요청을 처리합니다.
type AuthHandler struct {
	authUsecase usecase.AuthUsecase
}

// NewAuthHandler 는 AuthHandler 의 새로운 인스턴스를 생성합니다.
func NewAuthHandler(authUsecase usecase.AuthUsecase) *AuthHandler {
	return &AuthHandler{authUsecase: authUsecase}
}

// Register 는 사용자 회원가입을 처리합니다.
func (h *AuthHandler) Register(c *gin.Context) {
	var req dto.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "잘못된 요청 형식입니다.", err.Error())
		return
	}

	// DTO -> Domain Entity 변환
	user := &domain.User{
		Username: req.Username,
		Email:    req.Email,
		Password: req.Password,
		Nickname: req.Nickname,
	}

	createdUser, err := h.authUsecase.Register(user)
	if err != nil {
		InternalError(c, "회원가입에 실패했습니다.", err.Error())
		return
	}

	Created(c, createdUser)
}

// Login 은 사용자 로그인을 처리합니다.
func (h *AuthHandler) Login(c *gin.Context) {
	var req dto.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "아이디와 비밀번호를 모두 입력해주세요.")
		return
	}

	token, user, err := h.authUsecase.Login(req.Username, req.Password)
	if err != nil {
		Unauthorized(c, "LOGIN_FAILED", err.Error())
		return
	}

	Success(c, dto.LoginResponse{
		Token: token,
		User:  user,
	})
}
