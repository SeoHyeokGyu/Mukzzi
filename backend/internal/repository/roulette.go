package repository

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
)

type RouletteCandidate struct {
	Menu       domain.Menu
	IsFavorite bool
	Grade      string
}

type RouletteRepository interface {
	GetCandidates(userID int64) ([]RouletteCandidate, error)
}

type rouletteRepository struct {
	db *gorm.DB
}

func NewRouletteRepository(db *gorm.DB) RouletteRepository {
	return &rouletteRepository{db: db}
}

func (r *rouletteRepository) GetCandidates(userID int64) ([]RouletteCandidate, error) {
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
		Grade               string
		IsFavorite          bool
	}

	var rows []scanRow
	err := r.db.Raw(`
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
			COALESCE(ma.grade, 'NONE')  AS grade,
			(f.id IS NOT NULL)           AS is_favorite
		FROM menus m
		LEFT JOIN masteries ma
			ON ma.menu_id = m.id
			AND ma.user_id = ?
			AND ma.deleted_at IS NULL
		LEFT JOIN favorites f
			ON f.menu_id = m.id
			AND f.user_id = ?
			AND f.deleted_at IS NULL
		WHERE m.deleted_at IS NULL
		  AND (
		      f.id IS NOT NULL
		      OR ma.eat_count > 0
		      OR m.id IN (
		          SELECT menu_id
		          FROM masteries
		          WHERE deleted_at IS NULL
		          GROUP BY menu_id
		          ORDER BY SUM(eat_count) DESC
		          LIMIT 50
		      )
		  )
		  AND (
		      ma.last_eaten_at IS NULL
		      OR ma.last_eaten_at < NOW() - INTERVAL '3 days'
		  )
	`, userID, userID).Scan(&rows).Error
	if err != nil {
		return nil, err
	}

	candidates := make([]RouletteCandidate, 0, len(rows))
	for _, row := range rows {
		candidates = append(candidates, RouletteCandidate{
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
			IsFavorite: row.IsFavorite,
			Grade:      row.Grade,
		})
	}
	return candidates, nil
}
