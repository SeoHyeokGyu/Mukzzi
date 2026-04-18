package repository

import (
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
)

// DailyIntakeRepository 일일 섭취 통계 저장소 인터페이스
type DailyIntakeRepository interface {
	// FindByUserIDAndDate 특정 날짜의 일일 섭취 통계 조회
	FindByUserIDAndDate(userID int64, date time.Time) (*domain.DailyIntake, error)

	// FindRecentByUserID 최근 N일 일일 섭취 통계 조회 (날짜 내림차순)
	FindRecentByUserID(userID int64, limit int) ([]domain.DailyIntake, error)
}

type dailyIntakeRepositoryImpl struct {
	db *gorm.DB
}

func NewDailyIntakeRepository(db *gorm.DB) DailyIntakeRepository {
	return &dailyIntakeRepositoryImpl{db: db}
}

func (r *dailyIntakeRepositoryImpl) FindByUserIDAndDate(userID int64, date time.Time) (*domain.DailyIntake, error) {
	var intake domain.DailyIntake
	if err := r.db.
		Where("user_id = ? AND date = ?", userID, date).
		First(&intake).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &intake, nil
}

func (r *dailyIntakeRepositoryImpl) FindRecentByUserID(userID int64, limit int) ([]domain.DailyIntake, error) {
	var intakes []domain.DailyIntake
	if err := r.db.
		Where("user_id = ?", userID).
		Order("id DESC").
		Limit(limit).
		Find(&intakes).Error; err != nil {
		return nil, err
	}
	return intakes, nil
}
