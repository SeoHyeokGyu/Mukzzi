package domain

import "time"

type EventType string

const (
	EventMealCreated       EventType = "MEAL_CREATED"
	EventFriendNudged      EventType = "FRIEND_NUDGED"
	EventGuestbookPosted   EventType = "GUESTBOOK_POSTED"
	EventUserOnboarded     EventType = "USER_ONBOARDED"
	EventBadgeAcquired     EventType = "BADGE_ACQUIRED"
	EventAppearanceChanged EventType = "APPEARANCE_CHANGED"
	EventQuestCompleted    EventType = "QUEST_COMPLETED"
)

type Event struct {
	Type      EventType
	UserID    int64
	Payload   map[string]interface{}
	CreatedAt time.Time
}

type EventBus interface {
	Publish(event Event)
	Subscribe(eventType EventType, handler func(Event))
}
