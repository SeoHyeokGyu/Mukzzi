package domain

type FriendshipStatus string

const (
	FriendshipPending  FriendshipStatus = "PENDING"
	FriendshipAccepted FriendshipStatus = "ACCEPTED"
)

// Friendship 은 유저 간의 친구 관계 및 요청 상태를 관리합니다.
type Friendship struct {
	BaseDomain
	RequesterID     int64            `gorm:"index:idx_friendship,unique;not null" json:"requester_id,string"`
	ReceiverID      int64            `gorm:"index:idx_friendship,unique;not null" json:"receiver_id,string"`
	Status          FriendshipStatus `gorm:"type:varchar(20);default:'PENDING'" json:"status"`
	FriendshipScore int              `gorm:"default:0" json:"friendship_score"`

	// 연관 관계
	Requester *User `gorm:"foreignKey:RequesterID" json:"requester,omitempty"`
	Receiver  *User `gorm:"foreignKey:ReceiverID" json:"receiver,omitempty"`
}

// Block 은 유저 간의 차단 상태를 관리합니다.
type Block struct {
	BaseDomain
	BlockerID int64 `gorm:"index:idx_block,unique;not null" json:"blocker_id,string"`
	BlockedID int64 `gorm:"index:idx_block,unique;not null" json:"blocked_id,string"`

	// 연관 관계
	Blocker *User `gorm:"foreignKey:BlockerID" json:"blocker,omitempty"`
	Blocked *User `gorm:"foreignKey:BlockedID" json:"blocked,omitempty"`
}

// Guestbook 은 유저 프로필의 방명록 항목입니다.
type Guestbook struct {
	BaseDomain
	TargetUserID int64  `gorm:"index;not null" json:"target_user_id,string"`
	WriterID     int64  `gorm:"not null" json:"writer_id,string"`
	Content      string `gorm:"type:text;not null" json:"content"`
	IsSecret     bool   `gorm:"default:false" json:"is_secret"`

	// 연관 관계
	Writer *User `gorm:"foreignKey:WriterID" json:"writer,omitempty"`
}

// Nudge 는 오늘 보낸 응원 기록입니다 (1일 1회 제한용).
type Nudge struct {
	BaseDomain
	SenderID   int64 `gorm:"index:idx_nudge;not null" json:"sender_id,string"`
	ReceiverID int64 `gorm:"index:idx_nudge;not null" json:"receiver_id,string"`
	// Nudge 는 별도 테이블보다는 Redis 캐시로 관리하는 것이 효율적일 수 있으나,
	// 일단 ERD 설계에 맞춰 도메인 정의만 해둡니다.
}

type ReportReason string

const (
	ReportInappropriateNickname ReportReason = "INAPPROPRIATE_NICKNAME"
	ReportSpam                  ReportReason = "SPAM"
	ReportHarassment            ReportReason = "HARASSMENT"
	ReportOther                 ReportReason = "OTHER"
)

type ReportStatus string

const (
	ReportPending  ReportStatus = "PENDING"
	ReportReviewed ReportStatus = "REVIEWED"
	ReportResolved ReportStatus = "RESOLVED"
)

// Report 는 유저 신고 기록입니다.
type Report struct {
	BaseDomain
	ReporterID   int64        `gorm:"not null" json:"reporter_id,string"`
	TargetUserID int64        `gorm:"not null" json:"target_user_id,string"`
	Reason       ReportReason `gorm:"type:varchar(50);not null" json:"reason"`
	Detail       string       `gorm:"type:text" json:"detail"`
	Status       ReportStatus `gorm:"type:varchar(20);default:'PENDING'" json:"status"`
}

func (Friendship) TableName() string { return "friendships" }
func (Block) TableName() string      { return "blocks" }
func (Guestbook) TableName() string  { return "guestbooks" }
func (Nudge) TableName() string      { return "nudges" }
func (Report) TableName() string     { return "reports" }

type InteractionType string

const (
	InteractionFeed  InteractionType = "FEED"
	InteractionNudge InteractionType = "NUDGE"
)

type CharacterVisit struct {
	BaseDomain
	VisitorID       int64           `gorm:"index:idx_visitor_host_date;not null;index" json:"visitor_id,string"`
	HostID          int64           `gorm:"index:idx_visitor_host_date;not null;index" json:"host_id,string"`
	InteractionType InteractionType `gorm:"type:varchar(20);not null" json:"interaction_type"`
}

func (CharacterVisit) TableName() string { return "character_visits" }
