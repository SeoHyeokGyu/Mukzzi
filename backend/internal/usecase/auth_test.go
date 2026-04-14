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

func TestAuthUsecase_Register(t *testing.T) {
	mockRepo := new(MockUserRepository)
	uc := NewAuthUsecase(mockRepo)

	t.Run("성공적인 회원가입", func(t *testing.T) {
		user := &domain.User{
			Username: "testuser",
			Password: "password123",
			Email:    "test@example.com",
		}

		mockRepo.On("Create", mock.AnythingOfType("*domain.User")).Return(nil)

		createdUser, err := uc.Register(user)

		assert.NoError(t, err)
		assert.Equal(t, "testuser", createdUser.Username)
		assert.NotEqual(t, "password123", createdUser.Password)
		err = bcrypt.CompareHashAndPassword([]byte(createdUser.Password), []byte("password123"))
		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})
}

func TestAuthUsecase_Login(t *testing.T) {
	mockRepo := new(MockUserRepository)
	uc := NewAuthUsecase(mockRepo)

	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("password123"), bcrypt.DefaultCost)
	mockUser := &domain.User{
		BaseDomain: domain.BaseDomain{ID: 12345},
		Username:   "testuser",
		Password:   string(hashedPassword),
	}

	t.Run("성공적인 로그인", func(t *testing.T) {
		mockRepo.On("GetByUsername", "testuser").Return(mockUser, nil)

		token, user, err := uc.Login("testuser", "password123")

		assert.NoError(t, err)
		assert.NotEmpty(t, token)
		assert.Equal(t, mockUser.ID, user.ID)
		mockRepo.AssertExpectations(t)
	})

	t.Run("잘못된 비밀번호로 로그인 실패", func(t *testing.T) {
		mockRepo.On("GetByUsername", "testuser").Return(mockUser, nil)

		token, user, err := uc.Login("testuser", "wrongpassword")

		assert.Error(t, err)
		assert.Empty(t, token)
		assert.Nil(t, user)
		assert.Contains(t, err.Error(), "일치하지 않습니다")
	})

	t.Run("존재하지 않는 사용자로 로그인 실패", func(t *testing.T) {
		mockRepo.On("GetByUsername", "nonexistent").Return(nil, assert.AnError)

		token, user, err := uc.Login("nonexistent", "password123")

		assert.Error(t, err)
		assert.Empty(t, token)
		assert.Nil(t, user)
	})
}
