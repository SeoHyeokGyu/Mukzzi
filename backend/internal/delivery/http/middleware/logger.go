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
	green   = "\033[97;42m"
	white   = "\033[90;47m"
	yellow  = "\033[90;43m"
	red     = "\033[91;41m"
	blue    = "\033[97;44m"
	magenta = "\033[97;45m"
	cyan    = "\033[97;46m"
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

// LoggerMiddleware 는 보안 및 성능이 강화된 상세 API 로그를 기록합니다.
func LoggerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		requestID, _ := c.Get("requestID")
		isDev := os.Getenv("ENVIRONMENT") == "development"

		// 1. Request Body 로깅 준비
		var reqBodyLog string
		contentType := c.GetHeader("Content-Type")

		if isLoggable(contentType) && c.Request.Body != nil {
			bodyBytes, _ := io.ReadAll(c.Request.Body)
			c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))

			if len(bodyBytes) > MaxLogBodySize {
				reqBodyLog = maskSensitiveJSON(bodyBytes[:MaxLogBodySize]) + "... [TRUNCATED]"
			} else if len(bodyBytes) > 0 {
				reqBodyLog = maskSensitiveJSON(bodyBytes)
			}
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
			fmt.Printf("   ├─ [Request Body]  : %s\n", reqBodyLog)
			fmt.Printf("   └─ [Response Body] : %s\n", blw.body.String())
		} else {
			// 운영 환경용 구조화 로그 (slog)
			logLevel := slog.LevelInfo
			if status >= 400 {
				logLevel = slog.LevelError
			}
			slog.Log(c.Request.Context(), logLevel, "API Interaction",
				slog.String("request_id", fmt.Sprintf("%v", requestID)),
				slog.Group("req",
					slog.String("method", method),
					slog.String("path", path),
					slog.String("body", reqBodyLog),
					slog.String("ip", c.ClientIP()),
				),
				slog.Group("res",
					slog.Int("status", status),
					slog.String("body", blw.body.String()),
					slog.Duration("latency", latency),
				),
			)
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
	default:
		return white
	}
}

func isLoggable(contentType string) bool {
	ct := strings.ToLower(contentType)
	return strings.Contains(ct, "application/json") || strings.Contains(ct, "text/") || ct == ""
}

func maskSensitiveJSON(data []byte) string {
	var bodyMap map[string]any
	if err := json.Unmarshal(data, &bodyMap); err != nil {
		return string(data)
	}
	maskFields(bodyMap)
	maskedData, _ := json.Marshal(bodyMap)
	return string(maskedData)
}

func maskFields(m map[string]any) {
	for k, v := range m {
		if sensitiveFields[strings.ToLower(k)] {
			m[k] = "********"
		} else if nm, ok := v.(map[string]any); ok {
			maskFields(nm)
		}
	}
}
