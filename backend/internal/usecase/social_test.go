package usecase

import (
	"testing"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/go-redis/redismock/v9"
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
func (m *MockSocialRepository) CreateCharacterVisit(visit *domain.CharacterVisit) error {
	return m.Called(visit).Error(0)
}
func (m *MockSocialRepository) GetDailyCharacterVisitCount(visitorID int64, date time.Time) (int64, error) {
	args := m.Called(visitorID, date)
	return int64(args.Int(0)), args.Error(1)
}
func (m *MockSocialRepository) HasVisitedToday(visitorID, hostID int64, date time.Time) (bool, error) {
	args := m.Called(visitorID, hostID, date)
	return args.Bool(0), args.Error(1)
}
func (m *MockSocialRepository) IncrementFriendshipScore(userID1, userID2 int64, score int) error {
	return m.Called(userID1, userID2, score).Error(0)
}
func (m *MockSocialRepository) VisitTransaction(visit *domain.CharacterVisit, visitorPoint, hostPoint, score int) error {
	return m.Called(visit, visitorPoint, hostPoint, score).Error(0)
}
func (m *MockSocialRepository) GetFriendsComparison(userID int64, friendIDs []int64) ([]domain.ComparisonEntry, error) {
	args := m.Called(userID, friendIDs)
	return args.Get(0).([]domain.ComparisonEntry), args.Error(1)
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
func (m *MockUserRepositoryForSocial) AddPoint(id int64, amount int) error      { return nil }
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
	dummyRDB, _ := redismock.NewClientMock()

	// eventBus (nil) 추가
	uc := NewSocialUsecase(mockSocialRepo, mockUserRepo, mockMealRepo, mockCharRepo, nil, nil, dummyRDB)
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
func TestSocialUsecase_VisitFriend(t *testing.T) {
	mockSocialRepo := new(MockSocialRepository)
	mockUserRepo := new(MockUserRepositoryForSocial)
	mockMealRepo := new(MockMealRepositoryForSocial)
	mockCharRepo := new(MockCharacterRepositoryForSocial)
	dummyRDB, _ := redismock.NewClientMock()
	mockEventBus := new(MockEventBus)

	uc := NewSocialUsecase(mockSocialRepo, mockUserRepo, mockMealRepo, mockCharRepo, nil, mockEventBus, dummyRDB)

	visitorID := int64(1)
	hostID := int64(2)

	t.Run("성공적인 방문", func(t *testing.T) {
		mockSocialRepo.On("GetFriendship", visitorID, hostID).Return(&domain.Friendship{
			RequesterID:     visitorID,
			ReceiverID:      hostID,
			Status:          domain.FriendshipAccepted,
			FriendshipScore: 10,
		}, nil).Once()

		mockSocialRepo.On("GetDailyCharacterVisitCount", visitorID, mock.Anything).Return(2, nil).Once()
		mockSocialRepo.On("HasVisitedToday", visitorID, hostID, mock.Anything).Return(false, nil).Once()

		mockSocialRepo.On("VisitTransaction", mock.Anything, 10, 10, 1).Return(nil).Once()
		mockSocialRepo.On("GetFriendship", visitorID, hostID).Return(&domain.Friendship{
			RequesterID:     visitorID,
			ReceiverID:      hostID,
			Status:          domain.FriendshipAccepted,
			FriendshipScore: 11,
		}, nil).Once()

		mockEventBus.On("Publish", mock.Anything).Once()

		points, score, err := uc.VisitFriend(visitorID, hostID, domain.InteractionFeed)

		assert.NoError(t, err)
		assert.Equal(t, 10, points)
		assert.Equal(t, 11, score)
		mockSocialRepo.AssertExpectations(t)
		mockEventBus.AssertExpectations(t)
	})

	t.Run("비친구 에러", func(t *testing.T) {
		mockSocialRepo.On("GetFriendship", visitorID, hostID).Return(&domain.Friendship{
			RequesterID: visitorID,
			ReceiverID:  hostID,
			Status:      domain.FriendshipPending,
		}, nil).Once()

		_, _, err := uc.VisitFriend(visitorID, hostID, domain.InteractionFeed)

		assert.ErrorIs(t, err, ErrNotFriend)
	})

	t.Run("일일 한도 초과 에러", func(t *testing.T) {
		mockSocialRepo.On("GetFriendship", visitorID, hostID).Return(&domain.Friendship{
			RequesterID: visitorID,
			ReceiverID:  hostID,
			Status:      domain.FriendshipAccepted,
		}, nil).Once()

		mockSocialRepo.On("GetDailyCharacterVisitCount", visitorID, mock.Anything).Return(5, nil).Once()

		_, _, err := uc.VisitFriend(visitorID, hostID, domain.InteractionFeed)

		assert.ErrorIs(t, err, ErrDailyInteractionLimitExceeded)
	})

	t.Run("오늘 이미 방문함 에러", func(t *testing.T) {
		mockSocialRepo.On("GetFriendship", visitorID, hostID).Return(&domain.Friendship{
			RequesterID: visitorID,
			ReceiverID:  hostID,
			Status:      domain.FriendshipAccepted,
		}, nil).Once()

		mockSocialRepo.On("GetDailyCharacterVisitCount", visitorID, mock.Anything).Return(2, nil).Once()
		mockSocialRepo.On("HasVisitedToday", visitorID, hostID, mock.Anything).Return(true, nil).Once()

		_, _, err := uc.VisitFriend(visitorID, hostID, domain.InteractionFeed)

		assert.ErrorIs(t, err, ErrAlreadyVisitedToday)
	})
}

func TestSocialUsecase_GetFriendsComparison(t *testing.T) {
	mockSocialRepo := new(MockSocialRepository)
	mockUserRepo := new(MockUserRepositoryForSocial)
	mockMealRepo := new(MockMealRepositoryForSocial)
	mockCharRepo := new(MockCharacterRepositoryForSocial)
	dummyRDB, _ := redismock.NewClientMock()

	uc := NewSocialUsecase(mockSocialRepo, mockUserRepo, mockMealRepo, mockCharRepo, nil, nil, dummyRDB)

	userID := int64(1)
	friendID := int64(2)

	t.Run("나와 친구들의 비교 데이터 조회 성공", func(t *testing.T) {
		friendships := []domain.Friendship{
			{
				RequesterID: userID,
				ReceiverID:  friendID,
				Status:      domain.FriendshipAccepted,
			},
		}
		mockSocialRepo.On("GetFriends", userID).Return(friendships, nil).Once()

		expectedEntries := []domain.ComparisonEntry{
			{
				UserID:     userID,
				Nickname:   "나",
				Level:      5,
				Exp:        100,
				TotalExp:   5100,
				StreakDays: 10,
				BadgeCount: 3,
			},
			{
				UserID:     friendID,
				Nickname:   "친구",
				Level:      3,
				Exp:        50,
				TotalExp:   3050,
				StreakDays: 2,
				BadgeCount: 1,
			},
		}
		mockSocialRepo.On("GetFriendsComparison", userID, []int64{friendID}).Return(expectedEntries, nil).Once()

		entries, err := uc.GetFriendsComparison(userID)

		assert.NoError(t, err)
		assert.Len(t, entries, 2)
		assert.Equal(t, "나", entries[0].Nickname)
		assert.Equal(t, int64(5100), entries[0].TotalExp)
		assert.Equal(t, "친구", entries[1].Nickname)
		mockSocialRepo.AssertExpectations(t)
	})
}
