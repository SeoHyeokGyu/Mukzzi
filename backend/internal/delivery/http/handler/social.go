package handler

import (
	"strconv"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/dto"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
)

type SocialHandler struct {
	socialUsecase usecase.SocialUsecase
}

func NewSocialHandler(socialUsecase usecase.SocialUsecase) *SocialHandler {
	return &SocialHandler{socialUsecase: socialUsecase}
}

// GetFriends 내 친구 목록 조회
// @Summary      내 친구 목록 조회
// @Description  현재 로그인한 사용자의 승인된 친구 목록을 조회합니다.
// @Tags         social
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  Response
// @Failure      401  {object}  Response
// @Failure      500  {object}  Response
// @Router       /api/friends [get]
func (h *SocialHandler) GetFriends(c *gin.Context) {
	userID, _ := c.Get("userID")
	friends, err := h.socialUsecase.GetFriends(userID.(int64))
	if err != nil {
		InternalError(c, "친구 목록 조회에 실패했습니다.", err.Error())
		return
	}

	resps := make([]dto.UserResponse, len(friends))
	for i, f := range friends {
		resps[i] = dto.ToUserResponse(&f)
	}

	Success(c, resps)
}

// DeleteFriend 친구 삭제
// @Summary      친구 삭제
// @Description  특정 사용자와의 친구 관계를 삭제합니다.
// @Tags         social
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        userId  path      int64  true  "친구 사용자 ID"
// @Success      200     {object}  Response
// @Failure      400     {object}  Response
// @Failure      401     {object}  Response
// @Router       /api/friends/{userId} [delete]
func (h *SocialHandler) DeleteFriend(c *gin.Context) {
	userID, _ := c.Get("userID")
	friendID, err := strconv.ParseInt(c.Param("userId"), 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "잘못된 사용자 ID입니다.")
		return
	}

	if err := h.socialUsecase.DeleteFriend(userID.(int64), friendID); err != nil {
		InternalError(c, "친구 삭제에 실패했습니다.", err.Error())
		return
	}
	Success(c, nil)
}

// GetPendingRequests 받은 친구 요청 목록
// @Summary      받은 친구 요청 목록
// @Description  나에게 온 대기 중인 친구 요청 목록을 조회합니다.
// @Tags         social
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  Response
// @Failure      401  {object}  Response
// @Router       /api/friends/requests [get]
func (h *SocialHandler) GetPendingRequests(c *gin.Context) {
	userID, _ := c.Get("userID")
	requests, err := h.socialUsecase.GetPendingRequests(userID.(int64))
	if err != nil {
		InternalError(c, "친구 요청 목록 조회에 실패했습니다.", err.Error())
		return
	}

	resps := make([]dto.UserResponse, len(requests))
	for i, r := range requests {
		resps[i] = dto.ToUserResponse(&r)
	}

	Success(c, resps)
}

// GetSentRequests 내가 보낸 친구 요청 목록
func (h *SocialHandler) GetSentRequests(c *gin.Context) {
	userID, _ := c.Get("userID")
	requests, err := h.socialUsecase.GetSentRequests(userID.(int64))
	if err != nil {
		InternalError(c, "보낸 요청 목록 조회에 실패했습니다.", err.Error())
		return
	}

	resps := make([]dto.UserResponse, len(requests))
	for i, r := range requests {
		resps[i] = dto.ToUserResponse(&r)
	}

	Success(c, resps)
}

// SendFriendRequest 친구 요청 전송
// @Summary      친구 요청 전송
// @Description  특정 사용자에게 친구 요청을 보냅니다.
// @Tags         social
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        userId  path      int64  true  "대상 사용자 ID"
// @Success      200     {object}  Response
// @Failure      400     {object}  Response
// @Failure      401     {object}  Response
// @Router       /api/friends/requests/{userId} [post]
func (h *SocialHandler) SendFriendRequest(c *gin.Context) {
	userID, _ := c.Get("userID")
	receiverID, err := strconv.ParseInt(c.Param("userId"), 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "잘못된 사용자 ID입니다.")
		return
	}

	if err := h.socialUsecase.SendFriendRequest(userID.(int64), receiverID); err != nil {
		BadRequest(c, "REQUEST_FAILED", err.Error())
		return
	}
	Success(c, nil)
}

