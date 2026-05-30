package handler

import (
	"errors"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/config"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/dto"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
)

// SeedHandler 관리자 핸들러
type SeedHandler struct {
	seedUsecase usecase.SeedUsecase
}

func NewSeedHandler(seedUsecase usecase.SeedUsecase) *SeedHandler {
	return &SeedHandler{seedUsecase: seedUsecase}
}

// SeedMenus 메뉴 영양소 데이터 수집 시작 (온디맨드 배치)
// @Summary      메뉴 영양소 데이터 수집
// @Description  식약처(MFDS) 및 USDA에서 영양소 데이터를 수집하여 DB에 저장합니다.
//
//	백그라운드에서 실행되며, 즉시 202 응답을 반환합니다.
//	진행 상황은 GET /admin/menus/seed/status로 확인하세요.
//	source 미입력 시 all(MFDS+USDA), limit 미입력 시 5000건.
//
// @Tags         admin
// @Security     BearerAuth
// @Accept       json
// @Produce      json
// @Param        body  body      dto.SeedMenusRequest  false  "수집 옵션"
// @Success      202   {object}  Response              "수집 작업 시작됨"
// @Failure      400   {object}  Response              "INVALID_REQUEST"
// @Failure      401   {object}  Response              "UNAUTHORIZED"
// @Failure      403   {object}  Response              "FORBIDDEN"
// @Failure      409   {object}  Response              "SEED_ALREADY_RUNNING"
// @Router       /admin/menus/seed [post]
func (h *SeedHandler) SeedMenus(c *gin.Context) {
	var req dto.SeedMenusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "잘못된 요청 형식입니다.", err.Error())
		return
	}

	if req.Source == "" {
		req.Source = "all"
	}
	if req.Limit == 0 {
		req.Limit = 5000
	}

	if err := h.seedUsecase.SeedMenus(c.Request.Context(), req.Source, req.Limit); err != nil {
		if errors.Is(err, usecase.ErrSeedAlreadyRunning) {
			Conflict(c, "SEED_ALREADY_RUNNING", "이미 수집 작업이 실행 중입니다. 완료 후 다시 시도하세요.")
			return
		}
		InternalError(c, "수집 작업 시작에 실패했습니다.", err.Error())
		return
	}

	c.JSON(202, Response{
		Success: true,
		Data: gin.H{
			"message": "수집 작업이 시작되었습니다. GET /admin/menus/seed/status로 진행 상황을 확인하세요.",
			"source":  req.Source,
			"limit":   req.Limit,
		},
	})
}

// GetSeedStatus 마지막 수집 작업 상태 조회
// @Summary      메뉴 수집 작업 상태 조회
// @Description  마지막으로 실행된 수집 작업의 상태와 결과를 반환합니다.
//
//	state: IDLE(미실행) | RUNNING(진행 중) | DONE(완료) | FAILED(실패)
//
// @Tags         admin
// @Security     BearerAuth
// @Produce      json
// @Success      200  {object}  Response{data=dto.SeedJobStatusResponse}
// @Failure      401  {object}  Response  "UNAUTHORIZED"
// @Failure      403  {object}  Response  "FORBIDDEN"
// @Router       /admin/menus/seed/status [get]
func (h *SeedHandler) GetSeedStatus(c *gin.Context) {
	status := h.seedUsecase.GetSeedStatus()
	Success(c, dto.SeedJobStatusResponse{
		State:     string(status.State),
		Source:    status.Source,
		StartedAt: status.StartedAt,
		EndedAt:   status.EndedAt,
		Inserted:  status.Inserted,
		Skipped:   status.Skipped,
		Error:     status.Error,
	})
}

// SyncMenusToRedis Redis 메뉴 자동완성 데이터 동기화
// @Summary      Redis 메뉴 자동완성 동기화
// @Description  DB의 전체 메뉴를 Redis ZSET으로 재동기화합니다.
// @Tags         admin
// @Security     BearerAuth
// @Produce      json
// @Success      200  {object}  Response
// @Failure      401  {object}  Response  "UNAUTHORIZED"
// @Failure      403  {object}  Response  "FORBIDDEN"
// @Failure      500  {object}  Response  "INTERNAL_SERVER_ERROR"
// @Router       /admin/menus/sync-redis [post]
func (h *SeedHandler) SyncMenusToRedis(c *gin.Context) {
	if err := h.seedUsecase.SyncMenusToRedis(c.Request.Context()); err != nil {
		InternalError(c, "Redis 동기화에 실패했습니다.", err.Error())
		return
	}
	Success(c, gin.H{"message": "Redis 동기화가 완료되었습니다."})
}

