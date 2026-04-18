package repository

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
)

// TitleRepository 칭호 저장소 인터페이스
type TitleRepository interface {
	// FindAll 전체 칭호 목록 조회
	FindAll() ([]domain.Title, error)

	// FindByID 칭호 ID로 조회
	FindByID(titleID int64) (*domain.Title, error)

	// FindUserTitles 사용자가 획득한 칭호 목록 조회
	FindUserTitles(userID int64) ([]domain.UserTitle, error)

	// FindUserTitleByID 특정 칭호 획득 여부 조회
	FindUserTitleByID(userID, titleID int64) (*domain.UserTitle, error)

	// CreateUserTitle 칭호 지급
	CreateUserTitle(userTitle *domain.UserTitle) error
}

type titleRepositoryImpl struct {
	db *gorm.DB
}

func NewTitleRepository(db *gorm.DB) TitleRepository {
	return &titleRepositoryImpl{db: db}
}

func (r *titleRepositoryImpl) FindAll() ([]domain.Title, error) {
	var titles []domain.Title
	if err := r.db.Order("id ASC").Find(&titles).Error; err != nil {
		return nil, err
	}
	return titles, nil
}

func (r *titleRepositoryImpl) FindByID(titleID int64) (*domain.Title, error) {
	var title domain.Title
	if err := r.db.First(&title, titleID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &title, nil
}

func (r *titleRepositoryImpl) FindUserTitles(userID int64) ([]domain.UserTitle, error) {
	var userTitles []domain.UserTitle
	if err := r.db.Preload("Title").
		Where("user_id = ?", userID).
		Order("id DESC").
		Find(&userTitles).Error; err != nil {
		return nil, err
	}
	return userTitles, nil
}

func (r *titleRepositoryImpl) FindUserTitleByID(userID, titleID int64) (*domain.UserTitle, error) {
	var userTitle domain.UserTitle
	if err := r.db.Where("user_id = ? AND title_id = ?", userID, titleID).
		First(&userTitle).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &userTitle, nil
}

func (r *titleRepositoryImpl) CreateUserTitle(userTitle *domain.UserTitle) error {
	return r.db.Create(userTitle).Error
}
