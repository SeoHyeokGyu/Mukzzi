package domain

import (
	"database/sql"
	"time"
)

// BaseDomain 모든 도메인 엔티티의 기본 필드
type BaseDomain struct {
	ID        int64        `gorm:"primaryKey;autoIncrement:false;type:bigint"`
	CreatedAt time.Time    `gorm:"autoCreateTime;not null"`
	UpdatedAt time.Time    `gorm:"autoUpdateTime;not null"`
	DeletedAt sql.NullTime `gorm:"index"`
}
