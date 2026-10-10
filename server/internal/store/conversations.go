package store

import (
	"sort"
	"time"

	"github.com/gokr/ratatosk/server/internal/ids"
)

// CreateConversation stores a new conversation whose creator is an owner.
// memberIDs must not include duplicates; the creator is added automatically.
func (s *Store) CreateConversation(kind, title, creatorID string, memberIDs []string, now time.Time) (*Conversation, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, ok := s.db.Users[creatorID]; !ok {
		return nil, ErrUnknownUser
	}
	c := &Conversation{
		ID:        ids.New("c"),
		Kind:      kind,
		Title:     title,
		CreatedBy: creatorID,
		CreatedAt: now,
		UpdatedAt: now,
		Members:   map[string]*Member{},
	}
	addMember := func(id, role string) {
		if _, exists := c.Members[id]; exists {
			return
		}
		if _, ok := s.db.Users[id]; !ok {
			return
		}
		c.Members[id] = &Member{UserID: id, Role: role, JoinedAt: now}
	}
	addMember(creatorID, RoleOwner)
	for _, id := range memberIDs {
		addMember(id, RoleMember)
	}
	s.db.Conversations[c.ID] = c
	s.db.ConvMessages[c.ID] = nil
	s.markDirty()
	return cloneConversation(c), nil
}

// ConversationByID returns a copy of a conversation.
func (s *Store) ConversationByID(id string) (*Conversation, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	c, ok := s.db.Conversations[id]
	if !ok {
		return nil, ErrNotFound
	}
	return cloneConversation(c), nil
}

// ConversationsOf returns the conversations a user is a member of, most
// recently active first.
func (s *Store) ConversationsOf(userID string) []*Conversation {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var out []*Conversation
	for _, c := range s.db.Conversations {
		if _, ok := c.Members[userID]; ok {
			out = append(out, cloneConversation(c))
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].UpdatedAt.After(out[j].UpdatedAt) })
	return out
}

// FindDirectConversation returns the 1:1 conversation between two users.
func (s *Store) FindDirectConversation(a, b string) (*Conversation, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	for _, c := range s.db.Conversations {
		if c.Kind != KindDirect || len(c.Members) != 2 {
			continue
		}
		if _, ok := c.Members[a]; !ok {
			continue
		}
		if _, ok := c.Members[b]; !ok {
			continue
		}
		return cloneConversation(c), nil
	}
	return nil, ErrNotFound
}

// UpdateConversation applies fn to the stored conversation under the write
// lock and returns a copy of the result. fn must not call other store methods.
func (s *Store) UpdateConversation(id string, fn func(*Conversation)) (*Conversation, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	c, ok := s.db.Conversations[id]
	if !ok {
		return nil, ErrNotFound
	}
	fn(c)
	s.markDirty()
	return cloneConversation(c), nil
}

// LastMessage returns the newest message of a conversation.
func (s *Store) LastMessage(convID string) (*Message, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	c, ok := s.db.Conversations[convID]
	if !ok {
		return nil, ErrNotFound
	}
	if c.LastMessageID == "" {
		return nil, ErrNotFound
	}
	m, ok := s.db.Messages[c.LastMessageID]
	if !ok {
		return nil, ErrNotFound
	}
	return cloneMessage(m), nil
}
