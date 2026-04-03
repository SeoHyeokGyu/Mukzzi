package domain

// User 는 사용자 도메인 엔티티를 정의합니다.
// 도메인 엔티티는 API 전송용 태그(json)보다는 비즈니스 및 DB(gorm) 표현에 집중합니다.
type User struct {
	BaseDomain
	Username string `gorm:"uniqueIndex;not null;type:varchar(50)" json:"username"`
	Email    string `gorm:"uniqueIndex;not null;type:varchar(100)" json:"email"`
	Password string `gorm:"not null;type:varchar(255)" json:"-"` // 비밀번호는 어떤 경우에도 JSON 노출 금지
	Nickname string `gorm:"type:varchar(50)" json:"nickname"`
}

// TableName 은 User 엔티티의 테이블 이름을 지정합니다.
func (User) TableName() string {
	return "users"
}
