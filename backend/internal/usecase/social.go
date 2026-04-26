package usecase

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
	"github.com/redis/go-redis/v9"
)

type RankingEntry struct {
	UserID        int64   `json:"user_id,string"`
	Nickname      string  `json:"nickname"`
	Level         int     `json:"level"`
	Score         float64 `json:"score"`
	Rank          int     `json:"rank"`
	PenaltyStatus string  `json:"penalty_status"`
}

func (e RankingEntry) UserIDString() string {
	return strconv.FormatInt(e.UserID, 10)
}

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
	DeleteGuestbook(userID, guestbookID int64) error
	BlockUser(blockerID, blockedID int64) error
	UnblockUser(blockerID, blockedID int64) error
	ReportUser(report *domain.Report) error

	// Feed
	GetSocialFeed(userID int64, filter domain.MealListFilter) ([]domain.MealRecord, int64, error)

	// Ranking
	GetSocialRanking(ctx context.Context) ([]RankingEntry, error)
}

type socialUsecase struct {
	socialRepo    repository.SocialRepository
	userRepo      repository.UserRepository
	mealRepo      repository.MealRepository
	characterRepo repository.CharacterRepository
	notificationUc NotificationUsecase
	rdb           *redis.Client
}

func NewSocialUsecase(
	socialRepo repository.SocialRepository,
	userRepo repository.UserRepository,
	mealRepo repository.MealRepository,
	characterRepo repository.CharacterRepository,
	notificationUc NotificationUsecase,
	rdb *redis.Client,
) SocialUsecase {
	return &socialUsecase{
		socialRepo:    socialRepo,
		userRepo:      userRepo,
		mealRepo:      mealRepo,
		characterRepo: characterRepo,
		notificationUc: notificationUc,
		rdb:           rdb,
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
	ctx := context.Background()
	nudgeKey := fmt.Sprintf("nudge:%d:%d", senderID, receiverID)

	// 1일 1회 제한 확인
	exists, err := u.rdb.Exists(ctx, nudgeKey).Result()
	if err != nil {
		return err
	}
	if exists > 0 {
		return errors.New("오늘은 이미 응원했습니다. 내일 다시 응원해주세요!")
	}

	// 알림 생성
	sender, err := u.userRepo.GetByID(senderID)
	if err != nil {
		return err
	}

	err = u.notificationUc.CreateNotification(&domain.Notification{
		UserID:   receiverID,
		SenderID: &senderID,
		Type:     domain.NotificationTypeNudge,
		Title:    "응원 도착!",
		Content:  sender.Nickname + "님이 당신을 응원합니다!",
	})
	if err != nil {
		return err
	}

	// 오늘 남은 시간 계산 (KST 기준 자정까지)
	now := time.Now()
	loc, _ := time.LoadLocation("Asia/Seoul")
	if loc == nil {
		loc = time.Local
	}
	nowInLoc := now.In(loc)
	tomorrow := time.Date(nowInLoc.Year(), nowInLoc.Month(), nowInLoc.Day()+1, 0, 0, 0, 0, loc)
	ttl := tomorrow.Sub(nowInLoc)

	// Redis에 응원 기록 저장 (자정까지 유효)
	return u.rdb.Set(ctx, nudgeKey, "1", ttl).Err()
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

func (u *socialUsecase) DeleteGuestbook(userID, guestbookID int64) error {
	// 1. 방명록 조회
	entry, err := u.socialRepo.GetGuestbookByID(guestbookID)
	if err != nil {
		return err
	}
	if entry == nil {
		return errors.New("존재하지 않는 방명록 항목입니다.")
	}

	// 2. 권한 확인: 작성자거나 방명록 주인이어야 함
	if entry.WriterID != userID && entry.TargetUserID != userID {
		return errors.New("삭제 권한이 없습니다.")
	}

	// 3. 삭제 수행
	return u.socialRepo.DeleteGuestbook(guestbookID)
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

func (u *socialUsecase) GetSocialFeed(userID int64, filter domain.MealListFilter) ([]domain.MealRecord, int64, error) {
	ctx := context.Background()
	cacheKey := fmt.Sprintf("feed:%d:%d:%d", userID, filter.Cursor, filter.Limit)

	// 1. 캐시 확인
	if val, err := u.rdb.Get(ctx, cacheKey).Result(); err == nil {
		var cachedResult struct {
			Meals []domain.MealRecord `json:"meals"`
			Total int64               `json:"total"`
		}
		if err := json.Unmarshal([]byte(val), &cachedResult); err == nil {
			return cachedResult.Meals, cachedResult.Total, nil
		}
	}

	// 2. 친구 목록 조회
	friendships, err := u.socialRepo.GetFriends(userID)
	if err != nil {
		return nil, 0, err
	}

	// 3. 친구 ID 목록 추출
	friendIDs := make([]int64, 0, len(friendships)+1)
	for _, f := range friendships {
		if f.RequesterID == userID {
			friendIDs = append(friendIDs, f.ReceiverID)
		} else {
			friendIDs = append(friendIDs, f.RequesterID)
		}
	}
	friendIDs = append(friendIDs, userID) // 본인 소식 포함

	// 4. 식사 기록 조회
	meals, total, err := u.mealRepo.FindFriendMeals(friendIDs, filter)
	if err != nil {
		return nil, 0, err
	}

	// 5. 캐시 저장 (1분)
	cacheData := struct {
		Meals []domain.MealRecord `json:"meals"`
		Total int64               `json:"total"`
	}{
		Meals: meals,
		Total: total,
	}
	if b, err := json.Marshal(cacheData); err == nil {
		_ = u.rdb.Set(ctx, cacheKey, b, time.Minute).Err()
	}

	return meals, total, nil
}

func (u *socialUsecase) GetSocialRanking(ctx context.Context) ([]RankingEntry, error) {
	// 1. 상위 10명 조회
	zItems, err := u.rdb.ZRevRangeWithScores(ctx, RankingWeeklyKey, 0, 9).Result()
	if err != nil {
		return nil, err
	}

	ranking := make([]RankingEntry, 0, len(zItems))
	for i, item := range zItems {
		userID, _ := strconv.ParseInt(item.Member.(string), 10, 64)
		
		// 유저 정보 조회
		user, err := u.userRepo.GetByID(userID)
		if err != nil {
			continue
		}

		// 캐릭터 레벨 및 상태 조회
		char, _ := u.characterRepo.GetByUserID(userID)

		entry := RankingEntry{
			UserID:   userID,
			Nickname: user.Nickname,
			Score:    item.Score,
			Rank:     i + 1,
		}
		if char != nil {
			entry.Level = char.Level
			entry.PenaltyStatus = string(char.PenaltyStatus)
		} else {
			entry.Level = 1
			entry.PenaltyStatus = "NORMAL"
		}
		ranking = append(ranking, entry)
	}

	return ranking, nil
}