// AcceptFriendRequest 친구 요청 수락
// @Summary      친구 요청 수락
// @Description  나에게 온 친구 요청을 수락합니다.
// @Tags         social
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        userId  path      int64  true  "요청한 사용자 ID"
// @Success      200     {object}  Response
// @Failure      400     {object}  Response
// @Router       /api/friends/requests/{userId}/accept [patch]
func (h *SocialHandler) AcceptFriendRequest(c *gin.Context) {
	userID, _ := c.Get("userID")
	requesterID, err := strconv.ParseInt(c.Param("userId"), 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "잘못된 사용자 ID입니다.")
		return
	}

	if err := h.socialUsecase.AcceptFriendRequest(userID.(int64), requesterID); err != nil {
		InternalError(c, "요청 수락에 실패했습니다.", err.Error())
		return
	}
	Success(c, nil)
}

// RejectFriendRequest 친구 요청 거절
// @Summary      친구 요청 거절
// @Description  나에게 온 친구 요청을 거절합니다.
// @Tags         social
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        userId  path      int64  true  "요청한 사용자 ID"
// @Success      200     {object}  Response
// @Router       /api/friends/requests/{userId}/reject [patch]
func (h *SocialHandler) RejectFriendRequest(c *gin.Context) {
	userID, _ := c.Get("userID")
	requesterID, err := strconv.ParseInt(c.Param("userId"), 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "잘못된 사용자 ID입니다.")
		return
	}

	if err := h.socialUsecase.RejectFriendRequest(userID.(int64), requesterID); err != nil {
		InternalError(c, "요청 거절에 실패했습니다.", err.Error())
		return
	}
	Success(c, nil)
}

// Nudge 응원하기
// @Summary      응원하기
// @Description  특정 사용자에게 응원 메시지를 보냅니다. (1일 1회 제한)
// @Tags         social-interaction
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id   path      int64  true  "대상 사용자 ID"
// @Success      200  {object}  Response
// @Router       /api/users/{id}/nudge [post]
func (h *SocialHandler) Nudge(c *gin.Context) {
	userID, _ := c.Get("userID")
	receiverID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "잘못된 사용자 ID입니다.")
		return
	}

	if err := h.socialUsecase.Nudge(userID.(int64), receiverID); err != nil {
		InternalError(c, "응원하기에 실패했습니다.", err.Error())
		return
	}
	Success(c, nil)
}

// GetGuestbooks 방명록 조회
// @Summary      방명록 조회
// @Description  특정 사용자의 방명록 목록을 조회합니다.
// @Tags         social-interaction
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id     path      int64  true   "대상 사용자 ID"
// @Param        page   query     int    false  "페이지 번호"
// @Param        limit  query     int    false  "페이지당 항목 수"
// @Success      200    {object}  Response
// @Router       /api/users/{id}/guestbook [get]
func (h *SocialHandler) GetGuestbooks(c *gin.Context) {
	targetID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "잘못된 사용자 ID입니다.")
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	entries, err := h.socialUsecase.GetGuestbooks(targetID, page, limit)
	if err != nil {
		InternalError(c, "방명록 조회에 실패했습니다.", err.Error())
		return
	}
	Success(c, entries)
}

// WriteGuestbook 방명록 작성
// @Summary      방명록 작성
// @Description  특정 사용자의 프로필에 방명록을 남깁니다.
// @Tags         social-interaction
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id       path      int64                    true  "대상 사용자 ID"
// @Param        request  body      dto.GuestbookCreateRequest  true  "방명록 내용"
// @Success      200      {object}  Response
// @Router       /api/users/{id}/guestbook [post]
func (h *SocialHandler) WriteGuestbook(c *gin.Context) {
	userID, _ := c.Get("userID")
	targetID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "잘못된 사용자 ID입니다.")
		return
	}

	var req dto.GuestbookCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "잘못된 요청 형식입니다.")
		return
	}

	entry := &domain.Guestbook{
		TargetUserID: targetID,
		WriterID:     userID.(int64),
		Content:      req.Content,
		IsSecret:     req.IsSecret,
	}

	if err := h.socialUsecase.WriteGuestbook(entry); err != nil {
		InternalError(c, "방명록 작성에 실패했습니다.", err.Error())
		return
	}
	Success(c, nil)
}

