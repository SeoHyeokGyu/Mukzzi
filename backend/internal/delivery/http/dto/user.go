package dto

import (
	"os"
	"strconv"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"gorm.io/datatypes"
)

// UserResponse 는 공통 사용자 응답 데이터를 정의합니다.
type UserResponse struct {
	ID                   string         `json:"id"`
	Username             string         `json:"username"`
	Email                string         `json:"email"`
	Nickname             string         `json:"nickname"`
	ProfileImageURL      string         `json:"profile_image_url"`
	EquippedTitle        any            `json:"equipped_title,omitempty"`
	NotificationSettings datatypes.JSON `json:"notification_settings"`
	PrivacyLevel         string         `json:"privacy_level"`
	Body                 any            `json:"body"`
	IsAdmin              bool           `json:"is_admin"`
}

func ToUserResponse(u *domain.User) UserResponse {
	resp := UserResponse{
		ID:                   strconv.FormatInt(u.ID, 10),
		Username:             u.Username,
		Email:                u.Email,
		Nickname:             u.Nickname,
		ProfileImageURL:      u.ProfileImageURL,
		NotificationSettings: u.NotificationSettings,
		PrivacyLevel:         string(u.PrivacyLevel),
		Body:                 u.Body,
		IsAdmin:              strconv.FormatInt(u.ID, 10) == os.Getenv("ADMIN_USER_ID"),
	}
	if u.EquippedTitle != nil {
		resp.EquippedTitle = u.EquippedTitle
	}
	return resp
}

// UserUpdateRequest 는 사용자 프로필 수정 요청 데이터를 정의합니다.
type UserUpdateRequest struct {
	Nickname        string `json:"nickname" binding:"omitempty"`
	ProfileImageURL string `json:"profile_image_url" binding:"omitempty"`
}

// UserBodyUpdateRequest 는 신체 정보 수정 요청 데이터를 정의합니다.
type UserBodyUpdateRequest struct {
	Height        float64              `json:"height" binding:"required,gt=0"`
	Weight        float64              `json:"weight" binding:"required,gt=0"`
	ActivityLevel domain.ActivityLevel `json:"activity_level" binding:"required,oneof=LOW MODERATE HIGH VERY_HIGH"`
}

// UserNutritionGoalUpdateRequest 는 영양 목표 재설정 요청 데이터를 정의합니다.
type UserNutritionGoalUpdateRequest struct {
	Goal DietGoalRequest `json:"goal" binding:"required,oneof=DIET MAINTAIN BULK"`
}

type DietGoalRequest string

const (
	DietGoalDiet     DietGoalRequest = "DIET"
	DietGoalMaintain DietGoalRequest = "MAINTAIN"
	DietGoalBulk     DietGoalRequest = "BULK"
)

// UserSettingsUpdateRequest 는 설정 변경 요청 데이터를 정의합니다.
type UserSettingsUpdateRequest struct {
	PrivacyLevel         *domain.PrivacyLevel `json:"privacy_level" binding:"omitempty,oneof=PUBLIC FRIENDS PRIVATE"`
	NotificationSettings datatypes.JSON       `json:"notification_settings" binding:"omitempty"`
}

// UserSearchRequest 는 사용자 검색 요청 데이터를 정의합니다.
type UserSearchRequest struct {
	Query string `form:"query" binding:"required"`
}

// UserProfileResponse 는 타인 프로필 정보 응답 데이터를 정의합니다.
type UserProfileResponse struct {
	ID              int64               `json:"id,string"`
	Nickname        string              `json:"nickname"`
	ProfileImageURL string              `json:"profile_image_url"`
	EquippedTitle   string              `json:"equipped_title,omitempty"`
	PrivacyLevel    domain.PrivacyLevel `json:"privacy_level"`
}

// OnboardingRequest 는 온보딩 요청 데이터를 정의합니다.
type OnboardingRequest struct {
	MukzziName    string               `json:"mukzzi_name" binding:"required,min=1,max=20"`
	Height        float64              `json:"height" binding:"required,gt=0"`
	Weight        float64              `json:"weight" binding:"required,gt=0"`
	ActivityLevel domain.ActivityLevel `json:"activity_level" binding:"required,oneof=LOW MODERATE HIGH VERY_HIGH"`
	Goal          DietGoalRequest      `json:"goal" binding:"required,oneof=DIET MAINTAIN BULK"`
	BodyType      int                  `json:"body_type" binding:"min=0"`
	Muscle        int                  `json:"muscle" binding:"min=0"`
	SkinTone      int                  `json:"skin_tone" binding:"min=0"`
	Expression    int                  `json:"expression" binding:"min=0"`
}
