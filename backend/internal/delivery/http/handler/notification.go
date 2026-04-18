package handler

import (
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strconv"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/dto"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
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
	uid, _ := c.Get("userID")
	userID := uid.(int64)

	// 구독 시작
	ch, unsubscribe := h.notificationUsecase.Subscribe(userID)

	// 핸들러 종료 시 반드시 구독 해제
	defer func() {
		unsubscribe()
		slog.Debug("SSE 스트림 핸들러 물리적 종료", slog.Int64("user_id", userID))
	}()

	c.Header("Content-Type", "text/event-stream")
	c.Header("Cache-Control", "no-cache")
	c.Header("Connection", "keep-alive")
	c.Header("X-Accel-Buffering", "no")

	flusher, ok := c.Writer.(http.Flusher)
	if !ok {
		InternalError(c, "Streaming not supported")
		return
	}

	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()

	flusher.Flush()

	// 데이터 전송 및 연결 감시 루프
	c.Stream(func(w io.Writer) bool {
		select {
		case n, ok := <-ch:
			if !ok {
				slog.Debug("SSE 채널 닫힘 (중복 연결 정리됨)", slog.Int64("user_id", userID))
				return false // 채널이 닫히면 루프 종료
			}
			c.SSEvent("notification", dto.ToNotificationResponse(n))
			flusher.Flush()
			return true

		case <-ticker.C:
			// 하트비트 전송
			if _, err := fmt.Fprintf(w, ": heartbeat\n\n"); err != nil {
				slog.Debug("SSE 하트비트 전송 실패 (클라이언트 종료)", slog.Int64("user_id", userID))
				return false
			}
			flusher.Flush()
			return true

		case <-c.Request.Context().Done():
			slog.Debug("SSE 컨텍스트 종료 (브라우저 새로고침/종료)", slog.Int64("user_id", userID))
			return false
		}
	})
}
