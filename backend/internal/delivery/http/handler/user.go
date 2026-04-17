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

// GetMe 현재 사용자 프로필 조회
// @Summary      현재 사용자 프로필 조회
// @Description  로그인한 현재 사용자의 프로필 정보를 조회합니다.
// @Tags         users
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  Response  "사용자 프로필 조회 성공"
// @Failure      401  {object}  Response  "인증 토큰 누락 또는 유효하지 않음"
// @Failure      404  {object}  Response  "사용자를 찾을 수 없습니다"
// @Failure      500  {object}  Response  "서버 내부 에러"
// @Router       /api/users/me [get]
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

// UpdateMe 내 프로필 정보 수정 (닉네임, 이미지 등)
// @Summary      내 프로필 정보 수정
// @Description  자신의 프로필 정보(닉네임, 이미지)를 수정합니다.
// @Tags         users
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        UserUpdateRequest   body      dto.UserUpdateRequest   true  "프로필 수정 정보"
// @Success      200  {object}  Response  "프로필 수정 성공"
// @Failure      400  {object}  Response  "잘못된 요청 형식"
// @Failure      401  {object}  Response  "인증 정보 없음"
// @Failure      500  {object}  Response  "서버 내부 에러"
// @Router       /api/users/me [patch]
func (h *UserHandler) UpdateMe(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req dto.UserUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "잘못된 요청 형식입니다.", err.Error())
		return
	}

	if err := h.userUsecase.UpdateProfile(userID.(int64), req.Nickname, req.ProfileImageURL); err != nil {
		InternalError(c, "프로필 수정에 실패했습니다.", err.Error())
		return
	}

	updatedUser, err := h.userUsecase.GetProfile(userID.(int64))
	if err != nil {
		InternalError(c, "프로필 조회에 실패했습니다.", err.Error())
		return
	}
	Success(c, updatedUser)
}

// UpdateBody 신체 정보 수정
// @Summary      신체 정보 수정
// @Description  키, 몸무게, 활동량 등의 신체 정보를 수정합니다.
// @Tags         users
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        UserBodyUpdateRequest   body      dto.UserBodyUpdateRequest   true  "신체 정보 수정 정보"
// @Success      200  {object}  Response  "신체 정보 수정 성공"
// @Failure      400  {object}  Response  "잘못된 요청 형식"
// @Router       /api/users/me/body [patch]
func (h *UserHandler) UpdateBody(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req dto.UserBodyUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "잘못된 요청 형식입니다.", err.Error())
		return
	}

	if err := h.userUsecase.UpdateBody(userID.(int64), req.Height, req.Weight, req.ActivityLevel); err != nil {
		InternalError(c, "신체 정보 수정에 실패했습니다.", err.Error())
		return
	}

	updatedUser, err := h.userUsecase.GetProfile(userID.(int64))
	if err != nil {
		InternalError(c, "프로필 조회에 실패했습니다.", err.Error())
		return
	}
	Success(c, updatedUser)
}

// UpdateNutritionGoal 영양 목표 재설정
// @Summary      영양 목표 재설정
// @Description  목표(다이어트, 유지, 벌크업)를 재설정하고 권장 섭취량을 재계산합니다.
// @Tags         users
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        UserNutritionGoalUpdateRequest   body      dto.UserNutritionGoalUpdateRequest   true  "영양 목표 수정 정보"
// @Success      200  {object}  Response  "영양 목표 수정 성공"
// @Router       /api/users/me/nutrition-goal [patch]
func (h *UserHandler) UpdateNutritionGoal(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req dto.UserNutritionGoalUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "잘못된 요청 형식입니다.", err.Error())
		return
	}

	if err := h.userUsecase.UpdateNutritionGoal(userID.(int64), domain.DietGoal(req.Goal)); err != nil {
		InternalError(c, "영양 목표 수정에 실패했습니다.", err.Error())
		return
	}

	updatedUser, err := h.userUsecase.GetProfile(userID.(int64))
	if err != nil {
		InternalError(c, "프로필 조회에 실패했습니다.", err.Error())
		return
	}
	Success(c, updatedUser)
}

