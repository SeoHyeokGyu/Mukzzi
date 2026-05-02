package dto

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
)

type RouletteResponse struct {
	Candidates []MenuResponse `json:"candidates"`
	Menu       MenuResponse   `json:"menu"`
	Reason     string         `json:"reason"`
}

func ToRouletteResponse(candidates []domain.Menu, menu domain.Menu, reason string) RouletteResponse {
	candidateResponses := make([]MenuResponse, 0, len(candidates))
	for _, c := range candidates {
		candidateResponses = append(candidateResponses, MenuResponse{
			ID:                  c.ID,
			Name:                c.Name,
			Category:            string(c.Category),
			Source:              string(c.Source),
			DefaultCalories:     c.DefaultCalories,
			DefaultCarbs:        c.DefaultCarbs,
			DefaultProtein:      c.DefaultProtein,
			DefaultFat:          c.DefaultFat,
			DefaultFiber:        c.DefaultFiber,
			DefaultVitaminScore: c.DefaultVitaminScore,
		})
	}
	return RouletteResponse{
		Candidates: candidateResponses,
		Menu: MenuResponse{
			ID:                  menu.ID,
			Name:                menu.Name,
			Category:            string(menu.Category),
			Source:              string(menu.Source),
			DefaultCalories:     menu.DefaultCalories,
			DefaultCarbs:        menu.DefaultCarbs,
			DefaultProtein:      menu.DefaultProtein,
			DefaultFat:          menu.DefaultFat,
			DefaultFiber:        menu.DefaultFiber,
			DefaultVitaminScore: menu.DefaultVitaminScore,
		},
		Reason: reason,
	}
}
