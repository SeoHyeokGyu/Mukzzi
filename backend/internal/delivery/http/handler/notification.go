package handler

import (
	"io"
	"strconv"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/dto"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
	"github.com/gin-gonic/gin/render"
)

type NotificationHandler struct {
	notificationUsecase usecase.NotificationUsecase
}

func NewNotificationHandler(notificationUsecase usecase.NotificationUsecase) *NotificationHandler {
	return &NotificationHandler{
		notificationUsecase: notificationUsecase,
	}
}

// GetNotifications 알림 목록 조회
// @Summary      알림 목록 조회
// @Description  현재 사용자의 알림 목록을 cursor 기반 페이지네이션으로 조회합니다.
// @Tags         notifications
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        limit   query     int     false  "페이지당 항목 수 (기본 20)"
// @Param        cursor  query     string  false  "다음 페이지 커서"
// @Success      200  {object}  Response  "알림 목록 조회 성공"
// @Router       /api/notifications [get]
func (h *NotificationHandler) GetNotifications(c *gin.Context) {
	userID, _ := c.Get("userID")

	limitStr := c.DefaultQuery("limit", "20")
	limit, _ := strconv.Atoi(limitStr)
	cursor := c.Query("cursor")

	notifications, nextCursor, err := h.notificationUsecase.GetNotifications(userID.(int64), limit, cursor)
	if err != nil {
		InternalError(c, "알림 목록을 불러오는데 실패했습니다.", err.Error())
		return
	}

	CursorPaginated(c, dto.ToNotificationListResponse(notifications), limit, nextCursor != "", nextCursor)
}

// ReadNotification 알림 읽음 처리
// @Summary      알림 읽음 처리
// @Description  특정 알림을 읽음 상태로 변경합니다.
// @Tags         notifications
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id   path      int64   true  "알림 ID"
// @Success      200  {object}  Response  "알림 읽음 처리 성공"
// @Router       /api/notifications/{id}/read [patch]
func (h *NotificationHandler) ReadNotification(c *gin.Context) {
	userID, _ := c.Get("userID")
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "잘못된 알림 ID입니다.")
		return
	}

	if err := h.notificationUsecase.ReadNotification(id, userID.(int64)); err != nil {
		InternalError(c, "알림 읽음 처리에 실패했습니다.", err.Error())
		return
	}

	Success(c, nil)
}

// ReadAllNotifications 전체 알림 읽음 처리
// @Summary      전체 알림 읽음 처리
// @Description  현재 사용자의 모든 읽지 않은 알림을 읽음 상태로 변경합니다.
// @Tags         notifications
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  Response  "전체 알림 읽음 처리 성공"
// @Router       /api/notifications/read-all [post]
func (h *NotificationHandler) ReadAllNotifications(c *gin.Context) {
	userID, _ := c.Get("userID")

	if err := h.notificationUsecase.ReadAllNotifications(userID.(int64)); err != nil {
		InternalError(c, "전체 알림 읽음 처리에 실패했습니다.", err.Error())
		return
	}

	Success(c, nil)
}

// Stream 실시간 알림 스트림 (SSE)
// @Summary      실시간 알림 스트림
// @Description  SSE를 통해 현재 사용자의 알림을 실시간으로 수신합니다.
// @Tags         notifications
// @Accept       json
// @Produce      text/event-stream
// @Security     BearerAuth
// @Router       /api/notifications/stream [get]
func (h *NotificationHandler) Stream(c *gin.Context) {
	userID, _ := c.Get("userID")

	// 구독 시작
	ch, unsubscribe := h.notificationUsecase.Subscribe(userID.(int64))
	defer unsubscribe()

	c.Header("Content-Type", "text/event-stream")
	c.Header("Cache-Control", "no-cache")
	c.Header("Connection", "keep-alive")
	c.Header("Transfer-Encoding", "chunked")

	ticker := time.NewTicker(15 * time.Second) // 15초마다 하트비트
	defer ticker.Stop()

	c.Stream(func(w io.Writer) bool {
		select {
		case n, ok := <-ch:
			if !ok {
				return false
			}
			c.SSEvent("notification", dto.ToNotificationResponse(n))
			return true
		case <-ticker.C:
			// 연결 유지용 주석(comment) 직접 전송
			c.Render(-1, render.Data{
				ContentType: "text/event-stream",
				Data:        []byte(": heartbeat\n\n"),
			})
			return true
		case <-c.Request.Context().Done():
			return false
		}
	})
}
