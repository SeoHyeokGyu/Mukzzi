package handler

import (
	"strconv"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/dto"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
)

type FavoriteHandler struct {
	favoriteUsecase usecase.FavoriteUsecase
}

func NewFavoriteHandler(favoriteUsecase usecase.FavoriteUsecase) *FavoriteHandler {
	return &FavoriteHandler{favoriteUsecase: favoriteUsecase}
}

// Add 즐겨찾기 추가
// @Summary      즐겨찾기 추가
// @Tags         menus
// @Security     BearerAuth
// @Param        id   path  string  true  "메뉴 ID"
// @Success      200  {object}  Response  "즐겨찾기 추가 성공 (이미 있어도 200)"
// @Failure      400  {object}  Response  "잘못된 ID 형식"
// @Failure      401  {object}  Response  "인증 토큰 누락 또는 유효하지 않음"
// @Failure      404  {object}  Response  "메뉴를 찾을 수 없음"
// @Failure      500  {object}  Response  "서버 내부 에러"
// @Router       /menus/{id}/favorites [post]
func (h *FavoriteHandler) Add(c *gin.Context) {
	userID, _ := c.Get("userID")
	menuID, err := parseMenuID(c)
	if err != nil {
		return
	}

	if err := h.favoriteUsecase.Add(c.Request.Context(), userID.(int64), menuID); err != nil {
		if err.Error() == "menu not found" {
			NotFound(c, "MENU_NOT_FOUND", "해당 메뉴를 찾을 수 없습니다.")
			return
		}
		InternalError(c, "즐겨찾기 추가에 실패했습니다.")
		return
	}

	Success(c, nil)
}

// Remove 즐겨찾기 제거
// @Summary      즐겨찾기 제거
// @Tags         menus
// @Security     BearerAuth
// @Param        id   path  string  true  "메뉴 ID"
// @Success      200  {object}  Response  "즐겨찾기 제거 성공 (없어도 200)"
// @Failure      400  {object}  Response  "잘못된 ID 형식"
// @Failure      401  {object}  Response  "인증 토큰 누락 또는 유효하지 않음"
// @Failure      500  {object}  Response  "서버 내부 에러"
// @Router       /menus/{id}/favorites [delete]
func (h *FavoriteHandler) Remove(c *gin.Context) {
	userID, _ := c.Get("userID")
	menuID, err := parseMenuID(c)
	if err != nil {
		return
	}

	if err := h.favoriteUsecase.Remove(c.Request.Context(), userID.(int64), menuID); err != nil {
		InternalError(c, "즐겨찾기 제거에 실패했습니다.")
		return
	}

	Success(c, nil)
}

// GetList 즐겨찾기 목록 조회
// @Summary      즐겨찾기 목록 조회
// @Tags         menus
// @Security     BearerAuth
// @Param        cursor  query  string  false  "다음 페이지 커서"
// @Param        limit   query  int     false  "페이지당 항목 수 (기본값: 20, 최대: 50)"
// @Success      200  {object}  Response  "즐겨찾기 목록 조회 성공"
// @Failure      401  {object}  Response  "인증 토큰 누락 또는 유효하지 않음"
// @Failure      500  {object}  Response  "서버 내부 에러"
// @Router       /menus/favorites [get]
func (h *FavoriteHandler) GetList(c *gin.Context) {
	userID, _ := c.Get("userID")

	var cursor *int64
	if cursorStr := c.Query("cursor"); cursorStr != "" {
		v, err := strconv.ParseInt(cursorStr, 10, 64)
		if err != nil {
			BadRequest(c, "INVALID_PARAMETER", "cursor 값이 올바르지 않습니다.")
			return
		}
		cursor = &v
	}

	limit := 20
	if limitStr := c.Query("limit"); limitStr != "" {
		v, err := strconv.Atoi(limitStr)
		if err != nil || v <= 0 {
			BadRequest(c, "INVALID_PARAMETER", "limit 값이 올바르지 않습니다.")
			return
		}
		limit = v
	}

	result, err := h.favoriteUsecase.GetList(c.Request.Context(), domain.GetFavoritesQuery{
		UserID: userID.(int64),
		Cursor: cursor,
		Limit:  limit,
	})
	if err != nil {
		InternalError(c, "즐겨찾기 목록 조회에 실패했습니다.")
		return
	}

	nextCursor := ""
	if result.NextCursor != nil {
		nextCursor = *result.NextCursor
	}

	responses := make([]dto.FavoriteResponse, len(result.Favorites))
	for i, f := range result.Favorites {
		responses[i] = dto.FavoriteResponse{
			ID:   f.ID,
			Menu: toMenuResponse(f.Menu),
		}
	}

	CursorPaginated(c, responses, result.Limit, result.HasNext, nextCursor)
}

// parseMenuID path parameter :id를 int64로 파싱, 실패 시 BadRequest 응답 후 에러 반환
func parseMenuID(c *gin.Context) (int64, error) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_PARAMETER", "id 값이 올바르지 않습니다.")
		return 0, err
	}
	return id, nil
}
