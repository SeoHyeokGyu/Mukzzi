package usecase

import (
	"context"
	"errors"
	"log/slog"
	"strconv"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
	"github.com/redis/go-redis/v9"
)

// MenuUsecase 메뉴 유즈케이스 인터페이스
type MenuUsecase interface {
	Search(ctx context.Context, query domain.SearchMenuQuery) (*domain.SearchMenuResult, error)
	Create(ctx context.Context, input domain.CreateMenuInput) (*domain.Menu, bool, error)
	FindByID(ctx context.Context, id int64, userID int64) (*MenuDetail, error) // domain. 제거
	SyncMenusToRedis(ctx context.Context) error
}

// MenuDetail 메뉴 상세 (즐겨찾기/선호도 포함)
type MenuDetail struct {
	Menu       domain.Menu
	IsFavorite bool
	Preference *domain.PreferenceType
}

// menuUsecaseImpl 메뉴 유즈케이스 구현체
type menuUsecaseImpl struct {
	menuRepository       repository.MenuRepository
	favoriteRepository   repository.FavoriteRepository
	preferenceRepository repository.PreferenceRepository
	rdb                  *redis.Client
}

// NewMenuUsecase 메뉴 유즈케이스 생성
func NewMenuUsecase(
	menuRepository repository.MenuRepository,
	favoriteRepository repository.FavoriteRepository,
	preferenceRepository repository.PreferenceRepository,
	rdb *redis.Client,
) MenuUsecase {
	return &menuUsecaseImpl{
		menuRepository:       menuRepository,
		favoriteRepository:   favoriteRepository,
		preferenceRepository: preferenceRepository,
		rdb:                  rdb,
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

const menuAutocompleteKey = "menus:autocomplete"

// Search 메뉴 검색 (ZSET 자동완성 우선 적용)
func (u *menuUsecaseImpl) Search(ctx context.Context, query domain.SearchMenuQuery) (*domain.SearchMenuResult, error) {
	if query.Query == "" {
		return nil, errors.New("query is required")
	}
	if query.Limit <= 0 {
		query.Limit = 20
	}

	var menus []domain.Menu
	var err error

	// 1. Redis ZSET에서 접두사 검색 시도 (자동완성용)
	// 카테고리 필터나 커서가 없는 단순 검색인 경우에만 ZSET 사용
	if query.Category == nil && query.Cursor == nil {
		op := redis.ZRangeBy{
			Min:    "[" + query.Query,
			Max:    "[" + query.Query + "\xff",
			Offset: 0,
			Count:  int64(query.Limit + 1),
		}
		names, zErr := u.rdb.ZRangeByLex(ctx, menuAutocompleteKey, &op).Result()
		if zErr == nil && len(names) > 0 {
			menus, err = u.menuRepository.FindByNames(names)
		} else {
			// ZSET에 결과가 없으면 DB LIKE 검색으로 Fallback
			menus, err = u.menuRepository.Search(query.Query, query.Category, query.Cursor, query.Limit+1)
		}
	} else {
		// 복합 필터 조건이 있으면 DB에서 검색
		menus, err = u.menuRepository.Search(query.Query, query.Category, query.Cursor, query.Limit+1)
	}

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

// Create 사용자 정의 메뉴 등록
func (u *menuUsecaseImpl) Create(ctx context.Context, input domain.CreateMenuInput) (*domain.Menu, bool, error) {
	defaults := nutritionDefaultsByCategory(input.Category)

	nutritionDefaults := &domain.MenuNutritionDefaults{
		Calories:     input.Calories,
		Carbs:        input.Carbs,
		Protein:      input.Protein,
		Fat:          input.Fat,
		Fiber:        input.Fiber,
		VitaminScore: defaults.VitaminScore,
	}
	if nutritionDefaults.Calories == 0 { nutritionDefaults.Calories = defaults.Calories }
	if nutritionDefaults.Carbs == 0 { nutritionDefaults.Carbs = defaults.Carbs }
	if nutritionDefaults.Protein == 0 { nutritionDefaults.Protein = defaults.Protein }
	if nutritionDefaults.Fat == 0 { nutritionDefaults.Fat = defaults.Fat }
	if nutritionDefaults.Fiber == 0 { nutritionDefaults.Fiber = defaults.Fiber }

	menu, created, err := u.menuRepository.FindOrCreate(input.Name, input.Category, nutritionDefaults)
	if err == nil && created {
		// 새로 생성된 메뉴는 Redis ZSET에 추가
		_ = u.rdb.ZAdd(ctx, menuAutocompleteKey, redis.Z{Score: 0, Member: menu.Name}).Err()
	}
	return menu, created, err
}

// FindByID 단일 메뉴 상세 조회 (즐겨찾기/선호도 포함)
func (u *menuUsecaseImpl) FindByID(ctx context.Context, id int64, userID int64) (*MenuDetail, error) {
	menu, err := u.menuRepository.FindByID(id)
	if err != nil {
		return nil, err
	}
	if menu == nil {
		return nil, nil
	}

	fav, _ := u.favoriteRepository.FindByUserIDAndMenuID(userID, id)
	pref, _ := u.preferenceRepository.FindByUserIDAndMenuID(userID, id)

	detail := &MenuDetail{
		Menu:       *menu,
		IsFavorite: fav != nil,
	}
	if pref != nil {
		detail.Preference = &pref.Preference
	}

	return detail, nil
}

func (u *menuUsecaseImpl) SyncMenusToRedis(ctx context.Context) error {
	menus, err := u.menuRepository.FindAll()
	if err != nil {
		return err
	}

	u.rdb.Del(ctx, menuAutocompleteKey)

	if len(menus) == 0 {
		return nil
	}

	zs := make([]redis.Z, len(menus))
	for i, m := range menus {
		zs[i] = redis.Z{
			Score:  0,
			Member: m.Name,
		}
	}

	err = u.rdb.ZAdd(ctx, menuAutocompleteKey, zs...).Err()
	if err != nil {
		slog.Error("Redis ZAdd 메뉴 일괄 추가 실패", slog.Any("error", err))
		return err
	}
	return nil
}
