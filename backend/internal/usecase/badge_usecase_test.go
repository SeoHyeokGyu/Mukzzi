package usecase

import (
	"testing"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
)

// mockBadgeRepository 테스트용 mock 저장소
type mockBadgeRepository struct {
	badges      []domain.Badge
	userBadges  map[int64][]domain.UserBadge
}

// NewMockBadgeRepository mock 저장소 생성
func NewMockBadgeRepository() *mockBadgeRepository {
	return &mockBadgeRepository{
		badges: []domain.Badge{
			{
				BaseDomain:  domain.BaseDomain{ID: 1, CreatedAt: time.Now()},
				Code:        "FIRST_MEAL",
				Name:        "첫 식사",
				Description: "첫 식사를 기록했어요",
				IconURL:     "https://example.com/first_meal.png",
			},
			{
				BaseDomain:  domain.BaseDomain{ID: 2, CreatedAt: time.Now()},
				Code:        "SEVEN_STREAK",
				Name:        "7일 연속",
				Description: "7일 연속으로 식사를 기록했어요",
				IconURL:     "https://example.com/seven_streak.png",
			},
			{
				BaseDomain:  domain.BaseDomain{ID: 3, CreatedAt: time.Now()},
				Code:        "LEVEL_10",
				Name:        "레벨 10",
				Description: "레벨 10에 도달했어요",
				IconURL:     "https://example.com/level_10.png",
			},
			{
				BaseDomain:  domain.BaseDomain{ID: 4, CreatedAt: time.Now()},
				Code:        "MENU_MASTER",
				Name:        "메뉴 마스터",
				Description: "5가지 메뉴를 마스터했어요",
				IconURL:     "https://example.com/menu_master.png",
			},
			{
				BaseDomain:  domain.BaseDomain{ID: 5, CreatedAt: time.Now()},
				Code:        "SOCIAL_BUTTERFLY",
				Name:        "소셜 나비",
				Description: "10명과 친구가 되었어요",
				IconURL:     "https://example.com/social_butterfly.png",
			},
		},
		userBadges: make(map[int64][]domain.UserBadge),
	}
}

// FindAllBadges mock 구현
func (m *mockBadgeRepository) FindAllBadges(limit int, offset int) ([]domain.Badge, error) {
	if offset >= len(m.badges) {
		return []domain.Badge{}, nil
	}
	end := offset + limit
	if end > len(m.badges) {
		end = len(m.badges)
	}
	return m.badges[offset:end], nil
}

// CountAllBadges mock 구현
func (m *mockBadgeRepository) CountAllBadges() (int64, error) {
	return int64(len(m.badges)), nil
}

// FindUserAcquiredBadges mock 구현
func (m *mockBadgeRepository) FindUserAcquiredBadges(userID int64) ([]domain.UserBadge, error) {
	if badges, ok := m.userBadges[userID]; ok {
		return badges, nil
	}
	return []domain.UserBadge{}, nil
}

// FindBadgeByID mock 구현
func (m *mockBadgeRepository) FindBadgeByID(badgeID int64) (*domain.Badge, error) {
	for i := range m.badges {
		if m.badges[i].ID == badgeID {
			return &m.badges[i], nil
		}
	}
	return nil, nil
}

// CreateUserBadge mock 구현
func (m *mockBadgeRepository) CreateUserBadge(userBadge *domain.UserBadge) error {
	m.userBadges[userBadge.UserID] = append(m.userBadges[userBadge.UserID], *userBadge)
	return nil
}

// FindUserBadgeByID mock 구현
func (m *mockBadgeRepository) FindUserBadgeByID(userID, badgeID int64) (*domain.UserBadge, error) {
	if badges, ok := m.userBadges[userID]; ok {
		for i := range badges {
			if badges[i].BadgeID == badgeID {
				return &badges[i], nil
			}
		}
	}
	return nil, nil
}

// 테스트: 모든 뱃지 조회
func TestGetBadges_AllBadges(t *testing.T) {
	mockRepo := NewMockBadgeRepository()
	mockRepo.userBadges[1] = []domain.UserBadge{
		{
			BaseDomain: domain.BaseDomain{ID: 100, CreatedAt: time.Now()},
			UserID:     1,
			BadgeID:    1,
			AcquiredAt: time.Now(),
		},
		{
			BaseDomain: domain.BaseDomain{ID: 101, CreatedAt: time.Now()},
			UserID:     1,
			BadgeID:    2,
			AcquiredAt: time.Now(),
		},
	}

	// TODO: 실제 BadgeUsecase 인스턴스 생성 (GORM DB 필요)
	// usecase := NewBadgeUsecase(mockRepo, db)

	testCases := []struct {
		name            string
		includeAcquired bool
		expectedCount   int
	}{
		{
			name:            "include all badges",
			includeAcquired: true,
			expectedCount:   5,
		},
		{
			name:            "exclude acquired badges",
			includeAcquired: false,
			expectedCount:   3, // LEVEL_10, MENU_MASTER, SOCIAL_BUTTERFLY
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// TODO: 실제 테스트 구현
			// result, err := usecase.GetBadges(context.Background(), domain.GetBadgesQuery{
			// 	UserID:          1,
			// 	IncludeAcquired: tc.includeAcquired,
			// 	Limit:           20,
			// })

			// if err != nil {
			// 	t.Fatalf("unexpected error: %v", err)
			// }

			// if len(result.Badges) != tc.expectedCount {
			// 	t.Errorf("expected %d badges, got %d", tc.expectedCount, len(result.Badges))
			// }
		})
	}
}

// 테스트: 페이지네이션
func TestGetBadges_Pagination(t *testing.T) {
	testCases := []struct {
		name          string
		limit         int
		expectedCount int
		expectedNext  bool
	}{
		{
			name:          "default limit",
			limit:         20,
			expectedCount: 5,
			expectedNext:  false,
		},
		{
			name:          "small limit",
			limit:         2,
			expectedCount: 2,
			expectedNext:  true,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// TODO: 실제 페이지네이션 테스트
			_ = tc
		})
	}
}

// 테스트: 획득 시각 필드
func TestGetBadges_AcquiredAtField(t *testing.T) {
	t.Run("acquired badge has acquired_at", func(t *testing.T) {
		// TODO: 획득한 뱃지의 acquired_at 필드 검증
	})

	t.Run("unacquired badge has no acquired_at", func(t *testing.T) {
		// TODO: 미획득 뱃지의 acquired_at 필드 없음 검증
	})
}

// 테스트: 사용자별 분리
func TestGetBadges_UserIsolation(t *testing.T) {
	t.Run("different users see different acquired badges", func(t *testing.T) {
		// TODO: 사용자별로 다른 획득 정보 보이는지 검증
	})
}

// 테스트: 쿼리 파라미터 검증
func TestGetBadges_QueryValidation(t *testing.T) {
	testCases := []struct {
		name          string
		query         domain.GetBadgesQuery
		shouldSucceed bool
	}{
		{
			name:          "valid query",
			query:         domain.GetBadgesQuery{UserID: 1, IncludeAcquired: true, Limit: 20},
			shouldSucceed: true,
		},
		{
			name:          "limit zero",
			query:         domain.GetBadgesQuery{UserID: 1, IncludeAcquired: true, Limit: 0},
			shouldSucceed: true, // 0이면 기본값 20으로 설정
		},
		{
			name:          "limit exceeds max",
			query:         domain.GetBadgesQuery{UserID: 1, IncludeAcquired: true, Limit: 100},
			shouldSucceed: true, // 100은 50으로 제한됨
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// TODO: 쿼리 유효성 검증 테스트
			_ = tc
		})
	}
}
