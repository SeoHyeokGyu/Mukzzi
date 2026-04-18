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
func (h *NotificationHandler) ReadAllNotifications(c *gin.Context) {
	userID, _ := c.Get("userID")

	if err := h.notificationUsecase.ReadAllNotifications(userID.(int64)); err != nil {
		InternalError(c, "전체 알림 읽음 처리에 실패했습니다.", err.Error())
		return
	}

	Success(c, nil)
}

// Stream 실시간 알림 스트림 (SSE)
func (h *NotificationHandler) Stream(c *gin.Context) {
	userID, _ := c.Get("userID")

	// 구독 시작
	ch, unsubscribe := h.notificationUsecase.Subscribe(userID.(int64))
	defer unsubscribe()

	c.Header("Content-Type", "text/event-stream")
	c.Header("Cache-Control", "no-cache")
	c.Header("Connection", "keep-alive")
	c.Header("X-Accel-Buffering", "no")

	ticker := time.NewTicker(15 * time.Second)
	defer ticker.Stop()

	// 클라이언트 연결 상태 감시 및 데이터 전송
	c.Stream(func(w io.Writer) bool {
		select {
		case n, ok := <-ch:
			if !ok {
				return false
			}
			c.SSEvent("notification", dto.ToNotificationResponse(n))
			return true
			
		case <-ticker.C:
			// 하트비트 전송
			c.Render(-1, render.Data{
				ContentType: "text/event-stream",
				Data:        []byte(": heartbeat\n\n"),
			})
			return true
			
		case <-c.Request.Context().Done():
			// 연결 종료 감지
			return false
		}
	})
}
