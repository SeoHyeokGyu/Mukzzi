package handler

import (
	"errors"
	"strconv"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/dto"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
)

// MealHandler 식사 기록 핸들러
type MealHandler struct {
	mealUsecase usecase.MealUsecase
}

// NewMealHandler 식사 기록 핸들러 생성
func NewMealHandler(mealUsecase usecase.MealUsecase) *MealHandler {
	return &MealHandler{mealUsecase: mealUsecase}
}

// CreateMeal 식사 기록 등록
// @Summary      식사 기록 등록
// @Description  메뉴명, 식사 타입, 인분, 식사 시간을 필수로 입력합니다. 날씨/기분 태그는 선택 사항입니다. 등록 성공 시 퀘스트 진행 및 마스터리 갱신 결과를 side_effects로 함께 반환합니다.
// @Tags         meals
// @Security     BearerAuth
// @Accept       json
// @Produce      json
// @Param        body  body      dto.CreateMealRequest   true  "식사 기록 정보"
// @Success      201   {object}  Response  "식사 기록 등록 성공"
// @Failure      400   {object}  Response  "INVALID_REQUEST / INVALID_PARAMETER"
// @Failure      401   {object}  Response  "UNAUTHORIZED"
// @Failure      500   {object}  Response  "INTERNAL_SERVER_ERROR"
// @Router       /api/meals [post]
func (h *MealHandler) CreateMeal(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		Unauthorized(c, "UNAUTHORIZED", "인증 정보가 없습니다.")
		return
	}

	var req dto.CreateMealRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "잘못된 요청 형식입니다.", err.Error())
		return
	}

	input, err := dto.ToCreateMealInput(req, userID.(int64))
	if err != nil {
		BadRequest(c, "INVALID_PARAMETER", err.Error())
		return
	}

	output, err := h.mealUsecase.CreateMeal(input)
	if err != nil {
		InternalError(c, "식사 기록 저장에 실패했습니다.", err.Error())
		return
	}

	Created(c, dto.CreateMealResponse{
		Meal:        dto.ToMealResponse(output.Meal),
		SideEffects: output.SideEffects,
	})
}

// ListMeals 식사 기록 목록 조회
// @Summary      식사 기록 목록 조회
// @Description  날짜 범위 및 식사 타입으로 필터링할 수 있습니다. cursor 기반 페이지네이션을 사용합니다. cursor 미입력 시 최신순으로 첫 페이지를 반환합니다.
// @Tags         meals
// @Security     BearerAuth
// @Produce      json
// @Param        start_date  query     string  false  "시작일 (YYYY-MM-DD)"
// @Param        end_date    query     string  false  "종료일 (YYYY-MM-DD)"
// @Param        meal_type   query     string  false  "식사 종류" Enums(BREAKFAST, LUNCH, DINNER, SNACK)
// @Param        cursor      query     string  false  "다음 페이지 커서 (이전 응답의 next_cursor 값)"
// @Param        limit       query     int     false  "페이지당 항목 수 (기본값: 20, 최대: 50)"
// @Success      200         {object}  Response  "식사 기록 목록 조회 성공"
// @Failure      400         {object}  Response  "INVALID_PARAMETER"
// @Failure      401         {object}  Response  "UNAUTHORIZED"
// @Failure      500         {object}  Response  "INTERNAL_SERVER_ERROR"
// @Router       /api/meals [get]
func (h *MealHandler) ListMeals(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		Unauthorized(c, "UNAUTHORIZED", "인증 정보가 없습니다.")
		return
	}

	var q dto.MealListQuery
	if err := c.ShouldBindQuery(&q); err != nil {
		BadRequest(c, "INVALID_PARAMETER", "잘못된 쿼리 파라미터입니다.", err.Error())
		return
	}

	if q.Limit == 0 {
		q.Limit = 20
	}

	filter := domain.MealListFilter{
		StartDate: q.StartDate,
		EndDate:   q.EndDate,
		MealType:  domain.MealType(q.MealType),
		Limit:     q.Limit,
	}

	if q.Cursor != "" {
		v, err := strconv.ParseInt(q.Cursor, 10, 64)
		if err != nil {
			BadRequest(c, "INVALID_PARAMETER", "cursor 값이 올바르지 않습니다.")
			return
		}
		filter.Cursor = v
	}

	out, err := h.mealUsecase.ListMeals(userID.(int64), filter)
	if err != nil {
		InternalError(c, "식사 목록 조회에 실패했습니다.", err.Error())
		return
	}

	mealResponses := make([]dto.MealResponse, len(out.Meals))
	for i := range out.Meals {
		mealResponses[i] = dto.ToMealResponse(&out.Meals[i])
	}

	nextCursor := ""
	if out.HasNext && len(out.Meals) > 0 {
		nextCursor = strconv.FormatInt(out.Meals[len(out.Meals)-1].ID, 10)
	}

	CursorPaginated(c, mealResponses, q.Limit, out.HasNext, nextCursor)
}

