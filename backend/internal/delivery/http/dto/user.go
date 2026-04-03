package dto

// UserUpdateRequest 는 사용자 프로필 수정 요청 데이터를 정의합니다.
type UserUpdateRequest struct {
	Email    string `json:"email" binding:"email"`
	Nickname string `json:"nickname"`
	Password string `json:"password" binding:"omitempty,min=6"`
}
