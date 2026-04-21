package usecase

import (
	"context"
	"log/slog"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

// masteryTitleCodes 마스터리 등급별 칭호 코드 매핑
var masteryTitleCodes = map[domain.MasteryGrade]string{
	domain.MasteryArtisan: "MASTERY_ARTISAN",
	domain.MasteryMaster:  "MASTERY_MASTER",
}

// TitleGranter 칭호 자동 부여 인터페이스
type TitleGranter interface {
	// OnMasteryGradeChanged 마스터리 등급 변경 시 해당 칭호를 부여합니다.
	// 새로 부여된 칭호를 반환하며, 이미 보유 중이거나 해당 없는 등급이면 nil을 반환합니다.
	OnMasteryGradeChanged(ctx context.Context, userID int64, grade domain.MasteryGrade) (*domain.Title, error)
}

type titleGranterImpl struct {
	titleRepo repository.TitleRepository
}

func NewTitleGranter(titleRepo repository.TitleRepository) TitleGranter {
	return &titleGranterImpl{titleRepo: titleRepo}
}

func (g *titleGranterImpl) OnMasteryGradeChanged(_ context.Context, userID int64, grade domain.MasteryGrade) (*domain.Title, error) {
	code, ok := masteryTitleCodes[grade]
	if !ok {
		return nil, nil
	}

	title, err := g.titleRepo.FindByCode(code)
	if err != nil {
		slog.Error("칭호 정보 조회 실패", slog.String("code", code), slog.Any("error", err))
		return nil, err
	}
	if title == nil {
		return nil, nil
	}

	existing, err := g.titleRepo.FindUserTitleByID(userID, title.ID)
	if err != nil {
		slog.Error("사용자 칭호 보유 여부 확인 실패", slog.Int64("user_id", userID), slog.String("code", code), slog.Any("error", err))
		return nil, err
	}
	if existing != nil {
		return nil, nil
	}

	userTitle := &domain.UserTitle{
		UserID:     userID,
		TitleID:    title.ID,
		AchievedAt: time.Now(),
	}
	if err := g.titleRepo.CreateUserTitle(userTitle); err != nil {
		slog.Error("칭호 부여 실패", slog.String("code", code), slog.Int64("user_id", userID), slog.Any("error", err))
		return nil, err
	}

	slog.Info("칭호 부여 완료", slog.String("code", code), slog.Int64("user_id", userID))
	return title, nil
}
