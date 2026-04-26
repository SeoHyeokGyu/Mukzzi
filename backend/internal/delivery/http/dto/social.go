package dto

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
)

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

// RankingResponse 랭킹 항목 응답
type RankingResponse struct {
	UserID   string  `json:"user_id"`
	Nickname string  `json:"nickname"`
	Level    int     `json:"level"`
	Score    float64 `json:"score"`
	Rank     int     `json:"rank"`
}

// SocialFeedResponse 소셜 피드 목록 응답
type SocialFeedResponse struct {
	Meals      []MealResponse `json:"meals"`
	Total      int64          `json:"total"`
	NextCursor string         `json:"next_cursor"`
	HasNext    bool           `json:"has_next"`
}

// ToRankingResponse 랭킹 항목 변환
func ToRankingResponse(e usecase.RankingEntry) RankingResponse {
	return RankingResponse{
		UserID:   e.UserIDString(),
		Nickname: e.Nickname,
		Level:    e.Level,
		Score:    e.Score,
		Rank:     e.Rank,
	}
}

// ToRankingResponses 랭킹 목록 변환
func ToRankingResponses(entries []usecase.RankingEntry) []RankingResponse {
	resps := make([]RankingResponse, len(entries))
	for i, e := range entries {
		resps[i] = ToRankingResponse(e)
	}
	return resps
}
