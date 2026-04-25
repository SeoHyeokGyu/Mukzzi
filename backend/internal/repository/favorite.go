package repository

import (
	"strconv"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
)

// FavoriteRepository 즐겨찾기 저장소 인터페이스
type FavoriteRepository interface {
	// FindByUserIDAndMenuID 즐겨찾기 단건 조회 (없으면 nil)
	FindByUserIDAndMenuID(userID, menuID int64) (*domain.Favorite, error)

	// FindByUserID 즐겨찾기 목록 조회 (cursor 기반)
	FindByUserID(query domain.GetFavoritesQuery) ([]domain.Favorite, error)

	// Create 즐겨찾기 추가
	Create(favorite *domain.Favorite) error

	// Delete 즐겨찾기 제거
	Delete(userID, menuID int64) error
}

type favoriteRepositoryImpl struct {
	db *gorm.DB
}

func NewFavoriteRepository(db *gorm.DB) FavoriteRepository {
	return &favoriteRepositoryImpl{db: db}
}

func (r *favoriteRepositoryImpl) FindByUserIDAndMenuID(userID, menuID int64) (*domain.Favorite, error) {
	var fav domain.Favorite
	if err := r.db.
		Where("user_id = ? AND menu_id = ?", userID, menuID).
		First(&fav).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &fav, nil
}

func (r *favoriteRepositoryImpl) FindByUserID(query domain.GetFavoritesQuery) ([]domain.Favorite, error) {
	var favorites []domain.Favorite

	q := r.db.Preload("Menu").
		Where("user_id = ?", query.UserID).
		Order("id DESC")

	if query.Cursor != nil {
		q = q.Where("id < ?", *query.Cursor)
	}

	if err := q.Limit(query.Limit).Find(&favorites).Error; err != nil {
		return nil, err
	}
	return favorites, nil
}

func (r *favoriteRepositoryImpl) Create(favorite *domain.Favorite) error {
	// soft delete된 레코드 포함해서 먼저 조회
	var existing domain.Favorite
	err := r.db.Unscoped().
		Where("user_id = ? AND menu_id = ?", favorite.UserID, favorite.MenuID).
		First(&existing).Error

	if err == gorm.ErrRecordNotFound {
		// 완전히 새 레코드
		return r.db.Create(favorite).Error
	}
	if err != nil {
		return err
	}

	// soft delete된 레코드 복구 (deleted_at을 NULL로)
	return r.db.Unscoped().Model(&existing).Update("deleted_at", nil).Error
}

func (r *favoriteRepositoryImpl) Delete(userID, menuID int64) error {
	result := r.db.
		Where("user_id = ? AND menu_id = ?", userID, menuID).
		Delete(&domain.Favorite{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// nextCursorFromFavorites 마지막 항목 ID를 커서 문자열로 변환
func nextCursorFromFavorites(favorites []domain.Favorite) *string {
	if len(favorites) == 0 {
		return nil
	}
	s := strconv.FormatInt(favorites[len(favorites)-1].ID, 10)
	return &s
}
