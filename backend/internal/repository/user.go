package repository

import (
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
)

// UserRepository 인터페이스는 사용자 관련 저장소 메서드를 정의합니다.
type UserRepository interface {
	Create(user *domain.User) error
	GetByID(id int64) (*domain.User, error)
	GetByUsername(username string) (*domain.User, error)
	GetByEmail(email string) (*domain.User, error)
	Update(user *domain.User) error
	Delete(id int64) error

	// UserBody
	CreateBody(body *domain.UserBody) error
	GetLatestBody(userID int64) (*domain.UserBody, error)

	// UserNutritionGoal
	CreateOrUpdateNutritionGoal(goal *domain.UserNutritionGoal) error
	GetNutritionGoal(userID int64) (*domain.UserNutritionGoal, error)

	// Search & Recommendations
	Search(query string) ([]domain.User, error)
	GetRecommendations(userID int64, limit int) ([]domain.User, error)

	// UpdateEquippedTitle 장착 칭호 갱신 (nil이면 해제)
	UpdateEquippedTitle(userID int64, titleID *int64) error

	// DeletePhysicallyExpired 기간이 만료된 소프트 삭제된 사용자들을 물리적으로 삭제
	DeletePhysicallyExpired(days int) error
}

type userRepository struct {
	db *gorm.DB
}

// NewUserRepository 는 UserRepository 인터페이스의 구현체를 반환합니다.
func NewUserRepository(db *gorm.DB) UserRepository {
	return &userRepository{db: db}
}

func (r *userRepository) Create(user *domain.User) error {
	return r.db.Create(user).Error
}

func (r *userRepository) GetByID(id int64) (*domain.User, error) {
	var user domain.User
	err := r.db.Preload("EquippedTitle").Preload("Body").Preload("NutritionGoal").First(&user, id).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) GetByUsername(username string) (*domain.User, error) {
	var user domain.User
	err := r.db.Where("username = ?", username).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) GetByEmail(email string) (*domain.User, error) {
	var user domain.User
	err := r.db.Where("email = ?", email).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) Update(user *domain.User) error {
	return r.db.Save(user).Error
}

func (r *userRepository) Delete(id int64) error {
	return r.db.Delete(&domain.User{}, id).Error
}

func (r *userRepository) DeletePhysicallyExpired(days int) error {
	expiryDate := time.Now().AddDate(0, 0, -days)
	return r.db.Unscoped().
		Where("deleted_at <= ?", expiryDate).
		Delete(&domain.User{}).Error
}

// CreateBody 는 새로운 신체 정보를 저장합니다 (이력 관리).
func (r *userRepository) CreateBody(body *domain.UserBody) error {
	return r.db.Create(body).Error
}

// GetLatestBody 는 사용자의 가장 최신 신체 정보를 조회합니다.
func (r *userRepository) GetLatestBody(userID int64) (*domain.UserBody, error) {
	var body domain.UserBody
	err := r.db.Where("user_id = ?", userID).Order("id DESC").First(&body).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &body, nil
}

// CreateOrUpdateNutritionGoal 은 영양 목표를 저장하거나 업데이트합니다 (유저당 1개).
func (r *userRepository) CreateOrUpdateNutritionGoal(goal *domain.UserNutritionGoal) error {
	var existing domain.UserNutritionGoal
	err := r.db.Where("user_id = ?", goal.UserID).First(&existing).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return r.db.Create(goal).Error
		}
		return err
	}
	goal.ID = existing.ID
	return r.db.Save(goal).Error
}

// UpdateEquippedTitle 은 사용자의 장착 칭호를 갱신합니다.
func (r *userRepository) UpdateEquippedTitle(userID int64, titleID *int64) error {
	return r.db.Model(&domain.User{}).
		Where("id = ?", userID).
		Update("equipped_title_id", titleID).Error
}

// GetNutritionGoal 은 사용자의 영양 목표를 조회합니다.
func (r *userRepository) GetNutritionGoal(userID int64) (*domain.UserNutritionGoal, error) {
	var goal domain.UserNutritionGoal
	err := r.db.Where("user_id = ?", userID).First(&goal).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &goal, nil
}

func (r *userRepository) Search(query string) ([]domain.User, error) {
	var users []domain.User
	err := r.db.Where("nickname LIKE ? OR username LIKE ?", "%"+query+"%", "%"+query+"%").
		Limit(20).Find(&users).Error
	return users, err
}

func (r *userRepository) GetRecommendations(userID int64, limit int) ([]domain.User, error) {
	var users []domain.User
	err := r.db.Where("id != ?", userID).Order("id DESC").Limit(limit).Find(&users).Error
	return users, err
}
