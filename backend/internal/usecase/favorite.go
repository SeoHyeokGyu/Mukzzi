package usecase

import (
	"context"
	"errors"
	"strconv"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
	"gorm.io/gorm"
)

// FavoriteUsecase 즐겨찾기 유즈케이스 인터페이스
type FavoriteUsecase interface {
	// Add 즐겨찾기 추가 (이미 있으면 무시)
	Add(ctx context.Context, userID, menuID int64) error

	// Remove 즐겨찾기 제거 (없으면 무시)
	Remove(ctx context.Context, userID, menuID int64) error

	// GetList 즐겨찾기 목록 조회
	GetList(ctx context.Context, query domain.GetFavoritesQuery) (*domain.GetFavoritesResult, error)
}

type favoriteUsecaseImpl struct {
	favoriteRepository repository.FavoriteRepository
	menuRepository     repository.MenuRepository
}

func NewFavoriteUsecase(
	favoriteRepository repository.FavoriteRepository,
	menuRepository repository.MenuRepository,
) FavoriteUsecase {
	return &favoriteUsecaseImpl{
		favoriteRepository: favoriteRepository,
		menuRepository:     menuRepository,
	}
}

func (u *favoriteUsecaseImpl) Add(ctx context.Context, userID, menuID int64) error {
	// 메뉴 존재 확인
	menu, err := u.menuRepository.FindByID(menuID)
	if err != nil {
		return err
	}
	if menu == nil {
		return errors.New("menu not found")
	}

	// 이미 즐겨찾기 되어 있으면 무시
	existing, err := u.favoriteRepository.FindByUserIDAndMenuID(userID, menuID)
	if err != nil {
		return err
	}
	if existing != nil {
		return nil
	}

	return u.favoriteRepository.Create(&domain.Favorite{
		UserID: userID,
		MenuID: menuID,
	})
}

func (u *favoriteUsecaseImpl) Remove(ctx context.Context, userID, menuID int64) error {
	err := u.favoriteRepository.Delete(userID, menuID)
	// 없는 것을 제거하려 할 때는 에러로 처리하지 않음
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil
	}
	return err
}

func (u *favoriteUsecaseImpl) GetList(ctx context.Context, query domain.GetFavoritesQuery) (*domain.GetFavoritesResult, error) {
	if query.Limit <= 0 {
		query.Limit = 20
	}
	if query.Limit > 50 {
		query.Limit = 50
	}

	// 한 개 더 조회해서 다음 페이지 여부 판단
	query.Limit++
	favorites, err := u.favoriteRepository.FindByUserID(query)
	if err != nil {
		return nil, err
	}
	query.Limit--

	hasNext := len(favorites) > query.Limit
	if hasNext {
		favorites = favorites[:query.Limit]
	}

	var nextCursor *string
	if hasNext && len(favorites) > 0 {
		last := favorites[len(favorites)-1]
		s := strconv.FormatInt(last.ID, 10)
		nextCursor = &s
	}

	return &domain.GetFavoritesResult{
		Favorites:  favorites,
		NextCursor: nextCursor,
		HasNext:    hasNext,
		Limit:      query.Limit,
	}, nil
}
