package repository

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
)

// BadgeRepository 뱃지 저장소 인터페이스
type BadgeRepository interface {
	// FindAllBadges 모든 뱃지 목록 조회
	FindAllBadges(db *gorm.DB, limit int, offset int) ([]domain.Badge, error)

	// CountAllBadges 전체 뱃지 개수
	CountAllBadges(db *gorm.DB) (int64, error)

	// FindUserAcquiredBadges 사용자가 획득한 뱃지 조회
	FindUserAcquiredBadges(db *gorm.DB, userID int64) ([]domain.UserBadge, error)

	// FindBadgeByID 뱃지 ID로 조회
	FindBadgeByID(db *gorm.DB, badgeID int64) (*domain.Badge, error)

	// CreateUserBadge 사용자 뱃지 기록 생성
	CreateUserBadge(db *gorm.DB, userBadge *domain.UserBadge) error

	// FindUserBadgeByID 사용자 뱃지 기록 조회
	FindUserBadgeByID(db *gorm.DB, userID, badgeID int64) (*domain.UserBadge, error)
}

// badgeRepositoryImpl 뱃지 저장소 구현체
type badgeRepositoryImpl struct{}

// NewBadgeRepository 뱃지 저장소 생성
func NewBadgeRepository() BadgeRepository {
	return &badgeRepositoryImpl{}
}

// FindAllBadges 모든 뱃지 목록 조회
func (r *badgeRepositoryImpl) FindAllBadges(db *gorm.DB, limit int, offset int) ([]domain.Badge, error) {
	var badges []domain.Badge
	if err := db.
		Limit(limit).
		Offset(offset).
		Order("created_at ASC").
		Find(&badges).Error; err != nil {
		return nil, err
	}
	return badges, nil
}

// CountAllBadges 전체 뱃지 개수
func (r *badgeRepositoryImpl) CountAllBadges(db *gorm.DB) (int64, error) {
	var count int64
	if err := db.Model(&domain.Badge{}).Count(&count).Error; err != nil {
		return 0, err
	}
	return count, nil
}

// FindUserAcquiredBadges 사용자가 획득한 뱃지 조회
func (r *badgeRepositoryImpl) FindUserAcquiredBadges(db *gorm.DB, userID int64) ([]domain.UserBadge, error) {
	var userBadges []domain.UserBadge
	if err := db.
		Where("user_id = ?", userID).
		Preload("Badge").
		Order("acquired_at DESC").
		Find(&userBadges).Error; err != nil {
		return nil, err
	}
	return userBadges, nil
}

// FindBadgeByID 뱃지 ID로 조회
func (r *badgeRepositoryImpl) FindBadgeByID(db *gorm.DB, badgeID int64) (*domain.Badge, error) {
	var badge domain.Badge
	if err := db.Where("id = ?", badgeID).First(&badge).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &badge, nil
}

// CreateUserBadge 사용자 뱃지 기록 생성
func (r *badgeRepositoryImpl) CreateUserBadge(db *gorm.DB, userBadge *domain.UserBadge) error {
	return db.Create(userBadge).Error
}

// FindUserBadgeByID 사용자 뱃지 기록 조회
func (r *badgeRepositoryImpl) FindUserBadgeByID(db *gorm.DB, userID, badgeID int64) (*domain.UserBadge, error) {
	var userBadge domain.UserBadge
	if err := db.
		Where("user_id = ? AND badge_id = ?", userID, badgeID).
		First(&userBadge).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &userBadge, nil
}
