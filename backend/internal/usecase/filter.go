package usecase

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

const filterLimit = 5

type FilterResult struct {
	Menus  []domain.Menu
	Source string // "personal" | "global"
}

type MenuFilterUsecase interface {
	Filter(userID int64, weathers []string, moods []string) (*FilterResult, error)
}

type menuFilterUsecase struct {
	repo repository.MenuFilterRepository
}

func NewMenuFilterUsecase(repo repository.MenuFilterRepository) MenuFilterUsecase {
	return &menuFilterUsecase{repo: repo}
}

func (u *menuFilterUsecase) Filter(userID int64, weathers []string, moods []string) (*FilterResult, error) {
	// 1. 본인 기록 우선
	candidates, err := u.repo.GetByTagsForUser(userID, weathers, moods, filterLimit)
	if err != nil {
		return nil, err
	}

	source := "personal"

	// 2. 본인 기록 없으면 전체 유저 폴백
	if len(candidates) == 0 {
		candidates, err = u.repo.GetByTagsGlobal(weathers, moods, filterLimit)
		if err != nil {
			return nil, err
		}
		source = "global"
	}

	menus := make([]domain.Menu, 0, len(candidates))
	for _, c := range candidates {
		menus = append(menus, c.Menu)
	}

	return &FilterResult{
		Menus:  menus,
		Source: source,
	}, nil
}
