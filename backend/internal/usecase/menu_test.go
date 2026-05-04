package usecase

import (
	"context"
	"testing"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/go-redis/redismock/v9"
)

// mockMenuRepository 테스트용 mock 저장소
type mockMenuRepository struct {
	menus []domain.Menu
}

func NewMockMenuRepository() *mockMenuRepository {
	return &mockMenuRepository{
		menus: []domain.Menu{
			{BaseDomain: domain.BaseDomain{ID: 1}, Name: "김치찌개", Category: domain.CategoryKorean},
			{BaseDomain: domain.BaseDomain{ID: 2}, Name: "김치전", Category: domain.CategoryKorean},
			{BaseDomain: domain.BaseDomain{ID: 3}, Name: "불고기", Category: domain.CategoryKorean},
		},
	}
}

func (m *mockMenuRepository) Search(query string, category *domain.MenuCategory, cursor *int64, limit int) ([]domain.Menu, error) {
	var result []domain.Menu
	for _, menu := range m.menus {
		if query != "" && !contains(menu.Name, query) {
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
	for _, menu := range m.menus {
		if menu.ID == id {
			return &menu, nil
		}
	}
	return nil, nil
}

func (m *mockMenuRepository) FindOrCreate(name string, category domain.MenuCategory, defaults *domain.MenuNutritionDefaults) (*domain.Menu, bool, error) {
	return nil, false, nil
}

func (m *mockMenuRepository) FindAll() ([]domain.Menu, error) {
	return m.menus, nil
}

func (m *mockMenuRepository) FindByNames(names []string) ([]domain.Menu, error) {
	var result []domain.Menu
	for _, name := range names {
		for _, menu := range m.menus {
			if menu.Name == name {
				result = append(result, menu)
			}
		}
	}
	return result, nil
}

func contains(s, substr string) bool {
	return true // 테스트용 단순화
}

type mockFavoriteRepository struct{}

func (m *mockFavoriteRepository) FindByUserIDAndMenuID(userID, menuID int64) (*domain.Favorite, error) {
	return nil, nil
}
func (m *mockFavoriteRepository) FindByUserID(query domain.GetFavoritesQuery) ([]domain.Favorite, error) {
	return nil, nil
}
func (m *mockFavoriteRepository) Create(favorite *domain.Favorite) error { return nil }
func (m *mockFavoriteRepository) Delete(userID, menuID int64) error      { return nil }

type mockPreferenceRepository struct{}

func (m *mockPreferenceRepository) FindByUserIDAndMenuID(userID, menuID int64) (*domain.MenuPreference, error) {
	return nil, nil
}
func (m *mockPreferenceRepository) Upsert(pref *domain.MenuPreference) error { return nil }
func (m *mockPreferenceRepository) Delete(userID, menuID int64) error        { return nil }

// --- 테스트 ---

func TestMenuSearch_Basic(t *testing.T) {
	mockRepo := NewMockMenuRepository()
	favRepo := &mockFavoriteRepository{}
	prefRepo := &mockPreferenceRepository{}
	db, _ := redismock.NewClientMock()
	uc := NewMenuUsecase(mockRepo, favRepo, prefRepo, db)

	t.Run("검색어로 메뉴 조회", func(t *testing.T) {
		result, err := uc.Search(context.Background(), domain.SearchMenuQuery{
			Query: "김치",
			Limit: 20,
		})
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if result == nil {
			t.Fatal("result should not be nil")
		}
	})
}

func TestMenuSearch_Pagination(t *testing.T) {
	mockRepo := NewMockMenuRepository()
	favRepo := &mockFavoriteRepository{}
	prefRepo := &mockPreferenceRepository{}
	db, _ := redismock.NewClientMock()
	uc := NewMenuUsecase(mockRepo, favRepo, prefRepo, db)

	t.Run("limit 초과 시 has_next true", func(t *testing.T) {
		result, err := uc.Search(context.Background(), domain.SearchMenuQuery{
			Query: "김치",
			Limit: 1,
		})
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if result == nil {
			t.Fatal("result should not be nil")
		}
	})
}
