package repository

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/lib/pq"
	"gorm.io/gorm"
)

type FilterCandidate struct {
	Menu  domain.Menu
	Count int
}

type MenuFilterRepository interface {
	GetByTagsForUser(userID int64, weathers []string, moods []string, limit int) ([]FilterCandidate, error)
	GetByTagsGlobal(weathers []string, moods []string, limit int) ([]FilterCandidate, error)
}

type menuFilterRepository struct {
	db *gorm.DB
}

func NewMenuFilterRepository(db *gorm.DB) MenuFilterRepository {
	return &menuFilterRepository{db: db}
}

func (r *menuFilterRepository) GetByTagsForUser(userID int64, weathers []string, moods []string, limit int) ([]FilterCandidate, error) {
	return r.queryFilter(&userID, weathers, moods, limit)
}

func (r *menuFilterRepository) GetByTagsGlobal(weathers []string, moods []string, limit int) ([]FilterCandidate, error) {
	return r.queryFilter(nil, weathers, moods, limit)
}

func (r *menuFilterRepository) queryFilter(userID *int64, weathers []string, moods []string, limit int) ([]FilterCandidate, error) {
	type scanRow struct {
		ID                  int64
		Name                string
		Category            domain.MenuCategory
		DefaultCalories     float64
		DefaultCarbs        float64
		DefaultProtein      float64
		DefaultFat          float64
		DefaultFiber        float64
		DefaultVitaminScore float64
		Source              domain.MenuSource
		Count               int
	}

	sql := `
		SELECT
			m.id,
			m.name,
			m.category,
			m.default_calories,
			m.default_carbs,
			m.default_protein,
			m.default_fat,
			m.default_fiber,
			m.default_vitamin_score,
			m.source,
			COUNT(*) AS count
		FROM meal_records mr
		JOIN menus m ON m.id = mr.menu_id AND m.deleted_at IS NULL
		WHERE mr.deleted_at IS NULL
		  AND mr.menu_id IS NOT NULL
	`
	args := []interface{}{}

	if userID != nil {
		sql += " AND mr.user_id = ?"
		args = append(args, *userID)
	}
	if len(weathers) > 0 {
		sql += " AND mr.weather_tag = ANY(?)"
		args = append(args, pq.Array(weathers))
	}
	if len(moods) > 0 {
		sql += " AND mr.mood_tag = ANY(?)"
		args = append(args, pq.Array(moods))
	}

	sql += `
		GROUP BY m.id, m.name, m.category, m.default_calories, m.default_carbs,
		         m.default_protein, m.default_fat, m.default_fiber, m.default_vitamin_score, m.source
		ORDER BY count DESC
		LIMIT ?
	`
	args = append(args, limit)

	var rows []scanRow
	if err := r.db.Raw(sql, args...).Scan(&rows).Error; err != nil {
		return nil, err
	}

	candidates := make([]FilterCandidate, 0, len(rows))
	for _, row := range rows {
		candidates = append(candidates, FilterCandidate{
			Menu: domain.Menu{
				BaseDomain:          domain.BaseDomain{ID: row.ID},
				Name:                row.Name,
				Category:            row.Category,
				DefaultCalories:     row.DefaultCalories,
				DefaultCarbs:        row.DefaultCarbs,
				DefaultProtein:      row.DefaultProtein,
				DefaultFat:          row.DefaultFat,
				DefaultFiber:        row.DefaultFiber,
				DefaultVitaminScore: row.DefaultVitaminScore,
				Source:              row.Source,
			},
			Count: row.Count,
		})
	}
	return candidates, nil
}
