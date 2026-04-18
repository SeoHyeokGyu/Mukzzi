package repository

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/gorm"
)

// SocialRepository 는 친구 관계, 차단, 방명록, 신고 등 소셜 관련 모든 저장소 로직을 담당합니다.
type SocialRepository interface {
	// Friendship
	CreateFriendship(friendship *domain.Friendship) error
	GetFriendship(userID1, userID2 int64) (*domain.Friendship, error)
	GetFriends(userID int64) ([]domain.Friendship, error)
	GetPendingRequests(userID int64) ([]domain.Friendship, error)
	GetSentRequests(userID int64) ([]domain.Friendship, error)
	UpdateFriendshipStatus(requesterID, receiverID int64, status domain.FriendshipStatus) error
	DeleteFriendship(userID1, userID2 int64) error

	// Block
	CreateBlock(block *domain.Block) error
	GetBlock(blockerID, blockedID int64) (*domain.Block, error)
	DeleteBlock(blockerID, blockedID int64) error

	// Guestbook
	CreateGuestbook(entry *domain.Guestbook) error
	GetGuestbooks(targetUserID int64, limit, offset int) ([]domain.Guestbook, error)

	// Report
	CreateReport(report *domain.Report) error
}

type socialRepository struct {
	db *gorm.DB
}

func NewSocialRepository(db *gorm.DB) SocialRepository {
	return &socialRepository{db: db}
}

// Friendship 구현
func (r *socialRepository) CreateFriendship(f *domain.Friendship) error {
	return r.db.Create(f).Error
}

func (r *socialRepository) GetFriendship(userID1, userID2 int64) (*domain.Friendship, error) {
	var f domain.Friendship
	err := r.db.Where("(requester_id = ? AND receiver_id = ?) OR (requester_id = ? AND receiver_id = ?)",
		userID1, userID2, userID2, userID1).First(&f).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &f, nil
}

func (r *socialRepository) GetFriends(userID int64) ([]domain.Friendship, error) {
	var friends []domain.Friendship
	err := r.db.Preload("Requester").Preload("Receiver").
		Where("status = ? AND (requester_id = ? OR receiver_id = ?)", domain.FriendshipAccepted, userID, userID).
		Find(&friends).Error
	return friends, err
}

func (r *socialRepository) GetPendingRequests(userID int64) ([]domain.Friendship, error) {
	var requests []domain.Friendship
	err := r.db.Preload("Requester").
		Where("receiver_id = ? AND status = ?", userID, domain.FriendshipPending).
		Find(&requests).Error
	return requests, err
}

func (r *socialRepository) GetSentRequests(userID int64) ([]domain.Friendship, error) {
	var requests []domain.Friendship
	err := r.db.Preload("Receiver").
		Where("requester_id = ? AND status = ?", userID, domain.FriendshipPending).
		Find(&requests).Error
	return requests, err
}

func (r *socialRepository) UpdateFriendshipStatus(requesterID, receiverID int64, status domain.FriendshipStatus) error {
	return r.db.Model(&domain.Friendship{}).
		Where("requester_id = ? AND receiver_id = ?", requesterID, receiverID).
		Update("status", status).Error
}

func (r *socialRepository) DeleteFriendship(userID1, userID2 int64) error {
	return r.db.Where("(requester_id = ? AND receiver_id = ?) OR (requester_id = ? AND receiver_id = ?)",
		userID1, userID2, userID2, userID1).Delete(&domain.Friendship{}).Error
}

// Block 구현
func (r *socialRepository) CreateBlock(block *domain.Block) error {
	return r.db.Create(block).Error
}

func (r *socialRepository) GetBlock(blockerID, blockedID int64) (*domain.Block, error) {
	var b domain.Block
	err := r.db.Where("blocker_id = ? AND blocked_id = ?", blockerID, blockedID).First(&b).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &b, nil
}

func (r *socialRepository) DeleteBlock(blockerID, blockedID int64) error {
	return r.db.Where("blocker_id = ? AND blocked_id = ?", blockerID, blockedID).Delete(&domain.Block{}).Error
}

// Guestbook 구현
func (r *socialRepository) CreateGuestbook(entry *domain.Guestbook) error {
	return r.db.Create(entry).Error
}

func (r *socialRepository) GetGuestbooks(targetUserID int64, limit, offset int) ([]domain.Guestbook, error) {
	var entries []domain.Guestbook
	err := r.db.Preload("Writer").
		Where("target_user_id = ?", targetUserID).
		Order("id DESC").
		Limit(limit).Offset(offset).
		Find(&entries).Error
	return entries, err
}

// Report 구현
func (r *socialRepository) CreateReport(report *domain.Report) error {
	return r.db.Create(report).Error
}
