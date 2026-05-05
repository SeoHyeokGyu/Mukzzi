package handler

import (
	"strconv"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/dto"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
)

type QuestHandler struct {
	questUc usecase.QuestUsecase
}

func NewQuestHandler(questUc usecase.QuestUsecase) *QuestHandler {
	return &QuestHandler{questUc: questUc}
}

// GetMyQuests godoc
// @Summary      내 퀘스트 목록 조회
// @Description  현재 진행 중인 일일/주간/업적 퀘스트 목록을 조회합니다.
// @Tags         Quest
// @Accept       json
// @Produce      json
// @Param        period  query     string  false  "DAILY, WEEKLY, ACHIEVEMENT 중 하나"
// @Success      200      {object}  Response{data=[]dto.UserQuestResponse}
// @Security     BearerAuth
// @Router       /api/quests [get]
func (h *QuestHandler) GetMyQuests(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		Unauthorized(c, "UNAUTHORIZED", "인증 정보가 없습니다.")
		return
	}
	period := c.Query("period")

	quests, err := h.questUc.GetMyQuests(c.Request.Context(), userID.(int64), period)
	if err != nil {
		InternalError(c, "퀘스트 목록을 가져오는데 실패했습니다.", err.Error())
		return
	}

	Success(c, dto.ToUserQuestListResponse(quests))
}

// ClaimReward godoc
// @Summary      퀘스트 보상 수령
// @Description  완료된 퀘스트의 보상을 수령합니다.
// @Tags         Quest
// @Accept       json
// @Produce      json
// @Param        id   path      string  true  "유저 퀘스트 ID"
// @Success      200  {object}  Response{data=string}
// @Security     BearerAuth
// @Router       /api/quests/{id}/claim [post]
func (h *QuestHandler) ClaimReward(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		Unauthorized(c, "UNAUTHORIZED", "인증 정보가 없습니다.")
		return
	}
	userQuestID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "올바른 퀘스트 ID를 입력해주세요.")
		return
	}

	if err := h.questUc.ClaimReward(c.Request.Context(), userID.(int64), userQuestID); err != nil {
		BadRequest(c, "CLAIM_ERROR", err.Error())
		return
	}

	Success(c, "보상이 지급되었습니다.")
}
