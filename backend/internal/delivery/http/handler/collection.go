package handler

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/dto"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/usecase"
	"github.com/gin-gonic/gin"
)

// CollectionHandler 컬렉션 핸들러
type CollectionHandler struct {
	badgeUsecase          usecase.BadgeUsecase
	charCollectionUsecase usecase.CharacterCollectionUsecase
	masteryUsecase        usecase.MasteryUsecase
	titleUsecase          usecase.TitleUsecase
	rewardUsecase         usecase.RewardUsecase
}

// NewCollectionHandler 컬렉션 핸들러 생성
func NewCollectionHandler(
	badgeUsecase usecase.BadgeUsecase,
	charCollectionUsecase usecase.CharacterCollectionUsecase,
	masteryUsecase usecase.MasteryUsecase,
	titleUsecase usecase.TitleUsecase,
	rewardUsecase usecase.RewardUsecase,
) *CollectionHandler {
	return &CollectionHandler{
		badgeUsecase:          badgeUsecase,
		charCollectionUsecase: charCollectionUsecase,
		masteryUsecase:        masteryUsecase,
		titleUsecase:          titleUsecase,
		rewardUsecase:         rewardUsecase,
	}
}

// GetBadges 뱃지 목록 조회
// @Summary      뱃지 목록 조회
// @Description  사용자의 획득/미획득 뱃지 목록을 커서 기반 페이지네이션으로 반환합니다.
// @Tags         collections
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        include_acquired  query     bool    false  "획득한 뱃지 포함 여부 (기본값: true)"
// @Param        limit             query     int     false  "페이지당 항목 수 (기본값: 20, 범위: 1-50)"
// @Param        cursor            query     string  false  "다음 페이지 커서"
// @Success      200  {object}  Response  "뱃지 목록 조회 성공"
// @Failure      400  {object}  Response  "잘못된 쿼리 파라미터"
// @Failure      401  {object}  Response  "인증 토큰 누락 또는 유효하지 않음"
// @Failure      500  {object}  Response  "서버 내부 에러"
// @Router       /api/collections/badges [get]
func (h *CollectionHandler) GetBadges(c *gin.Context) {
	userIDVal, exists := c.Get("userID")
	if !exists {
		Unauthorized(c, "UNAUTHORIZED", "인증 토큰이 누락되었거나 유효하지 않습니다.", "BearerToken을 포함한 Authorization 헤더를 확인하세요.")
		return
	}
	userID := userIDVal.(int64)

	includeAcquiredStr := c.Query("include_acquired")
	limitStr := c.Query("limit")
	cursor := c.Query("cursor")

	includeAcquired := true
	if includeAcquiredStr != "" {
		if includeAcquiredStr == "false" {
			includeAcquired = false
		} else if includeAcquiredStr != "true" {
			BadRequest(c, "INVALID_PARAMETER", "include_acquired 파라미터는 'true' 또는 'false'여야 합니다.", map[string]any{"parameter": "include_acquired"})
			return
		}
	}

	limit := 20
	if limitStr != "" {
		parsedLimit, err := strconv.Atoi(limitStr)
		if err != nil || parsedLimit <= 0 || parsedLimit > 50 {
			BadRequest(c, "INVALID_PARAMETER", "limit 파라미터는 1 이상 50 이하의 정수여야 합니다.", map[string]any{"parameter": "limit", "min": 1, "max": 50})
			return
		}
		limit = parsedLimit
	}

	result, err := h.badgeUsecase.GetBadges(c.Request.Context(), domain.GetBadgesQuery{
		UserID:          userID,
		IncludeAcquired: includeAcquired,
		Cursor:          cursor,
		Limit:           limit,
	})
	if err != nil {
		badgeErr, ok := err.(*usecase.BadgeError)
		if !ok {
			InternalError(c, "서버 내부 오류가 발생했습니다.")
			return
		}
		Error(c, http.StatusInternalServerError, badgeErr.Code, badgeErr.Message, badgeErr.Details)
		return
	}

	responses := make([]dto.BadgeResponse, len(result.Badges))
	for i, bp := range result.Badges {
		userBadge, isAcquired := result.AcquiredMap[bp.ID]
		responses[i] = dto.BadgeResponse{
			ID:          bp.ID,
			Code:        bp.Code,
			Name:        bp.Name,
			Description: bp.Description,
			IconURL:     bp.IconURL,
			Progress:    bp.Progress,
			Target:      bp.Target,
			Acquired:    isAcquired,
		}
		if isAcquired && userBadge != nil {
			responses[i].AcquiredAt = &userBadge.AcquiredAt
		}
	}

	CursorPaginated(c, responses, result.Limit, result.HasNext, result.NextCursor)
}