// DeleteGuestbook 방명록 삭제
// @Summary      방명록 삭제
// @Description  방명록 항목을 삭제합니다. (작성자 또는 방명록 주인만 가능)
// @Tags         social-interaction
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id           path      int64  true  "대상 사용자 ID"
// @Param        guestbookId  path      int64  true  "방명록 항목 ID"
// @Success      200          {object}  Response
// @Failure      400          {object}  Response
// @Failure      403          {object}  Response
// @Router       /api/users/{id}/guestbook/{guestbookId} [delete]
func (h *SocialHandler) DeleteGuestbook(c *gin.Context) {
	userID, _ := c.Get("userID")
	guestbookID, err := strconv.ParseInt(c.Param("guestbookId"), 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "잘못된 방명록 ID입니다.")
		return
	}

	if err := h.socialUsecase.DeleteGuestbook(userID.(int64), guestbookID); err != nil {
		if err.Error() == "삭제 권한이 없습니다." {
			Forbidden(c, "PERMISSION_DENIED", err.Error())
			return
		}
		InternalError(c, "방명록 삭제에 실패했습니다.", err.Error())
		return
	}
	Success(c, nil)
}

// BlockUser 사용자 차단
// @Summary      사용자 차단
// @Description  특정 사용자를 차단합니다. 차단 시 친구 관계가 삭제됩니다.
// @Tags         social-interaction
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id   path      int64  true  "차단할 사용자 ID"
// @Success      200  {object}  Response
// @Router       /api/users/{id}/block [post]
func (h *SocialHandler) BlockUser(c *gin.Context) {
	userID, _ := c.Get("userID")
	targetID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "잘못된 사용자 ID입니다.")
		return
	}

	if err := h.socialUsecase.BlockUser(userID.(int64), targetID); err != nil {
		InternalError(c, "사용자 차단에 실패했습니다.", err.Error())
		return
	}
	Success(c, nil)
}

// UnblockUser 차단 해제
// @Summary      차단 해제
// @Description  차단된 사용자의 차단을 해제합니다.
// @Tags         social-interaction
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id   path      int64  true  "해제할 사용자 ID"
// @Success      200  {object}  Response
// @Router       /api/users/{id}/block [delete]
func (h *SocialHandler) UnblockUser(c *gin.Context) {
	userID, _ := c.Get("userID")
	targetID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "잘못된 사용자 ID입니다.")
		return
	}

	if err := h.socialUsecase.UnblockUser(userID.(int64), targetID); err != nil {
		InternalError(c, "차단 해제에 실패했습니다.", err.Error())
		return
	}
	Success(c, nil)
}

// ReportUser 사용자 신고
// @Summary      사용자 신고
// @Description  부적절한 행위를 한 사용자를 신고합니다.
// @Tags         social-interaction
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id       path      int64                 true  "신고 대상 사용자 ID"
// @Param        request  body      dto.ReportCreateRequest  true  "신고 사유"
// @Success      200      {object}  Response
// @Router       /api/users/{id}/report [post]
func (h *SocialHandler) ReportUser(c *gin.Context) {
	userID, _ := c.Get("userID")
	targetID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "잘못된 사용자 ID입니다.")
		return
	}

	var req dto.ReportCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "잘못된 요청 형식입니다.")
		return
	}

	report := &domain.Report{
		ReporterID:   userID.(int64),
		TargetUserID: targetID,
		Reason:       req.Reason,
		Detail:       req.Detail,
	}

	if err := h.socialUsecase.ReportUser(report); err != nil {
		InternalError(c, "신고 접수에 실패했습니다.", err.Error())
		return
	}
	Success(c, nil)
}

