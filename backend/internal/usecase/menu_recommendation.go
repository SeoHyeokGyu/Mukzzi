package usecase

import (
	"context"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

const (
	recommendationLimit   = 20 // 최대 추천 메뉴 수
	recentExcludeDays     = 3  // 최근 N일 내 먹은 메뉴 제외
	recentHistoryDays     = 30 // 최근 기록 참고 범위
	favoriteWeight        = 3  // 즐겨찾기 가중치 (점수)
	likeWeight            = 2  // 좋아요 가중치
	recentWeight          = 1  // 최근 기록 가중치
	minSignalsForPersonal = 1  // 개인화 추천 최소 신호 수
)

// RecommendationResult 추천 결과
type RecommendationResult struct {
	Menus      []domain.Menu
	IsPersonal bool // true: 개인화 추천, false: 인기 메뉴 폴백
}

// MenuRecommendationUsecase 메뉴 추천 유즈케이스 인터페이스
type MenuRecommendationUsecase interface {
	// GetRecommendations 선호도 기반 추천 목록 반환
	// 데이터 부족 시 인기 메뉴 폴백
	GetRecommendations(ctx context.Context, userID int64) (*RecommendationResult, error)
}

type menuRecommendationUsecase struct {
	recRepo repository.MenuRecommendationRepository
}

func NewMenuRecommendationUsecase(recRepo repository.MenuRecommendationRepository) MenuRecommendationUsecase {
	return &menuRecommendationUsecase{recRepo: recRepo}
}

func (u *menuRecommendationUsecase) GetRecommendations(ctx context.Context, userID int64) (*RecommendationResult, error) {
	now := time.Now()

	// 1. 제외 목록: 최근 3일 내 먹은 메뉴
	excludeIDs, err := u.recRepo.FindExcludeMenuIDs(userID, now.AddDate(0, 0, -recentExcludeDays))
	if err != nil {
		return nil, err
	}
	excludeSet := toSet(excludeIDs)

	// 2. 싫어요 메뉴도 제외
	dislikedIDs, err := u.recRepo.FindDislikedMenuIDs(userID)
	if err != nil {
		return nil, err
	}
	for _, id := range dislikedIDs {
		excludeSet[id] = struct{}{}
	}

	// 3. 신호 수집
	favoriteIDs, err := u.recRepo.FindFavoriteMenuIDs(userID)
	if err != nil {
		return nil, err
	}
	likedIDs, err := u.recRepo.FindLikedMenuIDs(userID)
	if err != nil {
		return nil, err
	}
	recentIDs, err := u.recRepo.FindRecentMenuIDs(userID, now.AddDate(0, 0, -recentHistoryDays))
	if err != nil {
		return nil, err
	}

	// 4. 신호가 너무 적으면 인기 메뉴 폴백
	totalSignals := len(favoriteIDs) + len(likedIDs) + len(recentIDs)
	if totalSignals < minSignalsForPersonal {
		menus, err := u.recRepo.FindPopularMenusByCategory(toSlice(excludeSet), recommendationLimit)
		if err != nil {
			return nil, err
		}
		return &RecommendationResult{Menus: menus, IsPersonal: false}, nil
	}

	// 5. 가중치 기반 점수 계산
	scores := make(map[int64]int)
	for _, id := range favoriteIDs {
		if _, excluded := excludeSet[id]; !excluded {
			scores[id] += favoriteWeight
		}
	}
	for _, id := range likedIDs {
		if _, excluded := excludeSet[id]; !excluded {
			scores[id] += likeWeight
		}
	}
	for _, id := range recentIDs {
		if _, excluded := excludeSet[id]; !excluded {
			scores[id] += recentWeight
		}
	}

	if len(scores) == 0 {
		// 모든 신호가 제외 목록에 걸린 경우 폴백
		menus, err := u.recRepo.FindPopularMenusByCategory(toSlice(excludeSet), recommendationLimit)
		if err != nil {
			return nil, err
		}
		return &RecommendationResult{Menus: menus, IsPersonal: false}, nil
	}

	// 6. 점수 내림차순 정렬 후 상위 ID 추출
	rankedIDs := rankByScore(scores, recommendationLimit)

	// 7. 메뉴 조회 (순서 유지)
	menus, err := u.recRepo.FindMenusByIDs(rankedIDs)
	if err != nil {
		return nil, err
	}

	// 8. 추천 수가 부족하면 인기 메뉴로 채우기
	if len(menus) < recommendationLimit {
		filledExclude := toSlice(excludeSet)
		for _, m := range menus {
			filledExclude = append(filledExclude, m.ID)
		}
		fallback, err := u.recRepo.FindPopularMenusByCategory(filledExclude, recommendationLimit-len(menus))
		if err == nil {
			menus = append(menus, fallback...)
		}
	}

	return &RecommendationResult{Menus: menus, IsPersonal: true}, nil
}

// ─────────────────────────────────────────
// 내부 헬퍼
// ─────────────────────────────────────────

func toSet(ids []int64) map[int64]struct{} {
	s := make(map[int64]struct{}, len(ids))
	for _, id := range ids {
		s[id] = struct{}{}
	}
	return s
}

func toSlice(s map[int64]struct{}) []int64 {
	ids := make([]int64, 0, len(s))
	for id := range s {
		ids = append(ids, id)
	}
	return ids
}

// rankByScore 점수 내림차순으로 상위 limit개의 ID를 반환합니다.
func rankByScore(scores map[int64]int, limit int) []int64 {
	type entry struct {
		id    int64
		score int
	}
	entries := make([]entry, 0, len(scores))
	for id, score := range scores {
		entries = append(entries, entry{id, score})
	}
	// 간단한 삽입 정렬 (메뉴 수가 많지 않으므로 충분)
	for i := 1; i < len(entries); i++ {
		key := entries[i]
		j := i - 1
		for j >= 0 && entries[j].score < key.score {
			entries[j+1] = entries[j]
			j--
		}
		entries[j+1] = key
	}
	if limit > len(entries) {
		limit = len(entries)
	}
	result := make([]int64, limit)
	for i := 0; i < limit; i++ {
		result[i] = entries[i].id
	}
	return result
}
