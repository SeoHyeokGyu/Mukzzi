package repository

import (
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
)

// MenuRecommendationRepository 선호도 기반 메뉴 추천 저장소 인터페이스
type MenuRecommendationRepository interface {
	// FindFavoriteMenuIDs 즐겨찾기한 메뉴 ID 목록 조회
	FindFavoriteMenuIDs(userID int64) ([]int64, error)

	// FindRecentMenuIDs 최근 N일 내 식사한 메뉴 ID 목록 조회
	FindRecentMenuIDs(userID int64, since time.Time) ([]int64, error)

	// FindExcludeMenuIDs 최근 3일 내 식사한 메뉴 ID 목록 조회 (추천 제외용)
	FindExcludeMenuIDs(userID int64, since time.Time) ([]int64, error)

	// FindLikedMenuIDs 좋아요한 메뉴 ID 목록 조회
	FindLikedMenuIDs(userID int64) ([]int64, error)

	// FindDislikedMenuIDs 싫어요한 메뉴 ID 목록 조회
	FindDislikedMenuIDs(userID int64) ([]int64, error)

	// FindMenusByIDs ID 목록으로 메뉴 조회 (순서 보장)
	FindMenusByIDs(ids []int64) ([]domain.Menu, error)

	// FindPopularMenusByCategory 카테고리별 인기 메뉴 조회 (신규 유저 폴백용)
	FindPopularMenusByCategory(excludeIDs []int64, limit int) ([]domain.Menu, error)

	// FindUserAllergies 유저의 알레르기 문자열 조회
	FindUserAllergies(userID int64) (string, error)

	// FindMenuIDsByAllergens 알레르기 성분이 포함된 메뉴 ID 목록 조회
	FindMenuIDsByAllergens(allergens []string) ([]int64, error)
}

type menuRecommendationRepository struct {
	db *gorm.DB
}

func NewMenuRecommendationRepository(db *gorm.DB) MenuRecommendationRepository {
	return &menuRecommendationRepository{db: db}
}

func (r *menuRecommendationRepository) FindFavoriteMenuIDs(userID int64) ([]int64, error) {
	var ids []int64
	err := r.db.Model(&domain.Favorite{}).
		Where("user_id = ? AND deleted_at IS NULL", userID).
		Pluck("menu_id", &ids).Error
	return ids, err
}

func (r *menuRecommendationRepository) FindRecentMenuIDs(userID int64, since time.Time) ([]int64, error) {
	var ids []int64
	err := r.db.Model(&domain.MealRecord{}).
		Where("user_id = ? AND menu_id IS NOT NULL AND recorded_at >= ? AND deleted_at IS NULL", userID, since).
		Distinct("menu_id").
		Pluck("menu_id", &ids).Error
	return ids, err
}

func (r *menuRecommendationRepository) FindExcludeMenuIDs(userID int64, since time.Time) ([]int64, error) {
	return r.FindRecentMenuIDs(userID, since)
}

func (r *menuRecommendationRepository) FindLikedMenuIDs(userID int64) ([]int64, error) {
	var ids []int64
	err := r.db.Table("menu_preferences").
		Where("user_id = ? AND preference = ? AND deleted_at IS NULL", userID, domain.PreferenceLike).
		Pluck("menu_id", &ids).Error
	return ids, err
}

func (r *menuRecommendationRepository) FindDislikedMenuIDs(userID int64) ([]int64, error) {
	var ids []int64
	err := r.db.Table("menu_preferences").
		Where("user_id = ? AND preference = ? AND deleted_at IS NULL", userID, domain.PreferenceDislike).
		Pluck("menu_id", &ids).Error
	return ids, err
}

func (r *menuRecommendationRepository) FindMenusByIDs(ids []int64) ([]domain.Menu, error) {
	if len(ids) == 0 {
		return []domain.Menu{}, nil
	}
	var menus []domain.Menu
	err := r.db.Where("id IN ? AND deleted_at IS NULL", ids).Find(&menus).Error
	if err != nil {
		return nil, err
	}

	// 입력 순서대로 정렬 (우선순위 보장)
	idIndex := make(map[int64]int, len(ids))
	for i, id := range ids {
		idIndex[id] = i
	}
	ordered := make([]domain.Menu, len(menus))
	copy(ordered, menus)
	for i := 0; i < len(ordered)-1; i++ {
		for j := i + 1; j < len(ordered); j++ {
			if idIndex[ordered[i].ID] > idIndex[ordered[j].ID] {
				ordered[i], ordered[j] = ordered[j], ordered[i]
			}
		}
	}
	return ordered, nil
}

func (r *menuRecommendationRepository) FindPopularMenusByCategory(excludeIDs []int64, limit int) ([]domain.Menu, error) {
	// 카테고리 수(7개)로 나눠 카테고리별 상위 perCategory개씩 뽑은 뒤
	// 전체를 meal_count 내림차순으로 재정렬하여 limit개 반환
	const categoryCount = 7
	perCategory := limit / categoryCount
	if perCategory < 1 {
		perCategory = 1
	}

	excludeClause := ""
	if len(excludeIDs) > 0 {
		excludeClause = "AND m.id NOT IN @excludeIDs"
	}

	rawSQL := `
		SELECT id, name, category,
		       default_calories, default_carbs, default_protein,
		       default_fat, default_fiber, default_vitamin_score,
		       source, created_at, updated_at, deleted_at
		FROM (
			SELECT
				m.*,
				COUNT(mr.menu_id)                                        AS meal_count,
				ROW_NUMBER() OVER (
					PARTITION BY m.category
					ORDER BY COUNT(mr.menu_id) DESC, m.id ASC
				)                                                        AS rn
			FROM menus m
			LEFT JOIN meal_records mr
				ON m.id = mr.menu_id
				AND mr.deleted_at IS NULL
			WHERE m.deleted_at IS NULL
			` + excludeClause + `
			GROUP BY m.id
		) ranked
		WHERE rn <= @perCategory
		ORDER BY meal_count DESC, id ASC
		LIMIT @limit
	`

	var menus []domain.Menu
	var err error
	if len(excludeIDs) > 0 {
		err = r.db.Raw(rawSQL,
			map[string]interface{}{
				"perCategory": perCategory,
				"limit":       limit,
				"excludeIDs":  excludeIDs,
			},
		).Scan(&menus).Error
	} else {
		err = r.db.Raw(rawSQL,
			map[string]interface{}{
				"perCategory": perCategory,
				"limit":       limit,
			},
		).Scan(&menus).Error
	}
	return menus, err
}

func (r *menuRecommendationRepository) FindUserAllergies(userID int64) (string, error) {
	var allergies string
	err := r.db.Model(&domain.User{}).Where("id = ? AND deleted_at IS NULL", userID).Pluck("allergies", &allergies).Error
	return allergies, err
}

func (r *menuRecommendationRepository) FindMenuIDsByAllergens(allergens []string) ([]int64, error) {
	if len(allergens) == 0 {
		return []int64{}, nil
	}
	var ids []int64
	query := r.db.Model(&domain.Menu{}).Where("deleted_at IS NULL")

	// 각 알레르기 물질에 대해 LIKE 쿼리로 다중 OR 조건을 단다.
	var subQuery *gorm.DB
	for i, allergen := range allergens {
		if i == 0 {
			subQuery = r.db.Where("allergies LIKE ?", "%"+allergen+"%")
		} else {
			subQuery = subQuery.Or("allergies LIKE ?", "%"+allergen+"%")
		}
	}
	err := query.Where(subQuery).Pluck("id", &ids).Error
	return ids, err
}
