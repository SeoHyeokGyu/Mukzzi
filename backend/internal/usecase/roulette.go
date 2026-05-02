package usecase

import (
	"errors"
	"math/rand"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
)

var ErrNoRouletteCandidate = errors.New("추천할 메뉴가 없습니다")

type RouletteResult struct {
	Candidates []domain.Menu
	Menu       domain.Menu
	Reason     string
}

type RouletteUsecase interface {
	Spin(userID int64) (*RouletteResult, error)
}

type rouletteUsecase struct {
	repo repository.RouletteRepository
}

func NewRouletteUsecase(repo repository.RouletteRepository) RouletteUsecase {
	return &rouletteUsecase{repo: repo}
}

func (u *rouletteUsecase) Spin(userID int64) (*RouletteResult, error) {
	candidates, err := u.repo.GetCandidates(userID)
	if err != nil {
		return nil, err
	}
	if len(candidates) == 0 {
		return nil, ErrNoRouletteCandidate
	}

	weights := make([]int, len(candidates))
	total := 0
	for i, c := range candidates {
		w := calcRouletteWeight(c.Grade, c.IsFavorite)
		weights[i] = w
		total += w
	}

	pick := rand.Intn(total)
	cumulative := 0
	selected := candidates[0]
	for i, c := range candidates {
		cumulative += weights[i]
		if pick < cumulative {
			selected = c
			break
		}
	}

	// 후보 메뉴 목록 추출
	menuList := make([]domain.Menu, 0, len(candidates))
	for _, c := range candidates {
		menuList = append(menuList, c.Menu)
	}

	return &RouletteResult{
		Candidates: menuList,
		Menu:       selected.Menu,
		Reason:     resolveRouletteReason(selected.IsFavorite, selected.Grade),
	}, nil
}

func calcRouletteWeight(grade string, isFavorite bool) int {
	w := 1
	switch grade {
	case "MASTER":
		w += 3
	case "ADVANCED":
		w += 2
	case "INTERMEDIATE":
		w += 1
	}
	if isFavorite {
		w += 3
	}
	return w
}

func resolveRouletteReason(isFavorite bool, grade string) string {
	if isFavorite {
		return "즐겨찾기 메뉴예요 ⭐"
	}
	switch grade {
	case "MASTER", "ADVANCED":
		return "자주 드시는 메뉴예요 🍽️"
	case "INTERMEDIATE":
		return "먹어본 메뉴예요 😋"
	default:
		return "오늘 이건 어때요? 🎲"
	}
}
