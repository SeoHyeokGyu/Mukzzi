package repository

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

// MenuRepository 메뉴 저장소 인터페이스
type MenuRepository interface {
	// Search 메뉴 검색 (USER 포함, 공식 소스 우선 정렬)
	Search(db *gorm.DB, query string, category *domain.MenuCategory, cursor *int64, limit int) ([]domain.Menu, error)

	// FindByID 메뉴 ID로 조회
	FindByID(db *gorm.DB, id int64) (*domain.Menu, error)

	// FindOrCreate 없으면 자동 생성
	FindOrCreate(db *gorm.DB, name string, category domain.MenuCategory, defaults *domain.MenuNutritionDefaults) (*domain.Menu, bool, error)
}

// menuRepositoryImpl 메뉴 저장소 구현체
type menuRepositoryImpl struct{}

// NewMenuRepository 메뉴 저장소 생성
func NewMenuRepository() MenuRepository {
	return &menuRepositoryImpl{}
}

// Search 메뉴 검색
func (r *menuRepositoryImpl) Search(db *gorm.DB, query string, category *domain.MenuCategory, cursor *int64, limit int) ([]domain.Menu, error) {
	var menus []domain.Menu

	q := db.
		Where("name % ?", query).
		Order("CASE WHEN source != 'USER' THEN 0 ELSE 1 END, name")

	if category != nil {
		q = q.Where("category = ?", *category)
	}
	if cursor != nil {
		q = q.Where("id > ?", *cursor)
	}

	if err := q.Limit(limit).Find(&menus).Error; err != nil {
		return nil, err
	}
	return menus, nil
}

// FindByID 메뉴 ID로 조회
func (r *menuRepositoryImpl) FindByID(db *gorm.DB, id int64) (*domain.Menu, error) {
	var menu domain.Menu
	if err := db.Where("id = ?", id).First(&menu).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &menu, nil
}

// FindOrCreate 없으면 자동 생성
func (r *menuRepositoryImpl) FindOrCreate(db *gorm.DB, name string, category domain.MenuCategory, defaults *domain.MenuNutritionDefaults) (*domain.Menu, bool, error) {
	menu := domain.Menu{
		Name:                name,
		Category:            category,
		Source:              domain.SourceUser,
		DefaultCalories:     defaults.Calories,
		DefaultCarbs:        defaults.Carbs,
		DefaultProtein:      defaults.Protein,
		DefaultFat:          defaults.Fat,
		DefaultFiber:        defaults.Fiber,
		DefaultVitaminScore: defaults.VitaminScore,
	}

	result := db.
		Where(domain.Menu{Name: name, Category: category}).
		Clauses(clause.OnConflict{DoNothing: true}).
		FirstOrCreate(&menu)

	if result.Error != nil {
		return nil, false, result.Error
	}

	created := result.RowsAffected == 1
	return &menu, created, nil
}
