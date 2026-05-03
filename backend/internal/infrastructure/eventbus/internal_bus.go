package eventbus

import (
	"sync"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
)

type internalBus struct {
	handlers map[domain.EventType][]func(domain.Event)
	mu       sync.RWMutex
}

func NewInternalBus() domain.EventBus {
	return &internalBus{
		handlers: make(map[domain.EventType][]func(domain.Event)),
	}
}

func (b *internalBus) Publish(event domain.Event) {
	b.mu.RLock()
	handlers := b.handlers[event.Type]
	b.mu.RUnlock()

	for _, handler := range handlers {
		handler(event)
	}
}

func (b *internalBus) Subscribe(eventType domain.EventType, handler func(domain.Event)) {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.handlers[eventType] = append(b.handlers[eventType], handler)
}
