package usecase

import (
	"errors"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

type SocialUsecase interface {
	// Friends
	GetFriends(userID int64) ([]domain.User, error)
	DeleteFriend(userID, friendID int64) error
	GetPendingRequests(userID int64) ([]domain.User, error) // 받은 요청
	GetSentRequests(userID int64) ([]domain.User, error)    // 보낸 요청 추가
	SendFriendRequest(requesterID, receiverID int64) error
	AcceptFriendRequest(receiverID, requesterID int64) error
	RejectFriendRequest(receiverID, requesterID int64) error

	// Interaction
	Nudge(senderID, receiverID int64) error
	GetGuestbooks(targetUserID int64, page, limit int) ([]domain.Guestbook, error)
	WriteGuestbook(entry *domain.Guestbook) error
	BlockUser(blockerID, blockedID int64) error
	UnblockUser(blockerID, blockedID int64) error
	ReportUser(report *domain.Report) error
}

type socialUsecase struct {
	socialRepo       repository.SocialRepository
	userRepo         repository.UserRepository
	notificationUc   NotificationUsecase
}

func NewSocialUsecase(
	socialRepo repository.SocialRepository,
	userRepo repository.UserRepository,
	notificationUc NotificationUsecase,
) SocialUsecase {
	return &socialUsecase{
		socialRepo:     socialRepo,
		userRepo:       userRepo,
		notificationUc: notificationUc,
	}
}

func (u *socialUsecase) GetFriends(userID int64) ([]domain.User, error) {
	friendships, err := u.socialRepo.GetFriends(userID)
	if err != nil {
		return nil, err
	}

	var friends []domain.User
	for _, f := range friendships {
		if f.RequesterID == userID {
			friends = append(friends, *f.Receiver)
		} else {
			friends = append(friends, *f.Requester)
		}
	}
	return friends, nil
}

func (u *socialUsecase) DeleteFriend(userID, friendID int64) error {
	return u.socialRepo.DeleteFriendship(userID, friendID)
}

func (u *socialUsecase) GetPendingRequests(userID int64) ([]domain.User, error) {
	friendships, err := u.socialRepo.GetPendingRequests(userID)
	if err != nil {
		return nil, err
	}

	var users []domain.User
	for _, f := range friendships {
		users = append(users, *f.Requester)
	}
	return users, nil
}

func (u *socialUsecase) GetSentRequests(userID int64) ([]domain.User, error) {
	friendships, err := u.socialRepo.GetSentRequests(userID)
	if err != nil {
		return nil, err
	}

	var users []domain.User
	for _, f := range friendships {
		users = append(users, *f.Receiver)
	}
	return users, nil
}

func (u *socialUsecase) SendFriendRequest(requesterID, receiverID int64) error {
	if requesterID == receiverID {
		return errors.New("자신에게 친구 요청을 보낼 수 없습니다.")
	}

	// 1. 내가 보낸 요청이 이미 있는지 확인 (정방향)
	existingForward, err := u.socialRepo.GetFriendship(requesterID, receiverID)
	if err == nil && existingForward != nil {
		if existingForward.Status == domain.FriendshipAccepted {
			return errors.New("이미 친구 관계입니다.")
		}
		return errors.New("이미 친구 요청을 보냈습니다.")
	}

	// 2. 상대방이 나에게 보낸 요청이 있는지 확인 (역방향)
	existingReverse, err := u.socialRepo.GetFriendship(receiverID, requesterID)
	if err == nil && existingReverse != nil {
		if existingReverse.Status == domain.FriendshipAccepted {
			return errors.New("이미 친구 관계입니다.")
		}
		return errors.New("상대방으로부터 이미 친구 요청이 와 있습니다. 요청 탭에서 확인해 주세요.")
	}

	// 3. 차단 여부 확인
	block, err := u.socialRepo.GetBlock(receiverID, requesterID)
	if err == nil && block != nil {
		return errors.New("상대방에 의해 차단된 상태입니다.")
	}

	f := &domain.Friendship{
		RequesterID: requesterID,
		ReceiverID:  receiverID,
		Status:      domain.FriendshipPending,
	}

	if err := u.socialRepo.CreateFriendship(f); err != nil {
		return err
	}

	// 알림 생성
	sender, err := u.userRepo.GetByID(requesterID)
	if err == nil {
		_ = u.notificationUc.CreateNotification(&domain.Notification{
			UserID:   receiverID,
			SenderID: &requesterID,
			Type:     domain.NotificationTypeFriendRequest,
			Title:    "새로운 친구 요청",
			Content:  sender.Nickname + "님이 친구 요청을 보냈습니다.",
		})
	}

	return nil
}

func (u *socialUsecase) AcceptFriendRequest(receiverID, requesterID int64) error {
	if err := u.socialRepo.UpdateFriendshipStatus(requesterID, receiverID, domain.FriendshipAccepted); err != nil {
		return err
	}

	// 알림 생성 (요청을 보냈던 사람에게 수락 알림 전송)
	sender, err := u.userRepo.GetByID(receiverID)
	if err == nil {
		_ = u.notificationUc.CreateNotification(&domain.Notification{
			UserID:   requesterID,
			SenderID: &receiverID,
			Type:     domain.NotificationTypeFriendAccepted,
			Title:    "친구 요청 수락",
			Content:  sender.Nickname + "님이 친구 요청을 수락했습니다.",
		})
	}

	return nil
}

func (u *socialUsecase) RejectFriendRequest(receiverID, requesterID int64) error {
	return u.socialRepo.DeleteFriendship(requesterID, receiverID)
}

func (u *socialUsecase) Nudge(senderID, receiverID int64) error {
	// 알림 생성
	sender, err := u.userRepo.GetByID(senderID)
	if err != nil {
		return err
	}

	return u.notificationUc.CreateNotification(&domain.Notification{
		UserID:   receiverID,
		SenderID: &senderID,
		Type:     domain.NotificationTypeNudge,
		Title:    "응원 도착!",
		Content:  sender.Nickname + "님이 당신을 응원합니다!",
	})
}

func (u *socialUsecase) GetGuestbooks(targetUserID int64, page, limit int) ([]domain.Guestbook, error) {
	if limit <= 0 {
		limit = 20
	}
	offset := (page - 1) * limit
	return u.socialRepo.GetGuestbooks(targetUserID, limit, offset)
}

func (u *socialUsecase) WriteGuestbook(entry *domain.Guestbook) error {
	if err := u.socialRepo.CreateGuestbook(entry); err != nil {
		return err
	}

	// 알림 생성
	sender, err := u.userRepo.GetByID(entry.WriterID)
	if err == nil {
		_ = u.notificationUc.CreateNotification(&domain.Notification{
			UserID:   entry.TargetUserID,
			SenderID: &entry.WriterID,
			Type:     domain.NotificationTypeGuestbook,
			Title:    "방명록 새 글",
			Content:  sender.Nickname + "님이 방명록에 글을 남겼습니다.",
		})
	}

	return nil
}

func (u *socialUsecase) BlockUser(blockerID, blockedID int64) error {
	if blockerID == blockedID {
		return errors.New("자신을 차단할 수 없습니다.")
	}

	// 기존 친구 관계 삭제
	_ = u.socialRepo.DeleteFriendship(blockerID, blockedID)

	b := &domain.Block{
		BlockerID: blockerID,
		BlockedID: blockedID,
	}
	return u.socialRepo.CreateBlock(b)
}

func (u *socialUsecase) UnblockUser(blockerID, blockedID int64) error {
	return u.socialRepo.DeleteBlock(blockerID, blockedID)
}

func (u *socialUsecase) ReportUser(report *domain.Report) error {
	return u.socialRepo.CreateReport(report)
}
