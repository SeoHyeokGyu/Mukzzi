package domain

// Favorite 메뉴 즐겨찾기
type Favorite struct {
	BaseDomain
	UserID int64 `gorm:"not null;uniqueIndex:idx_favorites_user_menu"`
	MenuID int64 `gorm:"not null;uniqueIndex:idx_favorites_user_menu"`
	Menu   Menu  `gorm:"foreignKey:MenuID"`
}

func (Favorite) TableName() string { return "favorites" }

// GetFavoritesQuery 즐겨찾기 목록 조회 쿼리
type GetFavoritesQuery struct {
	UserID int64
	Cursor *int64
	Limit  int
}

// GetFavoritesResult 즐겨찾기 목록 조회 결과
type GetFavoritesResult struct {
	Favorites  []Favorite
	NextCursor *string
	HasNext    bool
	Limit      int
}
