package config

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"os"
)

// InitLogger 는 환경 변수에 따라 slog 의 로그 레벨 및 핸들러를 설정합니다.
func InitLogger() {
	isDev := os.Getenv("ENVIRONMENT") == "development"

	if isDev {
		// 개발 환경: 커스텀 가독성 핸들러 사용
		opts := slog.HandlerOptions{
			Level: slog.LevelDebug,
		}
		handler := &prettyHandler{
			Handler: slog.NewTextHandler(os.Stdout, &opts),
		}
		slog.SetDefault(slog.New(handler))
	} else {
		// 운영 환경: 표준 JSON 핸들러 사용
		opts := slog.HandlerOptions{
			Level: slog.LevelInfo,
		}
		handler := slog.NewJSONHandler(os.Stdout, &opts)
		logger := slog.New(handler).With(slog.String("app", "MUKZZI"))
		slog.SetDefault(logger)
	}
}

// prettyHandler 는 개발 환경에서 가독성 높은 헤더와 트리 구조의 데이터를 제공합니다.
type prettyHandler struct {
	slog.Handler
}

func (h *prettyHandler) Handle(ctx context.Context, r slog.Record) error {
	level := r.Level.String()
	switch r.Level {
	case slog.LevelDebug:
		level = "\033[34mDEBUG\033[0m" // Blue
	case slog.LevelInfo:
		level = "\033[32mINFO \033[0m" // Green
	case slog.LevelWarn:
		level = "\033[33mWARN \033[0m" // Yellow
	case slog.LevelError:
		level = "\033[31mERROR\033[0m" // Red
	}

	timeStr := r.Time.Format("15:04:05")
	
	// 1. 헤더 출력
	fmt.Printf("[MUKZZI] %s | %s | %s | %s\n", 
		timeStr, 
		level, 
		"---------", 
		r.Message,
	)

	// 2. 속성(Attributes) 출력
	r.Attrs(func(a slog.Attr) bool {
		// API 로그의 req, res 는 특별 취급하여 더 예쁘게 출력
		if a.Key == "req" || a.Key == "res" {
			valJSON, _ := json.Marshal(a.Value.Any())
			label := "Req"
			if a.Key == "res" { label = "Res" }
			fmt.Printf("   ├─ [%s] : %s\n", label, string(valJSON))
		} else if a.Key == "request_id" {
			// request_id 는 헤더 정보 보강용으로 생략하거나 작게 표시 가능
		} else {
			// 일반 속성
			fmt.Printf("   └─ [%s] : %v\n", a.Key, a.Value.Any())
		}
		return true
	})

	return nil
}
