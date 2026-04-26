package usecase

import (
	"testing"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/redis/go-redis/v9"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockSocialRepository 는 SocialRepository 의 목 객체입니다.
type MockSocialRepository struct {
	mock.Mock
}

func (m *MockSocialRepository) CreateFriendship(f *domain.Friendship) error {
	return m.Called(f).Error(0)
}
func (m *MockSocialRepository) GetFriendship(u1, u2 int64) (*domain.Friendship, error) {
	args := m.Called(u1, u2)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.Friendship), args.Error(1)
}
func (m *MockSocialRepository) GetFriends(userID int64) ([]domain.Friendship, error) {
	args := m.Called(userID)
	return args.Get(0).([]domain.Friendship), args.Error(1)
}
func (m *MockSocialRepository) GetPendingRequests(userID int64) ([]domain.Friendship, error) {
	args := m.Called(userID)
	return args.Get(0).([]domain.Friendship), args.Error(1)
}
func (m *MockSocialRepository) GetSentRequests(userID int64) ([]domain.Friendship, error) {
	args := m.Called(userID)
	return args.Get(0).([]domain.Friendship), args.Error(1)
}
func (m *MockSocialRepository) UpdateFriendshipStatus(u1, u2 int64, s domain.FriendshipStatus) error {
	return m.Called(u1, u2, s).Error(0)
}
func (m *MockSocialRepository) DeleteFriendship(u1, u2 int64) error {
	return m.Called(u1, u2).Error(0)
}
func (m *MockSocialRepository) CreateBlock(b *domain.Block) error {
	return m.Called(b).Error(0)
}
func (m *MockSocialRepository) GetBlock(u1, u2 int64) (*domain.Block, error) {
	args := m.Called(u1, u2)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.Block), args.Error(1)
}
func (m *MockSocialRepository) DeleteBlock(u1, u2 int64) error {
	return m.Called(u1, u2).Error(0)
}
func (m *MockSocialRepository) CreateGuestbook(e *domain.Guestbook) error {
	return m.Called(e).Error(0)
}
func (m *MockSocialRepository) GetGuestbooks(id int64, l, o int) ([]domain.Guestbook, error) {
	args := m.Called(id, l, o)
	return args.Get(0).([]domain.Guestbook), args.Error(1)
}
func (m *MockSocialRepository) GetGuestbookByID(id int64) (*domain.Guestbook, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.Guestbook), args.Error(1)
}
func (m *MockSocialRepository) DeleteGuestbook(id int64) error {
	return m.Called(id).Error(0)
}
func (m *MockSocialRepository) CreateReport(r *domain.Report) error {
	return m.Called(r).Error(0)
}

// MockUserRepositoryForSocial 는 UserRepository 인터페이스를 완벽히 구현합니다.
type MockUserRepositoryForSocial struct {
	mock.Mock
}

func (m *MockUserRepositoryForSocial) Create(u *domain.User) error { return m.Called(u).Error(0) }
func (m *MockUserRepositoryForSocial) GetByID(id int64) (*domain.User, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.User), args.Error(1)
}
func (m *MockUserRepositoryForSocial) GetByUsername(n string) (*domain.User, error) {
	args := m.Called(n)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.User), args.Error(1)
}
func (m *MockUserRepositoryForSocial) GetByEmail(e string) (*domain.User, error) {
	args := m.Called(e)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.User), args.Error(1)
}
func (m *MockUserRepositoryForSocial) Update(u *domain.User) error { return m.Called(u).Error(0) }
func (m *MockUserRepositoryForSocial) Delete(id int64) error      { return m.Called(id).Error(0) }
func (m *MockUserRepositoryForSocial) CreateBody(b *domain.UserBody) error {
	return m.Called(b).Error(0)
}
func (m *MockUserRepositoryForSocial) GetLatestBody(id int64) (*domain.UserBody, error) {
	return nil, nil
}
func (m *MockUserRepositoryForSocial) CreateOrUpdateNutritionGoal(g *domain.UserNutritionGoal) error {
	return nil
}
func (m *MockUserRepositoryForSocial) GetNutritionGoal(id int64) (*domain.UserNutritionGoal, error) {
	return nil, nil
}
func (m *MockUserRepositoryForSocial) Search(q string) ([]domain.User, error) { return nil, nil }
func (m *MockUserRepositoryForSocial) GetRecommendations(id int64, l int) ([]domain.User, error) {
	return nil, nil
}
func (m *MockUserRepositoryForSocial) UpdateEquippedTitle(id int64, t *int64) error { return nil }
func (m *MockUserRepositoryForSocial) DeletePhysicallyExpired(d int) error          { return nil }

type MockMealRepositoryForSocial struct {
	mock.Mock
}

func (m *MockMealRepositoryForSocial) CountByUserID(id int64) (int64, error) { return 0, nil }
func (m *MockMealRepositoryForSocial) CountDistinctMenuByUserID(id int64) (int64, error) {
	return 0, nil
}
func (m *MockMealRepositoryForSocial) Create(meal *domain.MealRecord) error { return nil }
func (m *MockMealRepositoryForSocial) FindByID(id int64) (*domain.MealRecord, error) {
	return nil, nil
}
func (m *MockMealRepositoryForSocial) FindByUserID(id int64, f domain.MealListFilter) ([]domain.MealRecord, int64, error) {
	return nil, 0, nil
}
func (m *MockMealRepositoryForSocial) FindFriendMeals(ids []int64, f domain.MealListFilter) ([]domain.MealRecord, int64, error) {
	return nil, 0, nil
}
func (m *MockMealRepositoryForSocial) Update(meal *domain.MealRecord) error   { return nil }
func (m *MockMealRepositoryForSocial) Delete(id int64, userID int64) error    { return nil }

type MockCharacterRepositoryForSocial struct {
	mock.Mock
}

func (m *MockCharacterRepositoryForSocial) GetByUserID(id int64) (*domain.Character, error) {
	return nil, nil
}
func (m *MockCharacterRepositoryForSocial) Update(char *domain.Character) error { return nil }

func TestSocialUsecase_GetFriends(t *testing.T) {
	mockSocialRepo := new(MockSocialRepository)
	mockUserRepo := new(MockUserRepositoryForSocial)
	mockMealRepo := new(MockMealRepositoryForSocial)
	mockCharRepo := new(MockCharacterRepositoryForSocial)
	dummyRDB := redis.NewClient(&redis.Options{})

	uc := NewSocialUsecase(mockSocialRepo, mockUserRepo, mockMealRepo, mockCharRepo, nil, dummyRDB)

	t.Run("친구 목록 조회 성공", func(t *testing.T) {
		userID := int64(1)
		friendID := int64(2)
		friendships := []domain.Friendship{
			{
				RequesterID: userID,
				ReceiverID:  friendID,
				Status:      domain.FriendshipAccepted,
				Receiver:    &domain.User{BaseDomain: domain.BaseDomain{ID: friendID}, Nickname: "친구"},
			},
		}

		mockSocialRepo.On("GetFriends", userID).Return(friendships, nil)

		friends, err := uc.GetFriends(userID)

		assert.NoError(t, err)
		assert.Len(t, friends, 1)
		assert.Equal(t, "친구", friends[0].Nickname)
		mockSocialRepo.AssertExpectations(t)
	})
}
