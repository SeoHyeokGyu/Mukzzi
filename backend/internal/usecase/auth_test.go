package usecase

import (
	"testing"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"golang.org/x/crypto/bcrypt"
)

// MockUserRepository 는 UserRepository 인터페이스의 통합 모킹 객체입니다.
type MockUserRepository struct {
	mock.Mock
}

func (m *MockUserRepository) Create(user *domain.User) error {
	args := m.Called(user)
	return args.Error(0)
}

func (m *MockUserRepository) GetByID(id int64) (*domain.User, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.User), args.Error(1)
}

func (m *MockUserRepository) GetByUsername(username string) (*domain.User, error) {
	args := m.Called(username)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.User), args.Error(1)
}

func (m *MockUserRepository) GetByEmail(email string) (*domain.User, error) {
	args := m.Called(email)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.User), args.Error(1)
}

func (m *MockUserRepository) Update(user *domain.User) error {
	args := m.Called(user)
	return args.Error(0)
}

func (m *MockUserRepository) Delete(id int64) error {
	args := m.Called(id)
	return args.Error(0)
}

func (m *MockUserRepository) CreateBody(body *domain.UserBody) error {
	args := m.Called(body)
	return args.Error(0)
}

func (m *MockUserRepository) GetLatestBody(userID int64) (*domain.UserBody, error) {
	args := m.Called(userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.UserBody), args.Error(1)
}

func (m *MockUserRepository) CreateOrUpdateNutritionGoal(goal *domain.UserNutritionGoal) error {
	args := m.Called(goal)
	return args.Error(0)
}

func (m *MockUserRepository) GetNutritionGoal(userID int64) (*domain.UserNutritionGoal, error) {
	args := m.Called(userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.UserNutritionGoal), args.Error(1)
}

func (m *MockUserRepository) Search(query string) ([]domain.User, error) {
	args := m.Called(query)
	return args.Get(0).([]domain.User), args.Error(1)
}

func (m *MockUserRepository) GetRecommendations(userID int64, limit int) ([]domain.User, error) {
	args := m.Called(userID, limit)
	return args.Get(0).([]domain.User), args.Error(1)
}

func (m *MockUserRepository) UpdateEquippedTitle(userID int64, titleID *int64) error {
	args := m.Called(userID, titleID)
	return args.Error(0)
}

func (m *MockUserRepository) DeletePhysicallyExpired(days int) error {
	args := m.Called(days)
	return args.Error(0)
}

func TestAuthUsecase_Login(t *testing.T) {
	mockRepo := new(MockUserRepository)
	// NewAuthUsecase 에 nil (redis.Client) 추가
	uc := NewAuthUsecase(mockRepo, nil)

	t.Run("로그인 성공", func(t *testing.T) {
		hashed, _ := bcrypt.GenerateFromPassword([]byte("password"), bcrypt.DefaultCost)
		mockUser := &domain.User{
			BaseDomain: domain.BaseDomain{ID: 1},
			Username:   "test",
			Password:   string(hashed),
		}

		mockRepo.On("GetByUsername", "test").Return(mockUser, nil)

		// Login 반환값이 (accessToken, refreshToken, user, error) 로 변경됨
		accessToken, refreshToken, user, err := uc.Login("test", "", "password")

		assert.NoError(t, err)
		assert.NotEmpty(t, accessToken)
		assert.NotEmpty(t, refreshToken)
		assert.Equal(t, mockUser, user)
		mockRepo.AssertExpectations(t)
	})

	t.Run("로그인 실패 - 잘못된 비밀번호", func(t *testing.T) {
		hashed, _ := bcrypt.GenerateFromPassword([]byte("password"), bcrypt.DefaultCost)
		mockUser := &domain.User{
			BaseDomain: domain.BaseDomain{ID: 1},
			Username:   "test",
			Password:   string(hashed),
		}

		mockRepo.On("GetByUsername", "test").Return(mockUser, nil)

		accessToken, refreshToken, user, err := uc.Login("test", "", "wrong_password")

		assert.Error(t, err)
		assert.Empty(t, accessToken)
		assert.Empty(t, refreshToken)
		assert.Nil(t, user)
	})
}
