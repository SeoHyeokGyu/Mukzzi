package usecase

import (
	"context"
	"errors"
	"strconv"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

// MenuUsecase 메뉴 유즈케이스 인터페이스
type MenuUsecase interface {
	Search(ctx context.Context, query domain.SearchMenuQuery) (*domain.SearchMenuResult, error)
}

// menuUsecaseImpl 메뉴 유즈케이스 구현체
type menuUsecaseImpl struct {
	menuRepository repository.MenuRepository
}

// NewMenuUsecase 메뉴 유즈케이스 생성
func NewMenuUsecase(menuRepository repository.MenuRepository) MenuUsecase {
	return &menuUsecaseImpl{
		menuRepository: menuRepository,
	}
}

// 카테고리별 영양소 기본값
var categoryNutritionDefaults = map[domain.MenuCategory]domain.MenuNutritionDefaults{
	domain.CategoryKorean:   {Calories: 550, Carbs: 80, Protein: 20, Fat: 15, Fiber: 4, VitaminScore: 30},
	domain.CategoryChinese:  {Calories: 650, Carbs: 85, Protein: 18, Fat: 22, Fiber: 3, VitaminScore: 20},
	domain.CategoryJapanese: {Calories: 500, Carbs: 70, Protein: 22, Fat: 12, Fiber: 3, VitaminScore: 25},
	domain.CategoryWestern:  {Calories: 700, Carbs: 60, Protein: 30, Fat: 30, Fiber: 4, VitaminScore: 20},
	domain.CategorySnack:    {Calories: 300, Carbs: 45, Protein: 5, Fat: 12, Fiber: 1, VitaminScore: 10},
	domain.CategoryCafe:     {Calories: 250, Carbs: 40, Protein: 6, Fat: 8, Fiber: 1, VitaminScore: 10},
	domain.CategoryOther:    {Calories: 500, Carbs: 70, Protein: 15, Fat: 15, Fiber: 3, VitaminScore: 20},
}

func nutritionDefaultsByCategory(category domain.MenuCategory) domain.MenuNutritionDefaults {
	if defaults, ok := categoryNutritionDefaults[category]; ok {
		return defaults
	}
	return categoryNutritionDefaults[domain.CategoryOther]
}

// Search 메뉴 검색
func (u *menuUsecaseImpl) Search(ctx context.Context, query domain.SearchMenuQuery) (*domain.SearchMenuResult, error) {
	if query.Query == "" {
		return nil, errors.New("query is required")
	}
	if query.Limit <= 0 {
		query.Limit = 20
	}
	if query.Limit > 50 {
		query.Limit = 50
	}

	// 한 개 더 조회해서 다음 페이지 여부 판단
	menus, err := u.menuRepository.Search(query.Query, query.Category, query.Cursor, query.Limit+1)
	if err != nil {
		return nil, err
	}

	hasNext := len(menus) > query.Limit
	if hasNext {
		menus = menus[:query.Limit]
	}

	var nextCursor *string
	if hasNext {
		lastID := strconv.FormatInt(menus[len(menus)-1].ID, 10)
		nextCursor = &lastID
	}

	return &domain.SearchMenuResult{
		Menus:      menus,
		NextCursor: nextCursor,
		HasNext:    hasNext,
		Limit:      query.Limit,
	}, nil
}
