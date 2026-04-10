package handler

import (
	"strconv"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/dto"
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
// @Success      200  {object}  Response  "메뉴 검색 성공"
// @Failure      400  {object}  Response  "잘못된 쿼리 파라미터"
// @Failure      401  {object}  Response  "인증 토큰 누락 또는 유효하지 않음"
// @Failure      500  {object}  Response  "서버 내부 에러"
// @Router       /menus/search [get]
func (h *MenuHandler) Search(c *gin.Context) {
	// 인증 확인
	//_, exists := c.Get("userID")
	//if !exists {
	//	Unauthorized(c, "UNAUTHORIZED", "인증 정보가 없습니다.")
	//	return
	//}

	// 쿼리 파라미터 바인딩
	var req dto.MenuSearchRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "잘못된 요청 형식입니다.", err.Error())
		return
	}

	// limit 기본값
	if req.Limit == 0 {
		req.Limit = 20
	}

	// cursor 파싱
	var cursor *int64
	if req.Cursor != "" {
		v, err := strconv.ParseInt(req.Cursor, 10, 64)
		if err != nil {
			BadRequest(c, "INVALID_PARAMETER", "cursor 값이 올바르지 않습니다.")
			return
		}
		cursor = &v
	}

	// category 파싱
	var category *domain.MenuCategory
	if req.Category != "" {
		mc := domain.MenuCategory(req.Category)
		category = &mc
	}

	result, err := h.menuUsecase.Search(c.Request.Context(), domain.SearchMenuQuery{
		Query:    req.Query,
		Category: category,
		Cursor:   cursor,
		Limit:    req.Limit,
	})
	if err != nil {
		InternalError(c, "메뉴 검색에 실패했습니다.")
		return
	}

	Success(c, result.Menus)
}
