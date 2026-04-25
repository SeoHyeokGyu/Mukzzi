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
// @Tags         menus
// @Security     BearerAuth
// @Param        query     query  string  true   "검색어"
// @Param        category  query  string  false  "카테고리"
// @Param        cursor    query  string  false  "커서"
// @Param        limit     query  int     false  "페이지당 항목 수"
// @Success      200  {object}  Response
// @Router       /menus/search [get]
func (h *MenuHandler) Search(c *gin.Context) {
	var req dto.MenuSearchRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "잘못된 요청 형식입니다.", err.Error())
		return
	}

	if req.Limit == 0 {
		req.Limit = 20
	}

	var cursor *int64
	if req.Cursor != "" {
		v, err := strconv.ParseInt(req.Cursor, 10, 64)
		if err != nil {
			BadRequest(c, "INVALID_PARAMETER", "cursor 값이 올바르지 않습니다.")
			return
		}
		cursor = &v
	}

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

	nextCursor := ""
	if result.NextCursor != nil {
		nextCursor = *result.NextCursor
	}

	responses := make([]dto.MenuResponse, len(result.Menus))
	for i, m := range result.Menus {
		responses[i] = toMenuResponse(m)
	}

	CursorPaginated(c, responses, result.Limit, result.HasNext, nextCursor)
}

// Create 사용자 정의 메뉴 등록
// @Summary      사용자 정의 메뉴 등록
// @Tags         menus
// @Security     BearerAuth
// @Param        request  body  dto.MenuCreateRequest  true  "메뉴 등록 정보"
// @Success      201  {object}  Response
// @Router       /menus [post]
func (h *MenuHandler) Create(c *gin.Context) {
	var req dto.MenuCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "잘못된 요청 형식입니다.", err.Error())
		return
	}

	menu, created, err := h.menuUsecase.Create(c.Request.Context(), domain.CreateMenuInput{
		Name:     req.Name,
		Category: domain.MenuCategory(req.Category),
		Calories: req.Calories,
		Carbs:    req.Carbs,
		Protein:  req.Protein,
		Fat:      req.Fat,
		Fiber:    req.Fiber,
	})
	if err != nil {
		InternalError(c, "메뉴 등록에 실패했습니다.")
		return
	}
	if !created {
		BadRequest(c, "DUPLICATE_MENU", "동일한 이름과 카테고리의 메뉴가 이미 존재합니다.")
		return
	}

	Created(c, toMenuResponse(*menu))
}

// FindByID 단일 메뉴 상세 조회
// @Summary      메뉴 상세 조회
// @Tags         menus
// @Security     BearerAuth
// @Param        id  path  string  true  "메뉴 ID"
// @Success      200  {object}  Response
// @Failure      404  {object}  Response
// @Router       /menus/{id} [get]
func (h *MenuHandler) FindByID(c *gin.Context) {
	userID, _ := c.Get("userID")

	menuID, err := parseMenuID(c)
	if err != nil {
		return
	}

	detail, err := h.menuUsecase.FindByID(c.Request.Context(), menuID, userID.(int64))
	if err != nil {
		InternalError(c, "메뉴 조회에 실패했습니다.")
		return
	}
	if detail == nil {
		NotFound(c, "MENU_NOT_FOUND", "해당 메뉴를 찾을 수 없습니다.")
		return
	}

	menuResp := toMenuResponse(detail.Menu)
	resp := dto.MenuDetailResponse{
		MenuResponse: menuResp,
		IsFavorite:   detail.IsFavorite,
	}
	if detail.Preference != nil {
		s := string(*detail.Preference)
		resp.Preference = &s
	}
	Success(c, resp)
}

// toMenuResponse domain.Menu → dto.MenuResponse 변환
func toMenuResponse(m domain.Menu) dto.MenuResponse {
	return dto.MenuResponse{
		ID:                  m.ID,
		Name:                m.Name,
		Category:            string(m.Category),
		Source:              string(m.Source),
		DefaultCalories:     m.DefaultCalories,
		DefaultCarbs:        m.DefaultCarbs,
		DefaultProtein:      m.DefaultProtein,
		DefaultFat:          m.DefaultFat,
		DefaultFiber:        m.DefaultFiber,
		DefaultVitaminScore: m.DefaultVitaminScore,
	}
}
