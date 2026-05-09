package usecase

import (
	"context"
	"fmt"
	"strconv"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

// BadgeError 뱃지 관련 에러 — handler에서 type-assert로 구조화된 응답에 사용됩니다.
type BadgeError struct {
	Code    string
	Message string
	Details string
}

func (e *BadgeError) Error() string {
	return fmt.Sprintf("[%s] %s: %s", e.Code, e.Message, e.Details)
}

// BadgeWithProgress 뱃지 정보와 진행도
type BadgeWithProgress struct {
	domain.Badge
	Progress int
	Target   int
}

// GetBadgesResult 뱃지 목록 조회 결과 (진행도 포함)
type GetBadgesResult struct {
	Badges      []BadgeWithProgress
	AcquiredMap map[int64]*domain.UserBadge
	NextCursor  string
	HasNext     bool
	Limit       int
}

// BadgeUsecase 뱃지 유즈케이스 인터페이스
type BadgeUsecase interface {
	GetBadges(ctx context.Context, query domain.GetBadgesQuery) (*GetBadgesResult, error)
}

type badgeUsecaseImpl struct {
	badgeRepository repository.BadgeRepository
	badgeGranter    BadgeGranter
}

func NewBadgeUsecase(badgeRepository repository.BadgeRepository, badgeGranter BadgeGranter) BadgeUsecase {
	return &badgeUsecaseImpl{
		badgeRepository: badgeRepository,
		badgeGranter:    badgeGranter,
	}
}

func (u *badgeUsecaseImpl) GetBadges(ctx context.Context, query domain.GetBadgesQuery) (*GetBadgesResult, error) {
	limit := query.Limit
	if limit <= 0 {
		limit = 20
	}
	if limit > 50 {
		limit = 50
	}

	offset := 0
	if query.Cursor != "" {
		if parsed, err := strconv.Atoi(query.Cursor); err == nil && parsed > 0 {
			offset = parsed
		}
	}

	acquiredMap := make(map[int64]*domain.UserBadge)

	var badges []domain.Badge
	var err error

	if !query.IncludeAcquired && query.UserID > 0 {
		badges, err = u.badgeRepository.FindUnacquiredBadges(query.UserID, limit+1, offset)
		if err != nil {
			return nil, &BadgeError{Code: "BADGE_FETCH_ERROR", Message: "목록 조회 실패", Details: err.Error()}
		}
	} else {
		badges, err = u.badgeRepository.FindAllBadges(limit+1, offset)
		if err != nil {
			return nil, &BadgeError{Code: "BADGE_FETCH_ERROR", Message: "목록 조회 실패", Details: err.Error()}
		}

		if query.UserID > 0 {
			userBadges, err := u.badgeRepository.FindUserAcquiredBadges(query.UserID)
			if err == nil {
				for i := range userBadges {
					acquiredMap[userBadges[i].BadgeID] = &userBadges[i]
				}
			}
		}
	}

	hasNext := len(badges) > limit
	if hasNext {
		badges = badges[:limit]
	}

	nextCursor := ""
	if hasNext {
		nextCursor = strconv.Itoa(offset + limit)
	}

	badgesWithProgress := make([]BadgeWithProgress, len(badges))
	for i, b := range badges {
		progress, target, _ := u.badgeGranter.GetProgress(ctx, query.UserID, b.Code)
		badgesWithProgress[i] = BadgeWithProgress{
			Badge:    b,
			Progress: progress,
			Target:   target,
		}
	}

	return &GetBadgesResult{
		Badges:      badgesWithProgress,
		AcquiredMap: acquiredMap,
		NextCursor:  nextCursor,
		HasNext:     hasNext,
		Limit:       limit,
	}, nil
}
