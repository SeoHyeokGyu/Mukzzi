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
// @Description  DB에 없는 메뉴를 직접 등록합니다. source=USER로 저장됩니다. 영양소 값을 생략하면 카테고리 평균값이 적용됩니다.
// @Tags         menus
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        request  body      dto.MenuCreateRequest  true  "메뉴 등록 정보"
// @Success      201  {object}  Response  "메뉴 등록 성공"
// @Failure      400  {object}  Response  "잘못된 요청 또는 중복 메뉴"
// @Failure      401  {object}  Response  "인증 토큰 누락 또는 유효하지 않음"
// @Failure      500  {object}  Response  "서버 내부 에러"
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
// @Description  메뉴 ID로 단일 메뉴의 상세 정보를 조회합니다.
// @Tags         menus
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id   path      string  true  "메뉴 ID"
// @Success      200  {object}  Response  "메뉴 조회 성공"
// @Failure      400  {object}  Response  "잘못된 ID 형식"
// @Failure      401  {object}  Response  "인증 토큰 누락 또는 유효하지 않음"
// @Failure      404  {object}  Response  "메뉴를 찾을 수 없음"
// @Failure      500  {object}  Response  "서버 내부 에러"
// @Router       /menus/{id} [get]
func (h *MenuHandler) FindByID(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_PARAMETER", "id 값이 올바르지 않습니다.")
		return
	}

	menu, err := h.menuUsecase.FindByID(c.Request.Context(), id)
	if err != nil {
		InternalError(c, "메뉴 조회에 실패했습니다.")
		return
	}
	if menu == nil {
		NotFound(c, "MENU_NOT_FOUND", "해당 메뉴를 찾을 수 없습니다.")
		return
	}

	Success(c, toMenuResponse(*menu))
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