// GetSocialFeed 소셜 피드 조회
// @Summary      소셜 피드 조회
// @Description  친구들의 최근 식사 기록(피드)을 조회합니다.
// @Tags         social
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        cursor  query     int64  false  "커서 (마지막 항목 ID)"
// @Param        limit   query     int    false  "페이지당 항목 수"
// @Success      200     {object}  Response
// @Router       /api/social/feed [get]
func (h *SocialHandler) GetSocialFeed(c *gin.Context) {
	userID, _ := c.Get("userID")

	cursor, _ := strconv.ParseInt(c.Query("cursor"), 10, 64)
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	filter := domain.MealListFilter{
		Cursor: cursor,
		Limit:  limit,
	}

	meals, total, err := h.socialUsecase.GetSocialFeed(userID.(int64), filter)
	if err != nil {
		InternalError(c, "피드 조회에 실패했습니다.", err.Error())
		return
	}

	var nextCursor string
	if len(meals) > 0 && len(meals) >= limit {
		nextCursor = strconv.FormatInt(meals[len(meals)-1].ID, 10)
	}

	mealResps := make([]dto.MealResponse, len(meals))
	for i, m := range meals {
		mealResps[i] = dto.ToMealResponse(&m)
	}

	Success(c, dto.SocialFeedResponse{
		Meals:      mealResps,
		Total:      total,
		NextCursor: nextCursor,
		HasNext:    nextCursor != "",
	})
}

// GetSocialRanking 소셜 랭킹 조회
// @Summary      소셜 랭킹 조회
// @Description  주간 경험치 획득 상위 10명을 조회합니다.
// @Tags         social
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200     {object}  Response
// @Router       /api/social/ranking [get]
func (h *SocialHandler) GetSocialRanking(c *gin.Context) {
	ranking, err := h.socialUsecase.GetSocialRanking(c.Request.Context())
	if err != nil {
		InternalError(c, "랭킹 조회에 실패했습니다.", err.Error())
		return
	}
	Success(c, dto.ToRankingResponses(ranking))
}

// VisitFriend 캐릭터 룸 방문 상호작용
// @Summary      캐릭터 룸 방문 상호작용
// @Description  친구의 캐릭터 룸을 방문하여 먹이주기 또는 응원하기 상호작용을 진행합니다.
// @Tags         social-interaction
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id       path      int64             true  "대상 사용자 ID"
// @Param        request  body      dto.VisitRequest  true  "상호작용 정보"
// @Success      200      {object}  Response
// @Failure      400      {object}  Response
// @Failure      401      {object}  Response
// @Router       /api/users/{id}/visit [post]
func (h *SocialHandler) VisitFriend(c *gin.Context) {
	userID, _ := c.Get("userID")
	hostID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_ID", "잘못된 사용자 ID입니다.")
		return
	}

	var req dto.VisitRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "잘못된 요청 형식입니다.")
		return
	}

	points, score, err := h.socialUsecase.VisitFriend(userID.(int64), hostID, req.InteractionType)
	if err != nil {
		if err == usecase.ErrNotFriend || err == usecase.ErrDailyInteractionLimitExceeded || err == usecase.ErrAlreadyVisitedToday {
			BadRequest(c, "VISIT_FAILED", err.Error())
			return
		}
		InternalError(c, "캐릭터 방문에 실패했습니다.", err.Error())
		return
	}

	Success(c, dto.VisitResponse{
		VisitorPointEarned:     points,
		CurrentFriendshipScore: score,
	})
}

// GetFriendsComparison 친구 비교 데이터 조회
// @Summary      친구 비교 데이터 조회
// @Description  나를 포함한 친구들의 누적 경험치, 연속 스트릭, 뱃지 개수 등의 비교 데이터를 가져옵니다.
// @Tags         social
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200      {object}  Response
// @Failure      401      {object}  Response
// @Router       /api/social/friends/comparison [get]
func (h *SocialHandler) GetFriendsComparison(c *gin.Context) {
	userID, _ := c.Get("userID")

	entries, err := h.socialUsecase.GetFriendsComparison(userID.(int64))
	if err != nil {
		InternalError(c, "친구 비교 데이터 조회에 실패했습니다.", err.Error())
		return
	}

	Success(c, entries)
}