// ─────────────────────────────────────────
// 스케줄 관리
// ─────────────────────────────────────────

// ListSchedules 전체 스케줄 목록 및 상태 조회
// @Summary      스케줄 목록 조회
// @Description  등록된 모든 크론 스케줄의 활성화 상태와 다음 실행 시간을 반환합니다.
// @Tags         admin
// @Security     BearerAuth
// @Produce      json
// @Success      200  {object}  Response
// @Failure      401  {object}  Response  "UNAUTHORIZED"
// @Failure      403  {object}  Response  "FORBIDDEN"
// @Router       /admin/schedules [get]
func (h *SeedHandler) ListSchedules(c *gin.Context) {
	scheduler := config.GetScheduler()
	if scheduler == nil {
		InternalError(c, "스케줄러가 초기화되지 않았습니다.", "")
		return
	}
	Success(c, scheduler.ListSchedules())
}

// ToggleSchedule 특정 스케줄 활성화/비활성화
// @Summary      스케줄 활성화/비활성화
// @Description  key에 해당하는 스케줄의 활성화 상태를 변경합니다.
// @Tags         admin
// @Security     BearerAuth
// @Accept       json
// @Produce      json
// @Param        key   path      string                    true  "스케줄 키 (예: menu_seed)"
// @Param        body  body      dto.ToggleScheduleRequest true  "활성화 여부"
// @Success      200   {object}  Response
// @Failure      400   {object}  Response  "INVALID_REQUEST"
// @Failure      401   {object}  Response  "UNAUTHORIZED"
// @Failure      403   {object}  Response  "FORBIDDEN"
// @Failure      404   {object}  Response  "SCHEDULE_NOT_FOUND"
// @Router       /admin/schedules/{key}/toggle [patch]
func (h *SeedHandler) ToggleSchedule(c *gin.Context) {
	key := c.Param("key")

	var req dto.ToggleScheduleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "잘못된 요청 형식입니다.", err.Error())
		return
	}

	scheduler := config.GetScheduler()
	if scheduler == nil {
		InternalError(c, "스케줄러가 초기화되지 않았습니다.", "")
		return
	}

	if ok := scheduler.SetEnabled(key, req.Enabled); !ok {
		NotFound(c, "SCHEDULE_NOT_FOUND", "존재하지 않는 스케줄 키입니다.")
		return
	}

	state := "비활성화"
	if req.Enabled {
		state = "활성화"
	}
	Success(c, gin.H{
		"key":     key,
		"enabled": req.Enabled,
		"message": "스케줄이 " + state + "되었습니다.",
	})
}

// RunScheduleNow 특정 스케줄 즉시 실행
// @Summary      스케줄 즉시 실행
// @Description  key에 해당하는 스케줄을 활성화 여부에 관계없이 즉시 실행합니다. 백그라운드에서 실행되며 202를 반환합니다.
// @Tags         admin
// @Security     BearerAuth
// @Produce      json
// @Param        key  path      string  true  "스케줄 키 (예: menu_seed)"
// @Success      202  {object}  Response
// @Failure      401  {object}  Response  "UNAUTHORIZED"
// @Failure      403  {object}  Response  "FORBIDDEN"
// @Failure      404  {object}  Response  "SCHEDULE_NOT_FOUND"
// @Router       /admin/schedules/{key}/run [post]
func (h *SeedHandler) RunScheduleNow(c *gin.Context) {
	key := c.Param("key")

	scheduler := config.GetScheduler()
	if scheduler == nil {
		InternalError(c, "스케줄러가 초기화되지 않았습니다.", "")
		return
	}

	if ok := scheduler.RunNow(key); !ok {
		NotFound(c, "SCHEDULE_NOT_FOUND", "존재하지 않는 스케줄 키입니다.")
		return
	}

	c.JSON(202, Response{
		Success: true,
		Data:    gin.H{"key": key, "message": "스케줄이 백그라운드에서 즉시 실행됩니다."},
	})
}