// GetMeal 식사 기록 상세 조회
// @Summary      식사 기록 상세 조회
// @Description  식사 기록 ID로 단건 조회합니다. 본인 기록만 조회 가능합니다.
// @Tags         meals
// @Security     BearerAuth
// @Produce      json
// @Param        id   path      string  true  "식사 기록 ID"
// @Success      200  {object}  Response  "식사 기록 조회 성공"
// @Failure      400  {object}  Response  "INVALID_ID"
// @Failure      401  {object}  Response  "UNAUTHORIZED"
// @Failure      403  {object}  Response  "MEAL_FORBIDDEN"
// @Failure      404  {object}  Response  "MEAL_NOT_FOUND"
// @Router       /api/meals/{id} [get]
func (h *MealHandler) GetMeal(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		Unauthorized(c, "UNAUTHORIZED", "인증 정보가 없습니다.")
		return
	}

	mealID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "올바른 ID 형식이 아닙니다.")
		return
	}

	meal, err := h.mealUsecase.GetMeal(mealID, userID.(int64))
	if err != nil {
		handleMealError(c, err)
		return
	}

	Success(c, dto.ToMealResponse(meal))
}

// UpdateMeal 식사 기록 수정
// @Summary      식사 기록 수정
// @Description  수정할 필드만 포함하여 요청합니다. 포함되지 않은 필드는 기존 값을 유지합니다.
// @Tags         meals
// @Security     BearerAuth
// @Accept       json
// @Produce      json
// @Param        id    path      string                 true  "식사 기록 ID"
// @Param        body  body      dto.UpdateMealRequest  true  "수정할 식사 기록 정보"
// @Success      200   {object}  Response  "식사 기록 수정 성공"
// @Failure      400   {object}  Response  "INVALID_REQUEST / INVALID_PARAMETER"
// @Failure      401   {object}  Response  "UNAUTHORIZED"
// @Failure      403   {object}  Response  "MEAL_FORBIDDEN"
// @Failure      404   {object}  Response  "MEAL_NOT_FOUND"
// @Router       /api/meals/{id} [patch]
func (h *MealHandler) UpdateMeal(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		Unauthorized(c, "UNAUTHORIZED", "인증 정보가 없습니다.")
		return
	}

	mealID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "올바른 ID 형식이 아닙니다.")
		return
	}

	var req dto.UpdateMealRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "잘못된 요청 형식입니다.", err.Error())
		return
	}

	input := usecase.UpdateMealInput{
		MealID:      mealID,
		UserID:      userID.(int64),
		MenuName:    req.MenuName,
		Category:    req.Category,
		ServingSize: req.ServingSize,
		WeatherTag:  req.WeatherTag,
		MoodTag:     req.MoodTag,
		Review:      req.Review,
		Rating:      req.Rating,
	}
	if req.MealType != nil {
		mt := domain.MealType(*req.MealType)
		input.MealType = &mt
	}
	if req.RecordedAt != nil {
		t, err := time.Parse(time.RFC3339, *req.RecordedAt)
		if err != nil {
			BadRequest(c, "INVALID_PARAMETER", "올바른 날짜 형식(RFC3339)이 아닙니다.")
			return
		}
		input.RecordedAt = &t
	}

	meal, err := h.mealUsecase.UpdateMeal(input)
	if err != nil {
		handleMealError(c, err)
		return
	}

	Success(c, dto.ToMealResponse(meal))
}

// DeleteMeal 식사 기록 삭제
// @Summary      식사 기록 삭제
// @Description  식사 기록을 soft delete 처리합니다. 본인 기록만 삭제 가능합니다.
// @Tags         meals
// @Security     BearerAuth
// @Produce      json
// @Param        id   path      string  true  "식사 기록 ID"
// @Success      200  {object}  Response
// @Failure      400  {object}  Response  "INVALID_ID"
// @Failure      401  {object}  Response  "UNAUTHORIZED"
// @Failure      403  {object}  Response  "MEAL_FORBIDDEN"
// @Failure      404  {object}  Response  "MEAL_NOT_FOUND"
// @Router       /api/meals/{id} [delete]
func (h *MealHandler) DeleteMeal(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		Unauthorized(c, "UNAUTHORIZED", "인증 정보가 없습니다.")
		return
	}

	mealID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "올바른 ID 형식이 아닙니다.")
		return
	}

	if err := h.mealUsecase.DeleteMeal(mealID, userID.(int64)); err != nil {
		handleMealError(c, err)
		return
	}

	Success(c, nil)
}

