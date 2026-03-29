package handler

import (
	"strconv"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/dto"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
)

// UserHandler 는 사용자 관련 HTTP 요청을 처리합니다.
type UserHandler struct {
	userUsecase usecase.UserUsecase
}

// NewUserHandler 는 UserHandler 의 새로운 인스턴스를 생성합니다.
func NewUserHandler(userUsecase usecase.UserUsecase) *UserHandler {
	return &UserHandler{userUsecase: userUsecase}
}

// GetMe 는 현재 로그인한 사용자의 프로필을 조회합니다.
func (h *UserHandler) GetMe(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		Unauthorized(c, "UNAUTHORIZED", "인증 정보가 없습니다.")
		return
	}

	user, err := h.userUsecase.GetProfile(userID.(int64))
	if err != nil {
		NotFound(c, "USER_NOT_FOUND", "사용자를 찾을 수 없습니다.")
		return
	}

	Success(c, user)
}

// GetProfile 은 특정 사용자의 프로필을 조회합니다.
func (h *UserHandler) GetProfile(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "잘못된 사용자 ID입니다.")
		return
	}

	user, err := h.userUsecase.GetProfile(id)
	if err != nil {
		NotFound(c, "USER_NOT_FOUND", "사용자를 찾을 수 없습니다.")
		return
	}

	Success(c, user)
}

// UpdateProfile 은 특정 사용자의 프로필 정보를 수정합니다.
func (h *UserHandler) UpdateProfile(c *gin.Context) {
	// 1. 요청 파라미터 확인
	idStr := c.Param("id")
	targetID, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "잘못된 사용자 ID입니다.")
		return
	}

	// 2. 본인 확인 (토큰의 userID와 수정하려는 targetID 비교)
	currentUserID, _ := c.Get("userID")
	if currentUserID.(int64) != targetID {
		Forbidden(c, "ACCESS_DENIED", "자신의 프로필만 수정할 수 있습니다.")
		return
	}

	var req dto.UserUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "잘못된 요청 형식입니다.", err.Error())
		return
	}

	// 3. 비즈니스 로직 수행
	user := &domain.User{
		Email:    req.Email,
		Nickname: req.Nickname,
		Password: req.Password,
	}
	user.ID = targetID

	if err := h.userUsecase.UpdateProfile(user); err != nil {
		InternalError(c, "프로필 수정에 실패했습니다.", err.Error())
		return
	}

	// 4. 응답 (비밀번호 제외한 최신 정보 조회)
	updatedUser, _ := h.userUsecase.GetProfile(targetID)
	Success(c, updatedUser)
}

// DeleteAccount 는 특정 사용자의 계정을 삭제합니다.
func (h *UserHandler) DeleteAccount(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "잘못된 사용자 ID입니다.")
		return
	}

	if err := h.userUsecase.DeleteAccount(id); err != nil {
		InternalError(c, "계정 삭제에 실패했습니다.", err.Error())
		return
	}

	Success(c, nil)
}