// UpdateSettings 설정 변경
// @Summary      설정 변경
// @Description  알림 설정, 프라이버시 레벨 등의 설정을 변경합니다.
// @Tags         users
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        UserSettingsUpdateRequest   body      dto.UserSettingsUpdateRequest   true  "설정 수정 정보"
// @Success      200  {object}  Response  "설정 수정 성공"
// @Router       /api/users/me/settings [patch]
func (h *UserHandler) UpdateSettings(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req dto.UserSettingsUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "잘못된 요청 형식입니다.", err.Error())
		return
	}

	if err := h.userUsecase.UpdateSettings(userID.(int64), req.PrivacyLevel, req.NotificationSettings); err != nil {
		InternalError(c, "설정 수정에 실패했습니다.", err.Error())
		return
	}

	updatedUser, err := h.userUsecase.GetProfile(userID.(int64))
	if err != nil {
		InternalError(c, "프로필 조회에 실패했습니다.", err.Error())
		return
	}
	Success(c, updatedUser)
}

// WithdrawAccount 회원 탈퇴
// @Summary      회원 탈퇴
// @Description  계정을 삭제합니다. 삭제된 계정은 복구할 수 없습니다.
// @Tags         users
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  Response  "회원 탈퇴 성공"
// @Router       /api/users/me [delete]
func (h *UserHandler) WithdrawAccount(c *gin.Context) {
	userID, _ := c.Get("userID")

	if err := h.userUsecase.DeleteAccount(userID.(int64)); err != nil {
		InternalError(c, "회원 탈퇴에 실패했습니다.", err.Error())
		return
	}

	Success(c, nil)
}

// GetOtherProfile 타인 프로필 정보 조회
// @Summary      타인 프로필 정보 조회
// @Description  특정 사용자의 프로필 정보를 조회합니다.
// @Tags         users
// @Accept       json
// @Produce      json
// @Param        id   path      int64   true  "사용자 ID"
// @Success      200  {object}  Response  "프로필 조회 성공"
// @Router       /api/users/{id}/profile [get]
func (h *UserHandler) GetOtherProfile(c *gin.Context) {
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

	// 타인 프로필이므로 민감 정보는 제외한 DTO로 반환하는 것이 좋음
	res := dto.UserProfileResponse{
		ID:              user.ID,
		Nickname:        user.Nickname,
		ProfileImageURL: user.ProfileImageURL,
		PrivacyLevel:    user.PrivacyLevel,
	}

	Success(c, res)
}

// Search 사용자 검색
// @Summary      사용자 검색
// @Description  닉네임 또는 고유 ID로 사용자를 검색합니다.
// @Tags         users
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        query   query     string  true  "검색어 (닉네임 등)"
// @Success      200  {object}  Response  "사용자 검색 성공"
// @Router       /api/users/search [get]
func (h *UserHandler) Search(c *gin.Context) {
	query := c.Query("query")
	if query == "" {
		BadRequest(c, "INVALID_QUERY", "검색어를 입력해주세요.")
		return
	}

	users, err := h.userUsecase.Search(query)
	if err != nil {
		InternalError(c, "사용자 검색에 실패했습니다.", err.Error())
		return
	}

	Success(c, users)
}

// GetRecommendations 추천 사용자 목록
// @Summary      추천 사용자 목록
// @Description  비슷한 식습관이나 인기가 있는 추천 사용자 목록을 조회합니다.
// @Tags         users
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  Response  "추천 사용자 조회 성공"
// @Router       /api/users/recommendations [get]
func (h *UserHandler) GetRecommendations(c *gin.Context) {
	userID, _ := c.Get("userID")

	recommendations, err := h.userUsecase.GetRecommendations(userID.(int64))
	if err != nil {
		InternalError(c, "추천 사용자 목록 조회에 실패했습니다.", err.Error())
		return
	}

	Success(c, recommendations)
}

// Deprecated: GetProfile 은 GetOtherProfile 로 대체됩니다.
func (h *UserHandler) GetProfile(c *gin.Context) {
	h.GetOtherProfile(c)
}

// Deprecated: UpdateProfile 은 UpdateMe 로 대체됩니다.
func (h *UserHandler) UpdateProfile(c *gin.Context) {
	h.UpdateMe(c)
}

// Deprecated: DeleteAccount 는 WithdrawAccount 로 대체됩니다.
func (h *UserHandler) DeleteAccount(c *gin.Context) {
	h.WithdrawAccount(c)
}
