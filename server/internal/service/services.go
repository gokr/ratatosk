package service

import (
	"log/slog"

	"github.com/gokr/ratatosk/server/internal/realtime"
	"github.com/gokr/ratatosk/server/internal/store"
)

// Services bundles the three Connect service implementations. They share one
// base, so the typing tracker, presence visibility rule and hub are wired once.
type Services struct {
	Auth   *AuthService
	Chat   *ChatService
	Social *SocialService
	Keys   *KeyService
}

// New wires every service onto the same object graph.
func New(st *store.Store, hub *realtime.Hub, presence *realtime.Tracker, cfg Config, log *slog.Logger) *Services {
	b := NewBase(st, hub, presence, cfg, log)
	return &Services{
		Auth:   NewAuthService(b),
		Chat:   NewChatService(b),
		Social: NewSocialService(b),
		Keys:   NewKeyService(b),
	}
}

// Typing exposes the indicator tracker for callers outside this package.
func (s *Services) Typing() *realtime.Typing { return s.Chat.typing }
