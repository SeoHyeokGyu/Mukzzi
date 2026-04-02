package handler

import (
	"net/http"
	"strconv"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
)

type MenuHandler struct {
	menuUsecase usecase.MenuUsecase
}

func NewMenuHandler(menuUsecase usecase.MenuUsecase) *MenuHandler {
	return &MenuHandler{menuUsecase: menuUsecase}
}

// Search 메뉴 검색
// @Summary      메뉴 검색
// @Description  메뉴명으로 검색합니다. USER 소스 포함, 공식 소스 우선 정렬.
// @Tags         menus
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        query     query     string  true   "검색어"
// @Param        category  query     string  false  "카테고리 (KOREAN, CHINESE, JAPANESE, WESTERN, SNACK, CAFE, OTHER)"
// @Param        cursor    query     string  false  "다음 페이지 커서"
// @Param        limit     query     int     false  "페이지당 항목 수 (기본값: 20, 최대: 50)"
// @Success      200  {object}  ApiResponse
// @Failure      400  {object}  ApiResponse
// @Failure      401  {object}  ApiResponse
// @Failure      500  {object}  ApiResponse
// @Router       /api/v1/menus/search [get]
func (h *MenuHandler) Search(c *gin.Context) {
	query := c.Query("query")
	if query == "" {
		writeErrorResponse(c, http.StatusBadRequest, "INVALID_PARAM", "query는 필수입니다.")
		return
	}

	var category *domain.MenuCategory
	if cat := c.Query("category"); cat != "" {
		mc := domain.MenuCategory(cat)
		category = &mc
	}

	limit := 20
	if l := c.Query("limit"); l != "" {
		if v, err := strconv.Atoi(l); err == nil {
			limit = v
		}
	}

	var cursor *int64
	if cur := c.Query("cursor"); cur != "" {
		if v, err := strconv.ParseInt(cur, 10, 64); err == nil {
			cursor = &v
		}
	}

	result, err := h.menuUsecase.Search(c.Request.Context(), domain.SearchMenuQuery{
		Query:    query,
		Category: category,
		Cursor:   cursor,
		Limit:    limit,
	})
	if err != nil {
		writeErrorResponse(c, http.StatusInternalServerError, "SEARCH_FAILED", err.Error())
		return
	}

	writeSuccessResponse(c, http.StatusOK, map[string]interface{}{
		"data": result.Menus,
		"pagination": map[string]interface{}{
			"next_cursor": result.NextCursor,
			"has_next":    result.HasNext,
			"limit":       result.Limit,
		},
	})
}
