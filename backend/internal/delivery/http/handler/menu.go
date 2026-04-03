package handler

import (
	"net/http"
	"strconv"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
)

// MenuHandler 메뉴 핸들러
type MenuHandler struct {
	menuUsecase usecase.MenuUsecase
}

// NewMenuHandler 메뉴 핸들러 생성
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
// @Success      200  {object}  Response
// @Failure      400  {object}  Response
// @Failure      401  {object}  Response
// @Failure      500  {object}  Response
// @Router       /api/menus/search [get]
func (h *MenuHandler) Search(c *gin.Context) {
	query := c.Query("query")
	if query == "" {
		BadRequest(c, "INVALID_PARAM", "query는 필수입니다.")
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
		InternalError(c, "메뉴 검색에 실패했습니다.", err.Error())
		return
	}

	// 성공 응답 (기존 Response 구조체 사용)
	c.JSON(http.StatusOK, Response{
		Success: true,
		Data:    result.Menus,
		Pagination: &Pagination{
			Limit:   result.Limit,
			HasNext: result.HasNext,
			// 커서 기반 페이지네이션의 경우 TotalCount를 생략할 수 있음
			// NextCursor 등 다른 정보를 보강할 수 있음
		},
	})
}
