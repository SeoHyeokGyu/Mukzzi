package config

import (
	"log/slog"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/robfig/cron/v3"
)

// StartScheduler 는 백그라운드 크론 스케줄러를 시작합니다.
func StartScheduler(userUsecase usecase.UserUsecase) {
	// 서울 시간대 기준으로 크론 생성 (옵션: cron.WithLocation)
	c := cron.New()

	// 매일 자정 (00:00)에 실행
	_, err := c.AddFunc("0 0 * * *", func() {
		runPhysicalDeletion(userUsecase)
	})

	if err != nil {
		slog.Error("크론 작업 등록 실패", slog.Any("error", err))
		return
	}

	c.Start()
	slog.Info("백그라운드 크론 스케줄러 시작됨 (매일 자정 실행)")

	// 서버 시작 시 즉시 한 번 실행하여 체크 (선택 사항)
	go runPhysicalDeletion(userUsecase)
}

func runPhysicalDeletion(userUsecase usecase.UserUsecase) {
	slog.Info("만료된 탈퇴 회원 물리 삭제 작업 시작 (30일 경과 기준)")
	if err := userUsecase.ProcessPhysicalDeletion(); err != nil {
		slog.Error("물리 삭제 작업 중 오류 발생", slog.Any("error", err))
	} else {
		slog.Info("만료된 탈퇴 회원 물리 삭제 작업 완료")
	}
}
