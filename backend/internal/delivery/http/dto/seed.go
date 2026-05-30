package dto

import "time"

// SeedMenusRequest POST /admin/menus/seed
type SeedMenusRequest struct {
	Source string `json:"source" binding:"omitempty,oneof=mfds usda all"`
	Limit  int    `json:"limit" binding:"omitempty,min=1,max=50000"`
}

// SeedJobStatusResponse GET /admin/menus/seed/status
type SeedJobStatusResponse struct {
	State     string     `json:"state"`
	Source    string     `json:"source,omitempty"`
	StartedAt *time.Time `json:"started_at,omitempty"`
	EndedAt   *time.Time `json:"ended_at,omitempty"`
	Inserted  int        `json:"inserted"`
	Skipped   int        `json:"skipped"`
	Error     string     `json:"error,omitempty"`
}

// ToggleScheduleRequest PATCH /admin/schedules/:key/toggle
type ToggleScheduleRequest struct {
	Enabled bool `json:"enabled"`
}
