package middleware

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"os"
	"strings"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/gin-gonic/gin"
)

const (
	// MaxLogBodySize 는 로그에 기록할 요청/응답 본문의 최대 크기입니다 (2KB).
	MaxLogBodySize = 2048

	// ANSI 색상 코드
	green   = "\033[32m"
	white   = "\033[37m"
	yellow  = "\033[33m"
	red     = "\033[31m"
	blue    = "\033[34m"
	magenta = "\033[35m"
	cyan    = "\033[36m"
	reset   = "\033[0m"
)

// sensitiveFields는 로그에서 마스킹 처리할 보안 필드 목록입니다.
var sensitiveFields = map[string]bool{
	"password":      true,
	"access_token":  true,
	"refresh_token": true,
}

// bodyLogWriter 는 응답 본문을 캡처하기 위한 커스텀 ResponseWriter입니다.
type bodyLogWriter struct {
	gin.ResponseWriter
	body    *bytes.Buffer
	maxSize int
}

func (w *bodyLogWriter) Write(b []byte) (int, error) {
	if w.body.Len() < w.maxSize {
		remaining := w.maxSize - w.body.Len()
		if len(b) > remaining {
			w.body.Write(b[:remaining])
			w.body.WriteString("... [TRUNCATED]")
		} else {
			w.body.Write(b)
		}
	}
	return w.ResponseWriter.Write(b)
}

// RequestIDMiddleware 는 모든 요청에 Sonyflake 고유 ID를 부여합니다.
func RequestIDMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		id, err := domain.NextID()
		if err != nil {
			id = uint64(time.Now().UnixNano())
		}

		requestID := fmt.Sprintf("%d", id)
		c.Set("requestID", requestID)
		c.Header("X-Request-ID", requestID)
		c.Next()
	}
}

// LoggerMiddleware 는 slog를 기반으로 상세 API 로그를 기록합니다.
func LoggerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		path := c.Request.URL.Path

		// Skip logging for swagger and SSE stream requests
		if strings.HasPrefix(path, "/swagger") || path == "/api/notifications/stream" {
			c.Next()
			return
		}

		start := time.Now()
		requestID, _ := c.Get("requestID")
		isDev := os.Getenv("ENVIRONMENT") == "development"

		// 1. Request Body 로깅 준비
		var bodyBytes []byte
		contentType := c.GetHeader("Content-Type")

		if isLoggable(contentType) && c.Request.Body != nil {
			bodyBytes, _ = io.ReadAll(c.Request.Body)
			c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
		}

		// 2. Response Body 캡처 설정
		blw := &bodyLogWriter{
			body:           bytes.NewBuffer(make([]byte, 0, MaxLogBodySize)),
			ResponseWriter: c.Writer,
			maxSize:        MaxLogBodySize,
		}
		c.Writer = blw

		c.Next()

		// 3. 최종 로깅 실행
		latency := time.Since(start)
		status := c.Writer.Status()
		method := c.Request.Method

		// 로깅용 바디 가공 (마스킹 및 객체화)
		reqBody := processBodyLog(bodyBytes)
		resBody := processBodyLog(blw.body.Bytes())

		if isDev {
			// 개발 환경용 컬러 로그 출력
			fmt.Printf("[MUKZZI] %s | %v | %s %3d %s | %13v | %15s | %s %-7s %s %s\n",
				requestID,
				time.Now().Format("15:04:05"),
				statusColor(status), status, reset,
				latency,
				c.ClientIP(),
				methodColor(method), method, reset,
				path,
			)

			// 본문은 직접 마샬링하여 예쁘게 출력
			reqStr, _ := json.Marshal(reqBody)
			resStr, _ := json.Marshal(resBody)
			fmt.Printf("   ├─ [Req] : %s\n", string(reqStr))
			fmt.Printf("   └─ [Res] : %s\n", string(resStr))
		} else {
			// 운영 환경용 구조화 로그 (JSON)
			logLevel := slog.LevelInfo
			if status >= 400 {
				logLevel = slog.LevelError
			}

			slog.Log(c.Request.Context(), logLevel, "API Interaction",
				slog.String("request_id", fmt.Sprintf("%v", requestID)),
				slog.Group("req",
					slog.String("method", method),
					slog.String("path", path),
					slog.Any("body", reqBody),
					slog.String("ip", c.ClientIP()),
				),
				slog.Group("res",
					slog.Int("status", status),
					slog.Any("body", resBody),
					slog.Duration("latency", latency),
				),
			)
		}
	}
}

// processBodyLog 는 바디 데이터를 마스킹 처리하고, 가능하다면 JSON 객체(map)로 반환합니다.
func processBodyLog(data []byte) any {
	if len(data) == 0 {
		return nil
	}

	var bodyMap any
	if err := json.Unmarshal(data, &bodyMap); err != nil {
		str := string(data)
		if len(str) > MaxLogBodySize {
			return str[:MaxLogBodySize] + "... [TRUNCATED]"
		}
		return str
	}

	if m, ok := bodyMap.(map[string]any); ok {
		maskFields(m)
	}

	return bodyMap
}

func maskFields(m map[string]any) {
	for k, v := range m {
		if sensitiveFields[strings.ToLower(k)] {
			m[k] = "********"
		} else if nm, ok := v.(map[string]any); ok {
			maskFields(nm)
		} else if slice, ok := v.([]any); ok {
			for _, item := range slice {
				if im, ok := item.(map[string]any); ok {
					maskFields(im)
				}
			}
		}
	}
}

func statusColor(code int) string {
	switch {
	case code >= 200 && code < 300:
		return green
	case code >= 300 && code < 400:
		return white
	case code >= 400 && code < 500:
		return yellow
	default:
		return red
	}
}

func methodColor(method string) string {
	switch method {
	case "GET":
		return blue
	case "POST":
		return cyan
	case "PUT":
		return yellow
	case "DELETE":
		return red
	case "PATCH":
		return green
	case "HEAD":
		return magenta
	case "OPTIONS":
		return white
	default:
		return white
	}
}

func isLoggable(contentType string) bool {
	ct := strings.ToLower(contentType)
	return strings.Contains(ct, "application/json") || strings.Contains(ct, "text/") || ct == ""
}
