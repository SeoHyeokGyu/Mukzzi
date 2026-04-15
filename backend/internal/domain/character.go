package domain

import "time"

type CharacterCollection struct {
	BaseDomain
	UserID     int64     `gorm:"not null;uniqueIndex:idx_char_collection"`
	BodyType   int       `gorm:"not null;uniqueIndex:idx_char_collection"`
	Muscle     int       `gorm:"not null;uniqueIndex:idx_char_collection"`
	SkinTone   int       `gorm:"not null;uniqueIndex:idx_char_collection"`
	Expression int       `gorm:"not null;uniqueIndex:idx_char_collection"`
	AchievedAt time.Time `gorm:"not null"`
}

func (CharacterCollection) TableName() string {
	return "character_collections"
}
