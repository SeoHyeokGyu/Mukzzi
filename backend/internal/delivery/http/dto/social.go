package dto

import "github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"

// GuestbookCreateRequest 방명록 작성 요청
type GuestbookCreateRequest struct {
	Content  string `json:"content" binding:"required"`
	IsSecret bool   `json:"is_secret"`
}

// ReportCreateRequest 유저 신고 요청
type ReportCreateRequest struct {
	Reason domain.ReportReason `json:"reason" binding:"required"`
	Detail string              `json:"detail"`
}
