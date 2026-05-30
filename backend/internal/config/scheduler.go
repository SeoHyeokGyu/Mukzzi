package config

import (
	"context"
	"log/slog"
	"sync"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/robfig/cron/v3"
)

// SchedulerManager 크론 스케줄러와 각 작업의 활성화 상태를 관리합니다.
type SchedulerManager struct {
	mu      sync.RWMutex
	cron    *cron.Cron
	entries map[string]schedulerEntry
}

type schedulerEntry struct {
	entryID cron.EntryID
	spec    string
	name    string
	enabled bool
	fn      func()
}

// ScheduleStatus 는 클라이언트에 반환하는 스케줄 상태 뷰입니다.
type ScheduleStatus struct {
	Key     string    `json:"key"`
	Name    string    `json:"name"`
	Spec    string    `json:"spec"`
	Enabled bool      `json:"enabled"`
	NextRun time.Time `json:"next_run"`
}

var globalScheduler *SchedulerManager

// GetScheduler 는 싱글톤 스케줄러를 반환합니다.
func GetScheduler() *SchedulerManager {
	return globalScheduler
}

// StartScheduler 는 백그라운드 크론 스케줄러를 시작합니다.
func StartScheduler(userUsecase usecase.UserUsecase, questUsecase usecase.QuestUsecase, seedUsecase usecase.SeedUsecase) {
	loc, err := time.LoadLocation("Asia/Seoul")
	if err != nil {
		loc = time.Local
	}

	c := cron.New(cron.WithLocation(loc), cron.WithSeconds())

	mgr := &SchedulerManager{
		cron:    c,
		entries: make(map[string]schedulerEntry),
	}

	type jobDef struct {
		key  string
		spec string
		name string
		fn   func()
	}

	jobs := []jobDef{
		{
			key:  "physical_deletion",
			spec: "0 0 0 * * *", // 매일 00:00 KST
			name: "탈퇴 회원 물리 삭제",
			fn:   func() { runPhysicalDeletion(userUsecase) },
		},
		{
			key:  "inactivity_penalty",
			spec: "0 5 0 * * *", // 매일 00:05 KST
			name: "패널티 상태 갱신",
			fn:   func() { runInactivityPenalty(userUsecase) },
		},
		{
			key:  "daily_quest_reset",
			spec: "0 5 0 * * *", // 매일 00:05 KST
			name: "일일 퀘스트 초기화",
			fn:   func() { runQuestReset(questUsecase) },
		},
		{
			key:  "weekly_quest_reset",
			spec: "0 5 0 * * 1", // 매주 월요일 00:05 KST
			name: "주간 퀘스트 초기화",
			fn:   func() { runWeeklyQuestReset(questUsecase) },
		},
		{
			key:  "streak_reconciliation",
			spec: "0 5 0 * * *", // 매일 00:05 KST
			name: "전체 유저 스트릭 보정",
			fn:   func() { runStreakReconciliation(userUsecase) },
		},
		{
			key:  "menu_seed",
			spec: "0 0 3 1 * *", // 매월 1일 03:00 KST
			name: "식약처/USDA 영양소 데이터 수집",
			fn:   func() { runMenuSeed(seedUsecase) },
		},
	}

	for _, job := range jobs {
		job := job
		entryID, err := c.AddFunc(job.spec, func() {
			mgr.mu.RLock()
			entry, ok := mgr.entries[job.key]
			mgr.mu.RUnlock()

			if !ok || !entry.enabled {
				slog.Info("스케줄 작업 비활성화 상태 - 스킵", slog.String("job", job.name))
				return
			}
			job.fn()
		})
		if err != nil {
			slog.Error("크론 작업 등록 실패", slog.String("job", job.name), slog.Any("error", err))
			continue
		}

		mgr.entries[job.key] = schedulerEntry{
			entryID: entryID,
			spec:    job.spec,
			name:    job.name,
			enabled: true,
			fn:      job.fn,
		}
	}

	c.Start()
	globalScheduler = mgr
	slog.Info("백그라운드 크론 스케줄러 시작됨", slog.Int("jobs", len(mgr.entries)))
}

// ListSchedules 는 등록된 모든 스케줄의 상태를 반환합니다.
func (m *SchedulerManager) ListSchedules() []ScheduleStatus {
	m.mu.RLock()
	defer m.mu.RUnlock()

	result := make([]ScheduleStatus, 0, len(m.entries))
	for key, entry := range m.entries {
		cronEntry := m.cron.Entry(entry.entryID)
		result = append(result, ScheduleStatus{
			Key:     key,
			Name:    entry.name,
			Spec:    entry.spec,
			Enabled: entry.enabled,
			NextRun: cronEntry.Next,
		})
	}
	return result
}

// SetEnabled 는 특정 스케줄의 활성화 상태를 변경합니다.
// 비활성화해도 cron Entry 자체는 유지되며(overhead 미미), fn 시작 시 enabled 플래그를 확인합니다.
func (m *SchedulerManager) SetEnabled(key string, enabled bool) bool {
	m.mu.Lock()
	defer m.mu.Unlock()

	entry, ok := m.entries[key]
	if !ok {
		return false
	}
	entry.enabled = enabled
	m.entries[key] = entry

	slog.Info("스케줄 상태 변경",
		slog.String("key", key),
		slog.String("name", entry.name),
		slog.Bool("enabled", enabled),
	)
	return true
}

// RunNow 는 특정 스케줄을 즉시 실행합니다 (활성화 여부 무관).
func (m *SchedulerManager) RunNow(key string) bool {
	m.mu.RLock()
	entry, ok := m.entries[key]
	m.mu.RUnlock()

	if !ok {
		return false
	}

	go func() {
		slog.Info("스케줄 즉시 실행 요청", slog.String("key", key), slog.String("name", entry.name))
		entry.fn()
	}()
	return true
}

// ─────────────── 작업 함수들 ───────────────

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

func runWeeklyQuestReset(questUsecase usecase.QuestUsecase) {
	slog.Info("주간 퀘스트 초기화 및 할당 작업 시작")
	if err := questUsecase.AssignAllUsersWeeklyQuests(context.Background()); err != nil {
		slog.Error("주간 퀘스트 초기화 중 오류 발생", slog.Any("error", err))
	} else {
		slog.Info("주간 퀘스트 초기화 및 할당 작업 완료")
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

func runMenuSeed(seedUsecase usecase.SeedUsecase) {
	slog.Info("월간 영양소 데이터 수집 시작 (식약처/USDA)")
	ctx := context.Background()
	if err := seedUsecase.SeedMenus(ctx, "all", 5000); err != nil {
		slog.Error("월간 영양소 데이터 수집 실패", slog.Any("error", err))
	} else {
		slog.Info("월간 영양소 데이터 수집 완료")
	}
}
