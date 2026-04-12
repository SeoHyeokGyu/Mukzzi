package usecase

import (
	"context"
	"testing"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
)

// mockMenuRepository 테스트용 mock 저장소
type mockMenuRepository struct {
	menus       []domain.Menu
	favorites   map[int64][]int64                // userID -> []menuID
	preferences map[string]domain.PreferenceType // "userID:menuID" -> preference
}

func NewMockMenuRepository() *mockMenuRepository {
	return &mockMenuRepository{
		menus: []domain.Menu{
			{
				BaseDomain:      domain.BaseDomain{ID: 1, CreatedAt: time.Now(), UpdatedAt: time.Now()},
				Name:            "김치찌개",
				Category:        domain.CategoryKorean,
				Source:          domain.SourceMFDS,
				DefaultCalories: 550,
				DefaultCarbs:    15,
				DefaultProtein:  18,
				DefaultFat:      22,
			},
			{
				BaseDomain:      domain.BaseDomain{ID: 2, CreatedAt: time.Now(), UpdatedAt: time.Now()},
				Name:            "된장찌개",
				Category:        domain.CategoryKorean,
				Source:          domain.SourceMFDS,
				DefaultCalories: 480,
				DefaultCarbs:    12,
				DefaultProtein:  16,
				DefaultFat:      18,
			},
			{
				BaseDomain:      domain.BaseDomain{ID: 3, CreatedAt: time.Now(), UpdatedAt: time.Now()},
				Name:            "김치볶음밥",
				Category:        domain.CategoryKorean,
				Source:          domain.SourceUser,
				DefaultCalories: 500,
				DefaultCarbs:    80,
				DefaultProtein:  15,
				DefaultFat:      12,
			},
			{
				BaseDomain:      domain.BaseDomain{ID: 4, CreatedAt: time.Now(), UpdatedAt: time.Now()},
				Name:            "짜장면",
				Category:        domain.CategoryChinese,
				Source:          domain.SourceMFDS,
				DefaultCalories: 650,
				DefaultCarbs:    95,
				DefaultProtein:  18,
				DefaultFat:      18,
			},
		},
		favorites:   make(map[int64][]int64),
		preferences: make(map[string]domain.PreferenceType),
	}
}

func (m *mockMenuRepository) Search(query string, category *domain.MenuCategory, cursor *int64, limit int) ([]domain.Menu, error) {
	var result []domain.Menu
	for _, menu := range m.menus {
		if len(query) > 0 && !contains(menu.Name, query) {
			continue
		}
		if category != nil && menu.Category != *category {
			continue
		}
		if cursor != nil && menu.ID <= *cursor {
			continue
		}
		result = append(result, menu)
		if len(result) >= limit {
			break
		}
	}
	return result, nil
}

func (m *mockMenuRepository) FindByID(id int64) (*domain.Menu, error) {
	for i := range m.menus {
		if m.menus[i].ID == id {
			return &m.menus[i], nil
		}
	}
	return nil, nil
}

func (m *mockMenuRepository) FindOrCreate(name string, category domain.MenuCategory, defaults *domain.MenuNutritionDefaults) (*domain.Menu, bool, error) {
	for i := range m.menus {
		if m.menus[i].Name == name && m.menus[i].Category == category {
			return &m.menus[i], false, nil
		}
	}
	menu := domain.Menu{
		BaseDomain:      domain.BaseDomain{ID: int64(len(m.menus) + 1), CreatedAt: time.Now(), UpdatedAt: time.Now()},
		Name:            name,
		Category:        category,
		Source:          domain.SourceUser,
		DefaultCalories: defaults.Calories,
		DefaultCarbs:    defaults.Carbs,
		DefaultProtein:  defaults.Protein,
		DefaultFat:      defaults.Fat,
		DefaultFiber:    defaults.Fiber,
	}
	m.menus = append(m.menus, menu)
	return &menu, true, nil
}

// 헬퍼
func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(substr) == 0 ||
		func() bool {
			for i := 0; i <= len(s)-len(substr); i++ {
				if s[i:i+len(substr)] == substr {
					return true
				}
			}
			return false
		}())
}

// --- 테스트 ---

func TestMenuSearch_Basic(t *testing.T) {
	mockRepo := NewMockMenuRepository()
	uc := NewMenuUsecase(mockRepo)

	t.Run("검색어로 메뉴 조회", func(t *testing.T) {
		result, err := uc.Search(context.Background(), domain.SearchMenuQuery{
			Query: "김치",
			Limit: 20,
		})
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if len(result.Menus) == 0 {
			t.Error("검색 결과가 없습니다")
		}
	})

	t.Run("빈 검색어는 에러 반환", func(t *testing.T) {
		_, err := uc.Search(context.Background(), domain.SearchMenuQuery{
			Query: "",
			Limit: 20,
		})
		if err == nil {
			t.Error("빈 검색어에 대해 에러가 반환되어야 합니다")
		}
	})

	t.Run("카테고리 필터", func(t *testing.T) {
		category := domain.CategoryChinese
		result, err := uc.Search(context.Background(), domain.SearchMenuQuery{
			Query:    "짜장",
			Category: &category,
			Limit:    20,
		})
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		for _, menu := range result.Menus {
			if menu.Category != domain.CategoryChinese {
				t.Errorf("카테고리 필터가 적용되지 않았습니다: %s", menu.Category)
			}
		}
	})
}

func TestMenuSearch_Pagination(t *testing.T) {
	mockRepo := NewMockMenuRepository()
	uc := NewMenuUsecase(mockRepo)

	t.Run("limit 초과 시 has_next true", func(t *testing.T) {
		result, err := uc.Search(context.Background(), domain.SearchMenuQuery{
			Query: "김치",
			Limit: 1,
		})
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if !result.HasNext {
			t.Error("has_next가 true여야 합니다")
		}
		if result.NextCursor == nil {
			t.Error("next_cursor가 있어야 합니다")
		}
	})

	t.Run("limit 0이면 기본값 20 적용", func(t *testing.T) {
		result, err := uc.Search(context.Background(), domain.SearchMenuQuery{
			Query: "김치",
			Limit: 0,
		})
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if result.Limit != 20 {
			t.Errorf("기본 limit은 20이어야 합니다. got: %d", result.Limit)
		}
	})

	t.Run("limit 50 초과 시 50으로 제한", func(t *testing.T) {
		result, err := uc.Search(context.Background(), domain.SearchMenuQuery{
			Query: "김치",
			Limit: 100,
		})
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if result.Limit != 50 {
			t.Errorf("최대 limit은 50이어야 합니다. got: %d", result.Limit)
		}
	})
}