// GetCharacterCollections 먹찌 도감 조회
// @Summary      먹찌 도감 조회
// @Description  사용자가 달성한 먹찌 외형 컬렉션 목록을 반환합니다.
// @Tags         collections
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        page   query  int  false  "페이지 번호 (기본값: 1)"
// @Param        limit  query  int  false  "페이지당 항목 수 (기본값: 20, 최대: 100)"
// @Success      200  {object}  Response  "먹찌 도감 조회 성공"
// @Failure      401  {object}  Response  "인증 토큰 누락 또는 유효하지 않음"
// @Failure      500  {object}  Response  "서버 내부 에러"
// @Router       /api/collections/characters [get]
func (h *CollectionHandler) GetCharacterCollections(c *gin.Context) {
	userID := c.MustGet("userID").(int64)

	page, limit := parsePagination(c)

	collections, total, err := h.charCollectionUsecase.GetCharacterCollections(userID, page, limit)
	if err != nil {
		InternalError(c, "먹찌 도감을 조회하는 중에 오류가 발생했습니다.")
		return
	}

	responses := make([]dto.CharacterCollectionResponse, len(collections))
	for i, col := range collections {
		responses[i] = dto.CharacterCollectionResponse{
			ID:         col.ID,
			BodyType:   col.BodyType,
			Muscle:     col.Muscle,
			SkinTone:   col.SkinTone,
			Expression: col.Expression,
			AchievedAt: col.AchievedAt,
		}
	}

	Paginated(c, responses, total, page, limit)
}

// GetMasteries 마스터리 목록 조회
// @Summary      마스터리 목록 조회
// @Description  사용자의 메뉴 마스터리 목록을 반환합니다.
// @Tags         collections
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        page   query  int  false  "페이지 번호 (기본값: 1)"
// @Param        limit  query  int  false  "페이지당 항목 수 (기본값: 20, 최대: 50)"
// @Success      200  {object}  Response  "마스터리 목록 조회 성공"
// @Failure      401  {object}  Response  "인증 토큰 누락 또는 유효하지 않음"
// @Failure      500  {object}  Response  "서버 내부 에러"
// @Router       /api/collections/mastery [get]
func (h *CollectionHandler) GetMasteries(c *gin.Context) {
	userID := c.MustGet("userID").(int64)

	page, limit := parsePagination(c)

	masteries, total, err := h.masteryUsecase.GetMasteries(userID, page, limit)
	if err != nil {
		InternalError(c, "마스터리 목록을 조회하는 중에 오류가 발생했습니다.")
		return
	}

	responses := make([]dto.MasteryResponse, len(masteries))
	for i, m := range masteries {
		responses[i] = dto.MasteryResponse{
			ID:           m.ID,
			MenuID:       m.MenuID,
			MenuName:     m.Menu.Name,
			MenuCategory: m.Menu.Category,
			EatCount:     m.EatCount,
			Grade:        m.Grade,
			FirstEatenAt: m.FirstEatenAt,
			LastEatenAt:  m.LastEatenAt,
		}
	}

	Paginated(c, responses, total, page, limit)
}

// GetMasteryByMenu 특정 메뉴 마스터리 상세 조회
// @Summary      특정 메뉴 마스터리 상세 조회
// @Description  특정 메뉴에 대한 사용자의 마스터리 상세 정보를 반환합니다.
// @Tags         collections
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        menuId  path  string  true  "메뉴 ID"
// @Success      200  {object}  Response  "마스터리 상세 조회 성공"
// @Failure      400  {object}  Response  "잘못된 메뉴 ID"
// @Failure      401  {object}  Response  "인증 토큰 누락 또는 유효하지 않음"
// @Failure      404  {object}  Response  "마스터리 없음"
// @Failure      500  {object}  Response  "서버 내부 에러"
// @Router       /api/collections/mastery/{menuId} [get]
func (h *CollectionHandler) GetMasteryByMenu(c *gin.Context) {
	userID := c.MustGet("userID").(int64)

	menuIDStr := c.Param("menuId")
	menuID, err := strconv.ParseInt(menuIDStr, 10, 64)
	if err != nil {
		BadRequest(c, "INVALID_PARAMETER", "올바른 메뉴 ID를 입력해주세요.")
		return
	}

	mastery, err := h.masteryUsecase.GetMasteryByMenu(userID, menuID)
	if err != nil {
		InternalError(c, "마스터리 정보를 조회하는 중에 오류가 발생했습니다.")
		return
	}
	if mastery == nil {
		NotFound(c, "MASTERY_NOT_FOUND", "해당 메뉴의 마스터리 기록이 없습니다.")
		return
	}

	Success(c, dto.MasteryResponse{
		ID:           mastery.ID,
		MenuID:       mastery.MenuID,
		MenuName:     mastery.Menu.Name,
		MenuCategory: mastery.Menu.Category,
		EatCount:     mastery.EatCount,
		Grade:        mastery.Grade,
		FirstEatenAt: mastery.FirstEatenAt,
		LastEatenAt:  mastery.LastEatenAt,
	})
}

