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

// BadgeUsecase 뱃지 유즈케이스 인터페이스
type BadgeUsecase interface {
	GetBadges(ctx context.Context, query domain.GetBadgesQuery) (*domain.GetBadgesResult, error)
}

type badgeUsecaseImpl struct {
	badgeRepository repository.BadgeRepository
}

func NewBadgeUsecase(badgeRepository repository.BadgeRepository) BadgeUsecase {
	return &badgeUsecaseImpl{badgeRepository: badgeRepository}
}

func (u *badgeUsecaseImpl) GetBadges(ctx context.Context, query domain.GetBadgesQuery) (*domain.GetBadgesResult, error) {
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
		// 미획득 뱃지만 DB에서 필터링 — 앱 레이어 필터링 시 hasNext 판단 부정확 문제 해소
		badges, err = u.badgeRepository.FindUnacquiredBadges(query.UserID, limit+1, offset)
		if err != nil {
			return nil, &BadgeError{
				Code:    "BADGE_FETCH_ERROR",
				Message: "미획득 뱃지 목록을 조회하는 중에 오류가 발생했습니다.",
				Details: err.Error(),
			}
		}
	} else {
		badges, err = u.badgeRepository.FindAllBadges(limit+1, offset)
		if err != nil {
			return nil, &BadgeError{
				Code:    "BADGE_FETCH_ERROR",
				Message: "뱃지 목록을 조회하는 중에 오류가 발생했습니다.",
				Details: err.Error(),
			}
		}

		if query.UserID > 0 {
			userBadges, err := u.badgeRepository.FindUserAcquiredBadges(query.UserID)
			if err != nil {
				return nil, &BadgeError{
					Code:    "USER_BADGE_FETCH_ERROR",
					Message: "사용자의 뱃지 정보를 조회하는 중에 오류가 발생했습니다.",
					Details: err.Error(),
				}
			}
			for i := range userBadges {
				acquiredMap[userBadges[i].BadgeID] = &userBadges[i]
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

	return &domain.GetBadgesResult{
		Badges:      badges,
		AcquiredMap: acquiredMap,
		NextCursor:  nextCursor,
		HasNext:     hasNext,
		Limit:       limit,
	}, nil
}
