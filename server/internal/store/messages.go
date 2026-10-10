package store

import (
	"sort"
	"strings"
	"time"

	"github.com/gokr/ratatosk/server/internal/ids"
)

// maxPageSize caps every message page, whatever the client asks for.
const maxPageSize = 200

// AppendMessage stores a message and advances the conversation's seq.
//
// The caller fills in everything except ID and Seq, which are assigned here so
// that seq stays gapless and strictly increasing per conversation: the message
// list is append-only and never compacts, so index i is always seq i+1.
func (s *Store) AppendMessage(m *Message, now time.Time) (*Message, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	c, ok := s.db.Conversations[m.ConversationID]
	if !ok {
		return nil, ErrNotFound
	}
	if m.Kind == "" {
		m.Kind = MessageText
	}
	if m.Kind == MessageSystem {
		// System notes are authored by the server, so they have no sender to
		// check for membership — but they must not be forged either: only the
		// empty sender is accepted here.
		if m.SenderID != "" {
			return nil, ErrInvalidMessage
		}
	} else if _, ok := c.Members[m.SenderID]; !ok {
		return nil, ErrNotMember
	}
	// A text message with no plaintext is only valid when it carries sealed
	// content: the server cannot see the body, so it cannot check that the body
	// is non-empty. It still refuses a message that has neither.
	if m.Kind == MessageText && strings.TrimSpace(m.Text) == "" && len(m.Attachments) == 0 && len(m.Ciphertext) == 0 {
		return nil, ErrInvalidMessage
	}
	if len(m.Ciphertext) > 0 && (len(m.Nonce) == 0 || m.CryptoVersion == "") {
		return nil, ErrInvalidMessage
	}
	out := cloneMessage(m)
	out.ID = ids.New("m")
	out.Seq = c.LastSeq + 1
	if out.CreatedAt.IsZero() {
		out.CreatedAt = now
	}
	s.db.Messages[out.ID] = out
	s.db.ConvMessages[c.ID] = append(s.db.ConvMessages[c.ID], out.ID)
	if out.ClientMessageID != "" {
		s.clientIndex[clientKey(c.ID, out.SenderID, out.ClientMessageID)] = out.ID
	}
	c.LastSeq = out.Seq
	c.LastMessageID = out.ID
	c.UpdatedAt = out.CreatedAt
	s.markDirty()
	return cloneMessage(out), nil
}

// clientKey identifies an idempotency key. Retries of the same send arrive
// with an identical triple, so a repeat returns the stored message.
func clientKey(convID, senderID, clientMessageID string) string {
	return convID + "\x00" + senderID + "\x00" + clientMessageID
}

// FindMessageByClientID resolves a sender's idempotency key to a message.
func (s *Store) FindMessageByClientID(convID, senderID, clientMessageID string) (*Message, error) {
	if clientMessageID == "" {
		return nil, ErrNotFound
	}
	s.mu.RLock()
	defer s.mu.RUnlock()
	id, ok := s.clientIndex[clientKey(convID, senderID, clientMessageID)]
	if !ok {
		return nil, ErrNotFound
	}
	m, ok := s.db.Messages[id]
	if !ok {
		return nil, ErrNotFound
	}
	return cloneMessage(m), nil
}

// MessagesOf returns a page of a conversation's messages in ascending seq
// order.
//
//	beforeSeq > 0: the limit messages immediately before that seq (scroll up)
//	afterSeq  > 0: the limit messages immediately after that seq (catch up)
//	both zero:     the newest limit messages
//
// hasMore reports whether older messages exist before the first returned one.
func (s *Store) MessagesOf(convID string, beforeSeq, afterSeq int64, limit int) ([]*Message, bool, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if _, ok := s.db.Conversations[convID]; !ok {
		return nil, false, ErrNotFound
	}
	if limit <= 0 {
		limit = 50
	}
	if limit > maxPageSize {
		limit = maxPageSize
	}
	idsInOrder := s.db.ConvMessages[convID]
	n := int64(len(idsInOrder))
	var start, end int64
	switch {
	case afterSeq > 0:
		start = afterSeq // seq afterSeq sits at index afterSeq-1
		if start > n {
			start = n
		}
		end = min(n, start+int64(limit))
	case beforeSeq > 0:
		end = beforeSeq - 1
		if end > n {
			end = n
		}
		if end < 0 {
			end = 0
		}
		start = max(0, end-int64(limit))
	default:
		end = n
		start = max(0, end-int64(limit))
	}
	out := make([]*Message, 0, end-start)
	for i := start; i < end; i++ {
		if m, ok := s.db.Messages[idsInOrder[i]]; ok {
			out = append(out, cloneMessage(m))
		}
	}
	return out, start > 0, nil
}

// MessageByID returns a copy of one message.
func (s *Store) MessageByID(id string) (*Message, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	m, ok := s.db.Messages[id]
	if !ok {
		return nil, ErrNotFound
	}
	return cloneMessage(m), nil
}

// UpdateMessage applies fn to the stored message under the write lock and
// returns a copy of the result. fn must not call other store methods.
func (s *Store) UpdateMessage(id string, fn func(*Message)) (*Message, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	m, ok := s.db.Messages[id]
	if !ok {
		return nil, ErrNotFound
	}
	fn(m)
	s.markDirty()
	return cloneMessage(m), nil
}

// UnreadCount counts messages in a conversation that userID has not read,
// ignoring their own messages and system notes. recentWindow bounds the scan
// so a very long conversation cannot stall the caller.
func (s *Store) UnreadCount(convID, userID string, recentWindow int) int {
	s.mu.RLock()
	defer s.mu.RUnlock()
	c, ok := s.db.Conversations[convID]
	if !ok {
		return 0
	}
	member, ok := c.Members[userID]
	if !ok {
		return 0
	}
	idsInOrder := s.db.ConvMessages[convID]
	start := int64(member.LastReadSeq)
	if recentWindow > 0 && int64(len(idsInOrder))-start > int64(recentWindow) {
		start = int64(len(idsInOrder)) - int64(recentWindow)
	}
	count := 0
	for i := start; i < int64(len(idsInOrder)); i++ {
		m, ok := s.db.Messages[idsInOrder[i]]
		if !ok || m.SenderID == userID || m.Kind == MessageSystem {
			continue
		}
		count++
	}
	return count
}

// SearchMessages scans the given conversations for messages whose text
// contains query (case-insensitive), newest first. An empty query returns the
// newest messages. Deleted messages are skipped.
func (s *Store) SearchMessages(convIDs []string, query string, limit int) []*Message {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if limit <= 0 {
		limit = 30
	}
	q := strings.ToLower(strings.TrimSpace(query))
	var out []*Message
	for _, convID := range convIDs {
		for _, id := range s.db.ConvMessages[convID] {
			m, ok := s.db.Messages[id]
			if !ok || m.Deleted || m.Kind == MessageSystem {
				continue
			}
			if q != "" && !strings.Contains(strings.ToLower(m.Text), q) {
				continue
			}
			out = append(out, cloneMessage(m))
		}
	}
	sort.Slice(out, func(i, j int) bool {
		if !out[i].CreatedAt.Equal(out[j].CreatedAt) {
			return out[i].CreatedAt.After(out[j].CreatedAt)
		}
		return out[i].Seq > out[j].Seq
	})
	if len(out) > limit {
		out = out[:limit]
	}
	return out
}