// GetTitles 칭호 목록 조회
// @Summary      칭호 목록 조회
// @Description  전체 칭호 목록과 획득/장착 여부를 반환합니다.
// @Tags         collections
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  Response  "칭호 목록 조회 성공"
// @Failure      401  {object}  Response  "인증 토큰 누락 또는 유효하지 않음"
// @Failure      500  {object}  Response  "서버 내부 에러"
// @Router       /api/collections/titles [get]
func (h *CollectionHandler) GetTitles(c *gin.Context) {
	userID := c.MustGet("userID").(int64)

	titles, acquiredMap, equippedTitleID, err := h.titleUsecase.GetTitles(userID)
	if err != nil {
		InternalError(c, "칭호 목록을 조회하는 중에 오류가 발생했습니다.")
		return
	}

	responses := make([]dto.TitleResponse, len(titles))
	for i, title := range titles {
		ut, acquired := acquiredMap[title.ID]
		resp := dto.TitleResponse{
			ID:          title.ID,
			Code:        title.Code,
			Name:        title.Name,
			Description: title.Description,
			Acquired:    acquired,
			IsEquipped:  equippedTitleID != nil && *equippedTitleID == title.ID,
		}
		if acquired && ut != nil {
			resp.AchievedAt = &ut.AchievedAt
		}
		responses[i] = resp
	}

	Success(c, responses)
}

// EquipTitle 칭호 장착/해제
// @Summary      칭호 장착/해제
// @Description  보유한 칭호를 장착하거나 해제합니다. title_id를 null로 전송하면 해제됩니다.
// @Tags         collections
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        EquipTitleRequest  body  dto.EquipTitleRequest  true  "칭호 장착 요청"
// @Success      200  {object}  Response  "칭호 장착/해제 성공"
// @Failure      400  {object}  Response  "잘못된 요청 형식 또는 보유하지 않은 칭호"
// @Failure      401  {object}  Response  "인증 토큰 누락 또는 유효하지 않음"
// @Failure      500  {object}  Response  "서버 내부 에러"
// @Router       /api/collections/titles/equip [patch]
func (h *CollectionHandler) EquipTitle(c *gin.Context) {
	userID := c.MustGet("userID").(int64)

	var req dto.EquipTitleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "INVALID_REQUEST", "잘못된 요청 형식입니다.")
		return
	}

	// title_id string -> *int64 변환
	var titleID *int64
	if req.TitleID != nil {
		id, err := strconv.ParseInt(*req.TitleID, 10, 64)
		if err != nil {
			BadRequest(c, "INVALID_PARAMETER", "올바른 칭호 ID를 입력해주세요.")
			return
		}
		titleID = &id
	}

	if err := h.titleUsecase.EquipTitle(userID, titleID); err != nil {
		if errors.Is(err, usecase.ErrTitleNotOwned) {
			BadRequest(c, "TITLE_NOT_OWNED", err.Error())
			return
		}
		InternalError(c, "칭호 장착에 실패했습니다.")
		return
	}

	Success(c, gin.H{"message": "칭호가 변경되었습니다."})
}

// GetRewards 보상 아이템 목록 조회
// @Summary      보상 아이템 목록 조회
// @Description  전체 보상 아이템 목록과 획득 여부를 반환합니다.
// @Tags         collections
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  Response  "보상 목록 조회 성공"
// @Failure      401  {object}  Response  "인증 토큰 누락 또는 유효하지 않음"
// @Failure      500  {object}  Response  "서버 내부 에러"
// @Router       /api/collections/rewards [get]
func (h *CollectionHandler) GetRewards(c *gin.Context) {
	userID := c.MustGet("userID").(int64)

	rewards, acquiredMap, err := h.rewardUsecase.GetRewards(userID)
	if err != nil {
		InternalError(c, "보상 목록을 조회하는 중에 오류가 발생했습니다.")
		return
	}

	responses := make([]dto.RewardResponse, len(rewards))
	for i, reward := range rewards {
		ur, acquired := acquiredMap[reward.ID]
		resp := dto.RewardResponse{
			ID:          reward.ID,
			RewardType:  reward.RewardType,
			Name:        reward.Name,
			Description: reward.Description,
			AssetURL:    reward.AssetURL,
			Acquired:    acquired,
		}
		if acquired && ur != nil {
			resp.AchievedAt = &ur.AchievedAt
		}
		responses[i] = resp
	}

	Success(c, responses)
}

// parsePagination 쿼리 파라미터에서 page, limit 파싱
func parsePagination(c *gin.Context) (page, limit int) {
	page = 1
	limit = 20

	if p, err := strconv.Atoi(c.Query("page")); err == nil && p > 0 {
		page = p
	}
	if l, err := strconv.Atoi(c.Query("limit")); err == nil && l > 0 && l <= 100 {
		limit = l
	}
	return
}
