package repository

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
)

// BadgeRepository 뱃지 저장소 인터페이스
type BadgeRepository interface {
	// FindAllBadges 모든 뱃지 목록 조회
	FindAllBadges(limit int, offset int) ([]domain.Badge, error)

	// FindUnacquiredBadges 사용자가 미획득한 뱃지만 조회
	FindUnacquiredBadges(userID int64, limit, offset int) ([]domain.Badge, error)

	// CountAllBadges 전체 뱃지 개수
	CountAllBadges() (int64, error)

	// CountUserAcquiredBadges 사용자가 획득한 뱃지 수
	CountUserAcquiredBadges(userID int64) (int64, error)

	// FindUserAcquiredBadges 사용자가 획득한 뱃지 조회
	FindUserAcquiredBadges(userID int64) ([]domain.UserBadge, error)

	// FindBadgeByID 뱃지 ID로 조회
	FindBadgeByID(badgeID int64) (*domain.Badge, error)

	// CreateUserBadge 사용자 뱃지 기록 생성
	CreateUserBadge(userBadge *domain.UserBadge) error

	// FindUserBadgeByID 사용자 뱃지 기록 조회
	FindUserBadgeByID(userID, badgeID int64) (*domain.UserBadge, error)

	// FindBadgeByCode 뱃지 코드로 조회
	FindBadgeByCode(code string) (*domain.Badge, error)
}

// badgeRepositoryImpl 뱃지 저장소 구현체
type badgeRepositoryImpl struct {
	db *gorm.DB
}

// NewBadgeRepository 뱃지 저장소 생성
func NewBadgeRepository(db *gorm.DB) BadgeRepository {
	return &badgeRepositoryImpl{db: db}
}

// FindAllBadges 모든 뱃지 목록 조회
func (r *badgeRepositoryImpl) FindAllBadges(limit int, offset int) ([]domain.Badge, error) {
	var badges []domain.Badge
	if err := r.db.
		Limit(limit).
		Offset(offset).
		Order("id ASC").
		Find(&badges).Error; err != nil {
		return nil, err
	}
	return badges, nil
}

// FindUnacquiredBadges 사용자가 미획득한 뱃지만 조회
func (r *badgeRepositoryImpl) FindUnacquiredBadges(userID int64, limit, offset int) ([]domain.Badge, error) {
	var badges []domain.Badge
	if err := r.db.
		Where("id NOT IN (SELECT badge_id FROM user_badges WHERE user_id = ?)", userID).
		Limit(limit).
		Offset(offset).
		Order("id ASC").
		Find(&badges).Error; err != nil {
		return nil, err
	}
	return badges, nil
}

// CountAllBadges 전체 뱃지 개수
func (r *badgeRepositoryImpl) CountAllBadges() (int64, error) {
	var count int64
	if err := r.db.Model(&domain.Badge{}).Count(&count).Error; err != nil {
		return 0, err
	}
	return count, nil
}

// FindUserAcquiredBadges 사용자가 획득한 뱃지 조회
func (r *badgeRepositoryImpl) FindUserAcquiredBadges(userID int64) ([]domain.UserBadge, error) {
	var userBadges []domain.UserBadge
	if err := r.db.
		Where("user_id = ?", userID).
		Preload("Badge").
		Order("id DESC").
		Find(&userBadges).Error; err != nil {
		return nil, err
	}
	return userBadges, nil
}

// FindBadgeByID 뱃지 ID로 조회
func (r *badgeRepositoryImpl) FindBadgeByID(badgeID int64) (*domain.Badge, error) {
	var badge domain.Badge
	if err := r.db.Where("id = ?", badgeID).First(&badge).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &badge, nil
}

// CreateUserBadge 사용자 뱃지 기록 생성
func (r *badgeRepositoryImpl) CreateUserBadge(userBadge *domain.UserBadge) error {
	return r.db.Create(userBadge).Error
}

// FindBadgeByCode 뱃지 코드로 조회
func (r *badgeRepositoryImpl) FindBadgeByCode(code string) (*domain.Badge, error) {
	var badge domain.Badge
	if err := r.db.Where("code = ?", code).First(&badge).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &badge, nil
}

// CountUserAcquiredBadges 사용자가 획득한 뱃지 수 조회
func (r *badgeRepositoryImpl) CountUserAcquiredBadges(userID int64) (int64, error) {
	var count int64
	if err := r.db.Model(&domain.UserBadge{}).
		Where("user_id = ?", userID).
		Count(&count).Error; err != nil {
		return 0, err
	}
	return count, nil
}

// FindUserBadgeByID 사용자 뱃지 기록 조회
func (r *badgeRepositoryImpl) FindUserBadgeByID(userID, badgeID int64) (*domain.UserBadge, error) {
	var userBadge domain.UserBadge
	if err := r.db.
		Where("user_id = ? AND badge_id = ?", userID, badgeID).
		First(&userBadge).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &userBadge, nil
}
