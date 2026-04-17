package usecase

import (
	"context"
	"fmt"
	"strconv"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

// BadgeError 뱃지 관련 에러
type BadgeError struct {
	Code    string
	Message string
	Details string
}

// Error BadgeError 에러 구현
func (e *BadgeError) Error() string {
	return fmt.Sprintf("[%s] %s: %s", e.Code, e.Message, e.Details)
}

// BadgeUsecase 뱃지 유즈케이스 인터페이스
type BadgeUsecase interface {
	// GetBadges 뱃지 목록 조회 (획득/미획득 포함 여부 제어 가능)
	GetBadges(ctx context.Context, query domain.GetBadgesQuery) (*domain.GetBadgesResult, error)
}

// badgeUsecaseImpl 뱃지 유즈케이스 구현체
type badgeUsecaseImpl struct {
	badgeRepository repository.BadgeRepository
}

// NewBadgeUsecase 뱃지 유즈케이스 생성
func NewBadgeUsecase(
	badgeRepository repository.BadgeRepository,
) BadgeUsecase {
	return &badgeUsecaseImpl{
		badgeRepository: badgeRepository,
	}
}

// GetBadges 뱃지 목록 조회
func (u *badgeUsecaseImpl) GetBadges(ctx context.Context, query domain.GetBadgesQuery) (*domain.GetBadgesResult, error) {
	// limit 기본값 및 최대값 제한
	limit := query.Limit
	if limit <= 0 {
		limit = 20
	}
	if limit > 50 {
		limit = 50
	}

	// cursor는 다음 페이지 시작 offset을 인코딩한 숫자 문자열
	offset := 0
	if query.Cursor != "" {
		if parsed, err := strconv.Atoi(query.Cursor); err == nil && parsed > 0 {
			offset = parsed
		}
	}

	// 모든 뱃지 조회
	allBadges, err := u.badgeRepository.FindAllBadges(limit+1, offset)
	if err != nil {
		return nil, &BadgeError{
			Code:    "BADGE_FETCH_ERROR",
			Message: "뱃지 목록을 조회하는 중에 오류가 발생했습니다.",
			Details: err.Error(),
		}
	}

	// 사용자가 획득한 뱃지 조회
	var acquiredBadges map[int64]*domain.UserBadge
	acquiredBadges = make(map[int64]*domain.UserBadge)

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
			acquiredBadges[userBadges[i].BadgeID] = &userBadges[i]
		}
	}

	// 응답 생성
	var filteredBadges []domain.Badge
	for i, badge := range allBadges {
		// limit 초과 데이터는 has_next 판단용만으로 사용
		if i >= limit {
			break
		}

		// 획득/미획득 필터링
		_, isAcquired := acquiredBadges[badge.ID]
		if !query.IncludeAcquired && isAcquired {
			continue
		}

		filteredBadges = append(filteredBadges, badge)
	}

	// has_next 판단
	hasNext := len(allBadges) > limit

	// next_cursor: 다음 페이지 시작 offset
	nextCursor := ""
	if hasNext {
		nextCursor = strconv.Itoa(offset + limit)
	}

	return &domain.GetBadgesResult{
		Badges:      filteredBadges,
		AcquiredMap: acquiredBadges,
		NextCursor:  nextCursor,
		HasNext:     hasNext,
		Limit:       limit,
	}, nil
}
