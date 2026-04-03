package usecase

import (
	"context"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
	"gorm.io/gorm"
)

// BadgeUsecase 뱃지 유즈케이스 인터페이스
type BadgeUsecase interface {
	// GetBadges 뱃지 목록 조회 (획득/미획득 포함 여부 제어 가능)
	GetBadges(ctx context.Context, query domain.GetBadgesQuery) (*domain.GetBadgesResult, error)
}

// badgeUsecaseImpl 뱃지 유즈케이스 구현체
type badgeUsecaseImpl struct {
	badgeRepository repository.BadgeRepository
	db              *gorm.DB
}

// NewBadgeUsecase 뱃지 유즈케이스 생성
func NewBadgeUsecase(
	badgeRepository repository.BadgeRepository,
	db *gorm.DB,
) BadgeUsecase {
	return &badgeUsecaseImpl{
		badgeRepository: badgeRepository,
		db:              db,
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

	// offset 계산 (cursor 기반 페이지네이션)
	offset := 0
	if query.Cursor != "" {
		// cursor 기반 offset 계산 (실제 구현에서는 더 정교한 로직 필요)
		offset = 0 // TODO: cursor 파싱 및 offset 계산 로직 구현
	}

	// 모든 뱃지 조회
	allBadges, err := u.badgeRepository.FindAllBadges(u.db, limit+1, offset)
	if err != nil {
		return nil, err
	}

	// 사용자가 획득한 뱃지 조회
	var acquiredBadges map[int64]*domain.UserBadge
	acquiredBadges = make(map[int64]*domain.UserBadge)

	if query.UserID > 0 {
		userBadges, err := u.badgeRepository.FindUserAcquiredBadges(u.db, query.UserID)
		if err != nil {
			return nil, err
		}
		for i := range userBadges {
			acquiredBadges[userBadges[i].BadgeID] = &userBadges[i]
		}
	}

	// 응답 생성
	var badgeResponses []domain.BadgeResponse
	for i, badge := range allBadges {
		// limit 초과 데이터는 has_next 판단용만으로 사용
		if i >= limit {
			break
		}

		// 획득/미획득 필터링
		userBadge, isAcquired := acquiredBadges[badge.ID]
		if !query.IncludeAcquired && isAcquired {
			continue
		}

		response := domain.BadgeResponse{
			ID:          badge.ID,
			Code:        badge.Code,
			Name:        badge.Name,
			Description: badge.Description,
			IconURL:     badge.IconURL,
			Acquired:    isAcquired,
		}

		if isAcquired && userBadge != nil {
			response.AcquiredAt = &userBadge.AcquiredAt
		}

		badgeResponses = append(badgeResponses, response)
	}

	// has_next 판단
	hasNext := len(allBadges) > limit

	// next_cursor 계산
	nextCursor := ""
	if hasNext && len(badgeResponses) > 0 {
		nextCursor = badgeResponses[len(badgeResponses)-1].Code
	}

	return &domain.GetBadgesResult{
		Badges:     badgeResponses,
		NextCursor: nextCursor,
		HasNext:    hasNext,
		Limit:      limit,
	}, nil
}
