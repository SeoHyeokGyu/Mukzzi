package dto

type SetPreferenceRequest struct {
	Preference string `json:"preference" binding:"required,oneof=LIKE DISLIKE"`
}
