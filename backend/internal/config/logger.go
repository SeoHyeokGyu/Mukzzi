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
		// 개발 환경: 가독성 모드 + 소스 코드 위치 추적
		opts := slog.HandlerOptions{
			Level:     slog.LevelDebug,
			AddSource: true, // 소스 코드 위치(파일명:라인) 포함
		}
		handler := &prettyHandler{
			Handler: slog.NewTextHandler(os.Stdout, &opts),
		}
		slog.SetDefault(slog.New(handler))
	} else {
		// 운영 환경: ELK/분석 툴 최적화 모드
		opts := slog.HandlerOptions{
			Level:     slog.LevelInfo,
			AddSource: true,
			ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
				// ELK 표준 타임스탬프 필드명 (@timestamp) 적용
				if a.Key == slog.TimeKey {
					return slog.Attr{Key: "@timestamp", Value: a.Value}
				}
				return a
			},
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
		level = "\033[34mDEBUG\033[0m"
	case slog.LevelInfo:
		level = "\033[32mINFO \033[0m"
	case slog.LevelWarn:
		level = "\033[33mWARN \033[0m"
	case slog.LevelError:
		level = "\033[31mERROR\033[0m"
	}

	timeStr := r.Time.Format("15:04:05")

	// 헤더 출력
	fmt.Printf("[MUKZZI] %s | %s | %s | %s\n", timeStr, level, "---------", r.Message)

	r.Attrs(func(a slog.Attr) bool {
		if a.Key == "req" || a.Key == "res" {
			valJSON, _ := json.Marshal(a.Value.Any())
			label := "Req"
			if a.Key == "res" {
				label = "Res"
			}
			fmt.Printf("   ├─ [%s] : %s\n", label, string(valJSON))
		} else if a.Key == "source" {
			// 소스 정보 (파일명:라인) 표시
			fmt.Printf("   ├─ [Loc] : %v\n", a.Value.Any())
		} else if a.Key != "app" && a.Key != "request_id" {
			fmt.Printf("   └─ [%s] : %v\n", a.Key, a.Value.Any())
		}
		return true
	})

	return nil
}
