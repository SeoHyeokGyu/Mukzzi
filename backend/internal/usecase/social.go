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
	GetPendingRequests(userID int64) ([]domain.User, error)
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
	socialRepo repository.SocialRepository
	userRepo   repository.UserRepository
}

func NewSocialUsecase(
	socialRepo repository.SocialRepository,
	userRepo repository.UserRepository,
) SocialUsecase {
	return &socialUsecase{
		socialRepo: socialRepo,
		userRepo:   userRepo,
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

func (u *socialUsecase) SendFriendRequest(requesterID, receiverID int64) error {
	if requesterID == receiverID {
		return errors.New("자신에게 친구 요청을 보낼 수 없습니다.")
	}

	// 기존 관계 확인
	existing, err := u.socialRepo.GetFriendship(requesterID, receiverID)
	if err == nil && existing != nil {
		return errors.New("이미 친구이거나 대기 중인 요청이 있습니다.")
	}

	// 차단 여부 확인
	block, err := u.socialRepo.GetBlock(receiverID, requesterID)
	if err == nil && block != nil {
		return errors.New("상대방에 의해 차단된 상태입니다.")
	}

	f := &domain.Friendship{
		RequesterID: requesterID,
		ReceiverID:  receiverID,
		Status:      domain.FriendshipPending,
	}
	return u.socialRepo.CreateFriendship(f)
}

func (u *socialUsecase) AcceptFriendRequest(receiverID, requesterID int64) error {
	return u.socialRepo.UpdateFriendshipStatus(requesterID, receiverID, domain.FriendshipAccepted)
}

func (u *socialUsecase) RejectFriendRequest(receiverID, requesterID int64) error {
	return u.socialRepo.DeleteFriendship(requesterID, receiverID)
}

func (u *socialUsecase) Nudge(senderID, receiverID int64) error {
	return nil
}

func (u *socialUsecase) GetGuestbooks(targetUserID int64, page, limit int) ([]domain.Guestbook, error) {
	if limit <= 0 {
		limit = 20
	}
	offset := (page - 1) * limit
	return u.socialRepo.GetGuestbooks(targetUserID, limit, offset)
}

func (u *socialUsecase) WriteGuestbook(entry *domain.Guestbook) error {
	return u.socialRepo.CreateGuestbook(entry)
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
