package usecase

import (
	"testing"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
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
func (m *MockUserRepositoryForSocial) Update(u *domain.User) error { return m.Called(u).Error(0) }
func (m *MockUserRepositoryForSocial) Delete(id int64) error       { return m.Called(id).Error(0) }
func (m *MockUserRepositoryForSocial) CreateBody(b *domain.UserBody) error {
	return m.Called(b).Error(0)
}
func (m *MockUserRepositoryForSocial) GetLatestBody(id int64) (*domain.UserBody, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.UserBody), args.Error(1)
}
func (m *MockUserRepositoryForSocial) CreateOrUpdateNutritionGoal(g *domain.UserNutritionGoal) error {
	return m.Called(g).Error(0)
}
func (m *MockUserRepositoryForSocial) GetNutritionGoal(id int64) (*domain.UserNutritionGoal, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.UserNutritionGoal), args.Error(1)
}
func (m *MockUserRepositoryForSocial) Search(q string) ([]domain.User, error) {
	args := m.Called(q)
	return args.Get(0).([]domain.User), args.Error(1)
}
func (m *MockUserRepositoryForSocial) GetRecommendations(id int64, l int) ([]domain.User, error) {
	args := m.Called(id, l)
	return args.Get(0).([]domain.User), args.Error(1)
}
func (m *MockUserRepositoryForSocial) UpdateEquippedTitle(id int64, tid *int64) error {
	return m.Called(id, tid).Error(0)
}

// MockNotificationUsecaseForSocial
type MockNotificationUsecaseForSocial struct {
	mock.Mock
}

func (m *MockNotificationUsecaseForSocial) CreateNotification(n *domain.Notification) error {
	return m.Called(n).Error(0)
}
func (m *MockNotificationUsecaseForSocial) GetNotifications(id int64, l int, c string) ([]domain.Notification, string, error) {
	args := m.Called(id, l, c)
	return args.Get(0).([]domain.Notification), args.String(1), args.Error(2)
}
func (m *MockNotificationUsecaseForSocial) ReadNotification(id, uid int64) error {
	return m.Called(id, uid).Error(0)
}
func (m *MockNotificationUsecaseForSocial) ReadAllNotifications(id int64) error {
	return m.Called(id).Error(0)
}
func (m *MockNotificationUsecaseForSocial) Subscribe(id int64) (<-chan *domain.Notification, func()) {
	args := m.Called(id)
	return args.Get(0).(chan *domain.Notification), args.Get(1).(func())
}
func (m *MockNotificationUsecaseForSocial) Close() { m.Called() }

func TestSocialUsecase(t *testing.T) {
	mockSocial := new(MockSocialRepository)
	mockUser := new(MockUserRepositoryForSocial)
	mockNotify := new(MockNotificationUsecaseForSocial)
	uc := NewSocialUsecase(mockSocial, mockUser, mockNotify)

	t.Run("GetFriends - 친구 목록 조회", func(t *testing.T) {
		userID := int64(1)
		friends := []domain.Friendship{
			{RequesterID: userID, Receiver: &domain.User{BaseDomain: domain.BaseDomain{ID: 2}}},
			{ReceiverID: userID, Requester: &domain.User{BaseDomain: domain.BaseDomain{ID: 3}}},
		}
		mockSocial.On("GetFriends", userID).Return(friends, nil).Once()

		res, err := uc.GetFriends(userID)

		assert.NoError(t, err)
		assert.Len(t, res, 2)
		assert.Equal(t, int64(2), res[0].ID)
		assert.Equal(t, int64(3), res[1].ID)
	})

	t.Run("SendFriendRequest - 성공", func(t *testing.T) {
		reqID, resID := int64(1), int64(2)
		sender := &domain.User{BaseDomain: domain.BaseDomain{ID: reqID}, Nickname: "Tester"}

		mockSocial.On("GetFriendship", reqID, resID).Return(nil, nil).Once()
		mockSocial.On("GetFriendship", resID, reqID).Return(nil, nil).Once()
		mockSocial.On("GetBlock", resID, reqID).Return(nil, nil).Once()
		mockSocial.On("CreateFriendship", mock.Anything).Return(nil).Once()
		mockUser.On("GetByID", reqID).Return(sender, nil).Once()
		mockNotify.On("CreateNotification", mock.Anything).Return(nil).Once()

		err := uc.SendFriendRequest(reqID, resID)

		assert.NoError(t, err)
	})

	t.Run("AcceptFriendRequest - 성공", func(t *testing.T) {
		resID, reqID := int64(1), int64(2)
		receiver := &domain.User{BaseDomain: domain.BaseDomain{ID: resID}, Nickname: "Accepter"}

		mockSocial.On("UpdateFriendshipStatus", reqID, resID, domain.FriendshipAccepted).Return(nil).Once()
		mockUser.On("GetByID", resID).Return(receiver, nil).Once()
		mockNotify.On("CreateNotification", mock.MatchedBy(func(n *domain.Notification) bool {
			return n.UserID == reqID && n.Type == domain.NotificationTypeFriendAccepted
		})).Return(nil).Once()

		err := uc.AcceptFriendRequest(resID, reqID)

		assert.NoError(t, err)
	})

	t.Run("BlockUser - 성공", func(t *testing.T) {
		blockerID, blockedID := int64(1), int64(2)
		mockSocial.On("DeleteFriendship", blockerID, blockedID).Return(nil).Once()
		mockSocial.On("CreateBlock", mock.MatchedBy(func(b *domain.Block) bool {
			return b.BlockerID == blockerID && b.BlockedID == blockedID
		})).Return(nil).Once()

		err := uc.BlockUser(blockerID, blockedID)

		assert.NoError(t, err)
	})

	t.Run("WriteGuestbook - 성공", func(t *testing.T) {
		writerID, targetID := int64(1), int64(2)
		entry := &domain.Guestbook{WriterID: writerID, TargetUserID: targetID, Content: "Hello"}
		writer := &domain.User{BaseDomain: domain.BaseDomain{ID: writerID}, Nickname: "Writer"}

		mockSocial.On("CreateGuestbook", entry).Return(nil).Once()
		mockUser.On("GetByID", writerID).Return(writer, nil).Once()
		mockNotify.On("CreateNotification", mock.MatchedBy(func(n *domain.Notification) bool {
			return n.UserID == targetID && n.Type == domain.NotificationTypeGuestbook
		})).Return(nil).Once()

		err := uc.WriteGuestbook(entry)

		assert.NoError(t, err)
	})
}
