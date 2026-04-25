package handler

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/dto"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
)

type PreferenceHandler struct {
	preferenceUsecase usecase.PreferenceUsecase
}

func NewPreferenceHandler(preferenceUsecase usecase.PreferenceUsecase) *PreferenceHandler {
	return &PreferenceHandler{preferenceUsecase: preferenceUsecase}
}

// Set 선호도 설정
// @Summary      선호도 설정
// @Description  메뉴에 좋아요(LIKE) 또는 싫어요(DISLIKE)를 설정합니다. 이미 있으면 업데이트됩니다.
// @Tags         menus
// @Security     BearerAuth
// @Param        id       path  string                    true  "메뉴 ID"
// @Param        request  body  dto.SetPreferenceRequest  true  "선호도"
// @Success      200  {object}  Response  "선호도 설정 성공"
// @Failure      400  {object}  Response  "잘못된 요청"
// @Failure      401  {object}  Response  "인증 토큰 누락 또는 유효하지 않음"
// @Failure      404  {object}  Response  "메뉴를 찾을 수 없음"
// @Failure      500  {object}  Response  "서버 내부 에러"
// @Router       /menus/{id}/preferences [post]
func (h *PreferenceHandler) Set(c *gin.Context) {
	userID, _ := c.Get("userID")
	menuID, err := parseMenuID(c)
	if err != nil {
		return
	}

	var req dto.SetPreferenceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "잘못된 요청 형식입니다.", err.Error())
		return
	}

	if err := h.preferenceUsecase.Set(c.Request.Context(), domain.SetPreferenceInput{
		UserID:     userID.(int64),
		MenuID:     menuID,
		Preference: domain.PreferenceType(req.Preference),
	}); err != nil {
		if err.Error() == "menu not found" {
			NotFound(c, "MENU_NOT_FOUND", "해당 메뉴를 찾을 수 없습니다.")
			return
		}
		InternalError(c, "선호도 설정에 실패했습니다.")
		return
	}

	Success(c, nil)
}

// Remove 선호도 제거
// @Summary      선호도 제거
// @Tags         menus
// @Security     BearerAuth
// @Param        id   path  string  true  "메뉴 ID"
// @Success      200  {object}  Response  "선호도 제거 성공 (없어도 200)"
// @Failure      400  {object}  Response  "잘못된 ID 형식"
// @Failure      401  {object}  Response  "인증 토큰 누락 또는 유효하지 않음"
// @Failure      500  {object}  Response  "서버 내부 에러"
// @Router       /menus/{id}/preferences [delete]
func (h *PreferenceHandler) Remove(c *gin.Context) {
	userID, _ := c.Get("userID")
	menuID, err := parseMenuID(c)
	if err != nil {
		return
	}

	if err := h.preferenceUsecase.Remove(c.Request.Context(), userID.(int64), menuID); err != nil {
		InternalError(c, "선호도 제거에 실패했습니다.")
		return
	}

	Success(c, nil)
}
