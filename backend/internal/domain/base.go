package domain

import (
	"time"

	"github.com/sony/sonyflake"
	"gorm.io/gorm"
)

var sf *sonyflake.Sonyflake

func init() {
	var st sonyflake.Settings
	// MachineID가 nil일 경우 기본적으로 private IP를 사용하나,
	// 환경에 따라 실패할 수 있으므로 명시적으로 설정하거나 폴백을 제공합니다.
	st.MachineID = func() (uint16, error) {
		// TODO: 실제 운영 환경에서는 고유한 MachineID를 반환하도록 수정 (예: POD_ID, IP 등)
		return 1, nil
	}

	sf = sonyflake.NewSonyflake(st)
	if sf == nil {
		panic("sonyflake not created")
	}
}

// NextID generates a new unique ID using sonyflake.
func NextID() (uint64, error) {
	return sf.NextID()
}

// BaseDomain 은 모든 도메인 엔티티의 공통 필드를 정의합니다.
// ID는 sonyflake를 통해 생성된 64비트 정수(PostgreSQL BIGINT)를 사용합니다.
type BaseDomain struct {
	// 1. 기본 식별자: Sonyflake와의 호환성을 위해 int64 사용 (DB BIGINT 매핑)
	// json:",string" 태그를 추가하여 JS 등에서 정밀도 손실이 발생하지 않도록 합니다.
	ID int64 `gorm:"primaryKey;autoIncrement:false;type:bigint" json:"id,string"`

	// 2. 시간 추적: GORM 관례를 따르되 명시적 태그 추가
	CreatedAt time.Time `gorm:"autoCreateTime;not null"`
	UpdatedAt time.Time `gorm:"autoUpdateTime;not null"`

	// 3. 소프트 삭제 및 인덱스
	DeletedAt gorm.DeletedAt `gorm:"index"`
}

// BeforeCreate 는 엔티티 생성 전 ID가 없을 경우 sonyflake ID를 자동 할당합니다.
func (b *BaseDomain) BeforeCreate(tx *gorm.DB) (err error) {
	if b.ID == 0 {
		id, err := NextID()
		if err != nil {
			return err
		}
		b.ID = int64(id)
	}
	return nil
}
