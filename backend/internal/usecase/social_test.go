package usecase

import (
	"context"
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
	args := m.Called(f)
	return args.Error(0)
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
	args := m.Called(u1, u2, s)
	return args.Error(0)
}

func (m *MockSocialRepository) DeleteFriendship(u1, u2 int64) error {
	args := m.Called(u1, u2)
	return args.Error(0)
}

func (m *MockSocialRepository) CreateBlock(b *domain.Block) error {
	args := m.Called(b)
	return args.Error(0)
}

func (m *MockSocialRepository) GetBlock(u1, u2 int64) (*domain.Block, error) {
	args := m.Called(u1, u2)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.Block), args.Error(1)
}

func (m *MockSocialRepository) DeleteBlock(u1, u2 int64) error {
	args := m.Called(u1, u2)
	return args.Error(0)
}

func (m *MockSocialRepository) CreateGuestbook(e *domain.Guestbook) error {
	args := m.Called(e)
	return args.Error(0)
}

func (m *MockSocialRepository) GetGuestbooks(id int64, l, o int) ([]domain.Guestbook, error) {
	args := m.Called(id, l, o)
	return args.Get(0).([]domain.Guestbook), args.Error(1)
}

func (m *MockSocialRepository) CreateReport(r *domain.Report) error {
	args := m.Called(r)
	return args.Error(0)
}

// MockUserRepository 는 UserRepository 의 목 객체입니다.
type MockUserRepositoryForSocial struct {
	mock.Mock
}

func (m *MockUserRepositoryForSocial) GetByID(id int64) (*domain.User, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.User), args.Error(1)
}

// 나머지 인터페이스 메서드들은 테스트에 필요할 때 추가 구현
func (m *MockUserRepositoryForSocial) Create(u *domain.User) error                 { return nil }
func (m *MockUserRepositoryForSocial) GetByUsername(n string) (*domain.User, error) { return nil, nil }
func (m *MockUserRepositoryForSocial) GetByEmail(e string) (*domain.User, error)    { return nil, nil }
func (m *MockUserRepositoryForSocial) Update(u *domain.User) error                 { return nil }
func (m *MockUserRepositoryForSocial) Delete(id int64) error                      { return nil }
func (m *MockUserRepositoryForSocial) Search(q string) ([]domain.User, error)      { return nil, nil }
func (m *MockUserRepositoryForSocial) GetRecommendations(id int64, l int) ([]domain.User, error) {
	return nil, nil
}

// MockNotificationUsecase 는 NotificationUsecase 의 목 객체입니다.
type MockNotificationUsecaseForSocial struct {
	mock.Mock
}

func (m *MockNotificationUsecaseForSocial) CreateNotification(n *domain.Notification) error {
	args := m.Called(n)
	return args.Error(0)
}
func (m *MockNotificationUsecaseForSocial) GetNotifications(id int64, l int, c string) ([]domain.Notification, string, error) {
	return nil, "", nil
}
func (m *MockNotificationUsecaseForSocial) ReadNotification(id, uid int64) error { return nil }
func (m *MockNotificationUsecaseForSocial) ReadAllNotifications(id int64) error  { return nil }
func (m *MockNotificationUsecaseForSocial) Subscribe(id int64) (<-chan *domain.Notification, func()) {
	return nil, func() {}
}
func (m *MockNotificationUsecaseForSocial) Close() {}

func TestSocialUsecase_SendFriendRequest(t *testing.T) {
	mockSocialRepo := new(MockSocialRepository)
	mockUserRepo := new(MockUserRepositoryForSocial)
	mockNotifyUc := new(MockNotificationUsecaseForSocial)
	uc := NewSocialUsecase(mockSocialRepo, mockUserRepo, mockNotifyUc)

	t.Run("성공적인 친구 요청", func(t *testing.T) {
		reqID, resID := int64(1), int64(2)
		sender := &domain.User{BaseDomain: domain.BaseDomain{ID: reqID}, Nickname: "Sender"}

		mockSocialRepo.On("GetFriendship", reqID, resID).Return(nil, nil).Once()
		mockSocialRepo.On("GetFriendship", resID, reqID).Return(nil, nil).Once()
		mockSocialRepo.On("GetBlock", resID, reqID).Return(nil, nil).Once()
		mockSocialRepo.On("CreateFriendship", mock.Anything).Return(nil).Once()
		mockUserRepo.On("GetByID", reqID).Return(sender, nil).Once()
		mockNotifyUc.On("CreateNotification", mock.Anything).Return(nil).Once()

		err := uc.SendFriendRequest(reqID, resID)

		assert.NoError(t, err)
		mockSocialRepo.AssertExpectations(t)
		mockNotifyUc.AssertExpectations(t)
	})

	t.Run("이미 요청을 보낸 경우 실패", func(t *testing.T) {
		reqID, resID := int64(1), int64(2)
		existing := &domain.Friendship{RequesterID: reqID, ReceiverID: resID, Status: domain.FriendshipPending}

		mockSocialRepo.On("GetFriendship", reqID, resID).Return(existing, nil).Once()

		err := uc.SendFriendRequest(reqID, resID)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "이미 친구 요청을 보냈습니다")
	})
}

func TestSocialUsecase_AcceptFriendRequest(t *testing.T) {
	mockSocialRepo := new(MockSocialRepository)
	mockUserRepo := new(MockUserRepositoryForSocial)
	mockNotifyUc := new(MockNotificationUsecaseForSocial)
	uc := NewSocialUsecase(mockSocialRepo, mockUserRepo, mockNotifyUc)

	t.Run("친구 요청 수락 성공", func(t *testing.T) {
		resID, reqID := int64(1), int64(2) // 수신자가 1, 요청자가 2
		receiver := &domain.User{BaseDomain: domain.BaseDomain{ID: resID}, Nickname: "Receiver"}

		mockSocialRepo.On("UpdateFriendshipStatus", reqID, resID, domain.FriendshipAccepted).Return(nil).Once()
		mockUserRepo.On("GetByID", resID).Return(receiver, nil).Once()
		mockNotifyUc.On("CreateNotification", mock.MatchedBy(func(n *domain.Notification) bool {
			return n.UserID == reqID && n.Type == domain.NotificationTypeFriendAccepted
		})).Return(nil).Once()

		err := uc.AcceptFriendRequest(resID, reqID)

		assert.NoError(t, err)
		mockSocialRepo.AssertExpectations(t)
		mockNotifyUc.AssertExpectations(t)
	})
}

func TestSocialUsecase_Nudge(t *testing.T) {
	mockSocialRepo := new(MockSocialRepository)
	mockUserRepo := new(MockUserRepositoryForSocial)
	mockNotifyUc := new(MockNotificationUsecaseForSocial)
	uc := NewSocialUsecase(mockSocialRepo, mockUserRepo, mockNotifyUc)

	t.Run("응원하기 성공", func(t *testing.T) {
		senderID, receiverID := int64(1), int64(2)
		sender := &domain.User{BaseDomain: domain.BaseDomain{ID: senderID}, Nickname: "Sender"}

		mockUserRepo.On("GetByID", senderID).Return(sender, nil).Once()
		mockNotifyUc.On("CreateNotification", mock.MatchedBy(func(n *domain.Notification) bool {
			return n.UserID == receiverID && n.Type == domain.NotificationTypeNudge
		})).Return(nil).Once()

		err := uc.Nudge(senderID, receiverID)

		assert.NoError(t, err)
		mockNotifyUc.AssertExpectations(t)
	})
}
