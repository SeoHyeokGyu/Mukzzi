package dto

import (
	"strconv"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
)

type QuestResponse struct {
	ID          string `json:"id"`
	Code        string `json:"code"`
	Type        string `json:"type"`
	Category    string `json:"category"`
	Title       string `json:"title"`
	Description string `json:"description"`
	TargetCount int    `json:"target_count"`
	RewardPoint int    `json:"reward_point"`
	RewardExp   int    `json:"reward_exp"`
}

type UserQuestResponse struct {
	ID           string         `json:"id"`
	QuestID      string         `json:"quest_id"`
	CurrentCount int            `json:"current_count"`
	Status       string         `json:"status"`
	AssignedAt   time.Time      `json:"assigned_at"`
	ExpiresAt    time.Time      `json:"expires_at"`
	Quest        *QuestResponse `json:"Quest,omitempty"`
}

type QuestProgressResponse struct {
	QuestType  string `json:"quest_type"`
	QuestTitle string `json:"quest_title"`
	Progress   int    `json:"progress"`
	Target     int    `json:"target"`
	Completed  bool   `json:"completed"`
}

func ToQuestProgressResponse(qp domain.QuestProgress) QuestProgressResponse {
	return QuestProgressResponse{
		QuestType:  qp.QuestType,
		QuestTitle: qp.QuestTitle,
		Progress:   qp.Progress,
		Target:     qp.Target,
		Completed:  qp.Completed,
	}
}

func ToQuestProgressListResponse(qps []domain.QuestProgress) []QuestProgressResponse {
	resps := make([]QuestProgressResponse, len(qps))
	for i, qp := range qps {
		resps[i] = ToQuestProgressResponse(qp)
	}
	return resps
}

func ToUserQuestResponse(uq domain.UserQuest) UserQuestResponse {
	resp := UserQuestResponse{
		ID:           strconv.FormatInt(uq.ID, 10),
		QuestID:      strconv.FormatInt(uq.QuestID, 10),
		CurrentCount: uq.CurrentCount,
		Status:       string(uq.Status),
		AssignedAt:   uq.AssignedAt,
		ExpiresAt:    uq.ExpiresAt,
	}

	if uq.Quest != nil {
		resp.Quest = &QuestResponse{
			ID:          strconv.FormatInt(uq.Quest.ID, 10),
			Code:        uq.Quest.Code,
			Type:        string(uq.Quest.Type),
			Category:    string(uq.Quest.Category),
			Title:       uq.Quest.Title,
			Description: uq.Quest.Description,
			TargetCount: uq.Quest.TargetCount,
			RewardPoint: uq.Quest.RewardPoint,
			RewardExp:   uq.Quest.RewardExp,
		}
	}

	return resp
}

func ToUserQuestListResponse(quests []domain.UserQuest) []UserQuestResponse {
	resps := make([]UserQuestResponse, len(quests))
	for i, q := range quests {
		resps[i] = ToUserQuestResponse(q)
	}
	return resps
}
