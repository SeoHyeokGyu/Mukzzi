package config

import (
	"context"
	"log/slog"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/robfig/cron/v3"
)

// StartScheduler 는 백그라운드 크론 스케줄러를 시작합니다.
func StartScheduler(userUsecase usecase.UserUsecase, questUsecase usecase.QuestUsecase) {
	loc, err := time.LoadLocation("Asia/Seoul")
	if err != nil {
		loc = time.Local
	}
	c := cron.New(cron.WithLocation(loc))

	jobs := []struct {
		spec string
		fn   func()
		name string
	}{
		{"0 0 * * *", func() { runPhysicalDeletion(userUsecase) }, "탈퇴 회원 물리 삭제"},
		{"0 5 * * *", func() { runInactivityPenalty(userUsecase) }, "패널티 상태 갱신"},
		{"0 5 * * *", func() { runQuestReset(questUsecase) }, "일일 퀘스트 초기화"},
		{"0 5 * * *", func() { runStreakReconciliation(userUsecase) }, "전체 유저 스트릭 보정"},
	}

	for _, job := range jobs {
		job := job
		if _, err := c.AddFunc(job.spec, job.fn); err != nil {
			slog.Error("크론 작업 등록 실패", slog.String("job", job.name), slog.Any("error", err))
			return
		}
	}

	c.Start()
	slog.Info("백그라운드 크론 스케줄러 시작됨")
}

func runPhysicalDeletion(userUsecase usecase.UserUsecase) {
	slog.Info("만료된 탈퇴 회원 물리 삭제 작업 시작 (30일 경과 기준)")
	if err := userUsecase.ProcessPhysicalDeletion(); err != nil {
		slog.Error("물리 삭제 작업 중 오류 발생", slog.Any("error", err))
	} else {
		slog.Info("만료된 탈퇴 회원 물리 삭제 작업 완료")
	}
}

func runInactivityPenalty(userUsecase usecase.UserUsecase) {
	slog.Info("패널티 상태 갱신 작업 시작")
	if err := userUsecase.RunInactivityPenalty(); err != nil {
		slog.Error("패널티 상태 갱신 중 오류 발생", slog.Any("error", err))
	} else {
		slog.Info("패널티 상태 갱신 작업 완료")
	}
}

func runQuestReset(questUsecase usecase.QuestUsecase) {
	slog.Info("일일 퀘스트 초기화 및 할당 작업 시작")
	if err := questUsecase.AssignAllUsersDailyQuests(context.Background()); err != nil {
		slog.Error("일일 퀘스트 초기화 중 오류 발생", slog.Any("error", err))
	} else {
		slog.Info("일일 퀘스트 초기화 및 할당 작업 완료")
	}
}

func runStreakReconciliation(userUsecase usecase.UserUsecase) {
	slog.Info("전체 유저 스트릭 재계산 및 보정 작업 시작")
	if err := userUsecase.RecalculateAllUsersStreak(); err != nil {
		slog.Error("스트릭 보정 작업 중 오류 발생", slog.Any("error", err))
	} else {
		slog.Info("전체 유저 스트릭 재계산 및 보정 작업 완료")
	}
}
