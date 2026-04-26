package repository

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

// MenuRepository 메뉴 저장소 인터페이스
type MenuRepository interface {
	// Search 메뉴 검색 (USER 포함, 공식 소스 우선 정렬)
	Search(query string, category *domain.MenuCategory, cursor *int64, limit int) ([]domain.Menu, error)

	// FindByID 메뉴 ID로 조회 (없으면 nil 반환)
	FindByID(id int64) (*domain.Menu, error)

	// FindOrCreate 없으면 자동 생성, created=false이면 이미 존재
	FindOrCreate(name string, category domain.MenuCategory, defaults *domain.MenuNutritionDefaults) (*domain.Menu, bool, error)

	// Redis 동기화를 위한 전체 조회
	FindAll() ([]domain.Menu, error)
	// Redis 검색 결과 기반 상세 조회
	FindByNames(names []string) ([]domain.Menu, error)
}

// menuRepositoryImpl 메뉴 저장소 구현체
type menuRepositoryImpl struct {
	db *gorm.DB
}

// NewMenuRepository 메뉴 저장소 생성
func NewMenuRepository(db *gorm.DB) MenuRepository {
	return &menuRepositoryImpl{db: db}
}

// Search 메뉴 검색
func (r *menuRepositoryImpl) Search(query string, category *domain.MenuCategory, cursor *int64, limit int) ([]domain.Menu, error) {
	var menus []domain.Menu

	q := r.db.
		Where("name LIKE ?", "%"+query+"%").
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
func (r *menuRepositoryImpl) FindByID(id int64) (*domain.Menu, error) {
	var menu domain.Menu
	if err := r.db.Where("id = ?", id).First(&menu).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &menu, nil
}

// FindOrCreate 없으면 자동 생성
func (r *menuRepositoryImpl) FindOrCreate(name string, category domain.MenuCategory, defaults *domain.MenuNutritionDefaults) (*domain.Menu, bool, error) {
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

	result := r.db.
		Where(domain.Menu{Name: name, Category: category}).
		Clauses(clause.OnConflict{DoNothing: true}).
		FirstOrCreate(&menu)

	if result.Error != nil {
		return nil, false, result.Error
	}

	created := result.RowsAffected == 1
	return &menu, created, nil
}

func (r *menuRepositoryImpl) FindAll() ([]domain.Menu, error) {
	var menus []domain.Menu
	err := r.db.Find(&menus).Error
	return menus, err
}

func (r *menuRepositoryImpl) FindByNames(names []string) ([]domain.Menu, error) {
	if len(names) == 0 {
		return []domain.Menu{}, nil
	}
	var menus []domain.Menu
	err := r.db.Where("name IN ?", names).
		Order("CASE WHEN source != 'USER' THEN 0 ELSE 1 END, name").
		Find(&menus).Error
	return menus, err
}