// AcceptFriendTag 식사 친구 태그 수락
// @Summary      식사 친구 태그 수락
// @Description  식사 기록에 태그된 친구 요청을 수락합니다. 태그된 본인만 수락 가능합니다. 수락 시 양쪽 모두에게 보너스 EXP가 지급됩니다.
// @Tags         meals
// @Security     BearerAuth
// @Produce      json
// @Param        id     path      string  true  "식사 기록 ID"
// @Param        tagId  path      string  true  "태그 ID"
// @Success      200    {object}  Response
// @Failure      400    {object}  Response  "INVALID_ID"
// @Failure      401    {object}  Response  "UNAUTHORIZED"
// @Failure      404    {object}  Response  "TAG_NOT_FOUND"
// @Failure      500    {object}  Response  "INTERNAL_SERVER_ERROR"
// @Router       /api/meals/{id}/tags/{tagId}/accept [post]
func (h *MealHandler) AcceptFriendTag(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		Unauthorized(c, "UNAUTHORIZED", "인증 정보가 없습니다.")
		return
	}

	mealID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "올바른 meal ID 형식이 아닙니다.")
		return
	}

	if err := h.mealUsecase.AcceptFriendTag(mealID, userID.(int64)); err != nil {
		if errors.Is(err, usecase.ErrTagNotFound) {
			NotFound(c, "TAG_NOT_FOUND", "태그를 찾을 수 없습니다.")
			return
		}
		InternalError(c, "태그 수락에 실패했습니다.", err.Error())
		return
	}

	Success(c, nil)
}

// GetTodayNutrition 오늘 영양 섭취 요약
// @Summary      오늘 영양 섭취 요약
// @Description  오늘(05:00 KST 기준) 섭취한 영양소 합산 정보를 반환합니다. 식사 기록이 없으면 모든 값이 0인 빈 응답을 반환합니다. last_calculated_at으로 마지막 계산 시각을 확인할 수 있습니다.
// @Tags         nutrition
// @Security     BearerAuth
// @Produce      json
// @Success      200  {object}  Response  "오늘 영양 정보 조회 성공"
// @Failure      401  {object}  Response  "UNAUTHORIZED"
// @Failure      500  {object}  Response  "INTERNAL_SERVER_ERROR"
// @Router       /api/nutrition/today [get]
func (h *MealHandler) GetTodayNutrition(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		Unauthorized(c, "UNAUTHORIZED", "인증 정보가 없습니다.")
		return
	}

	di, err := h.mealUsecase.GetTodayNutrition(userID.(int64))
	if err != nil {
		InternalError(c, "영양 정보 조회에 실패했습니다.", err.Error())
		return
	}

	Success(c, dto.ToDailyNutritionResponse(di))
}

// GetWeeklyNutrition 주간 영양 요약
// @Summary      주간 영양 요약
// @Description  start_date 기준 7일간(start_date ~ start_date+6) 날짜별 영양소 합산을 반환합니다. 기록이 없는 날짜는 응답에 포함되지 않습니다.
// @Tags         nutrition
// @Security     BearerAuth
// @Produce      json
// @Param        start_date  query     string  true  "시작일 (YYYY-MM-DD)"
// @Success      200         {object}  Response  "주간 영양 정보 조회 성공"
// @Failure      400         {object}  Response  "INVALID_PARAMETER"
// @Failure      401         {object}  Response  "UNAUTHORIZED"
// @Failure      500         {object}  Response  "INTERNAL_SERVER_ERROR"
// @Router       /api/nutrition/weekly [get]
func (h *MealHandler) GetWeeklyNutrition(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		Unauthorized(c, "UNAUTHORIZED", "인증 정보가 없습니다.")
		return
	}

	var q dto.WeeklyNutritionQuery
	if err := c.ShouldBindQuery(&q); err != nil {
		BadRequest(c, "INVALID_PARAMETER", "잘못된 쿼리 파라미터입니다.", err.Error())
		return
	}

	intakes, err := h.mealUsecase.GetWeeklyNutrition(userID.(int64), q.StartDate)
	if err != nil {
		InternalError(c, "주간 영양 정보 조회에 실패했습니다.", err.Error())
		return
	}

	items := make([]dto.WeeklyNutritionItem, len(intakes))
	for i, di := range intakes {
		items[i] = dto.ToWeeklyNutritionItem(di)
	}

	Success(c, items)
}

// ─────────────────────────────────────────
// 내부 헬퍼
// ─────────────────────────────────────────

func handleMealError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, usecase.ErrMealNotFound):
		NotFound(c, "MEAL_NOT_FOUND", "식사 기록을 찾을 수 없습니다.")
	case errors.Is(err, usecase.ErrMealForbidden):
		Forbidden(c, "MEAL_FORBIDDEN", "접근 권한이 없습니다.")
	default:
		InternalError(c, "서버 내부 에러가 발생했습니다.", err.Error())
	}
}
