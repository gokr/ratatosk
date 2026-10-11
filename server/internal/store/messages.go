package store

import (
	"database/sql"
	"github.com/gokr/ratatosk/server/internal/ids"
	"sort"
	"strings"
	"time"
)

const maxPageSize = 200

func clientKey(convID, senderID, clientID string) string {
	return convID + "\x00" + senderID + "\x00" + clientID
}
func (s *Store) saveMessage(q querier, m *Message) error {
	var client any
	if m.ClientMessageID != "" {
		client = s.digest("client-message", m.ClientMessageID)
	}
	return s.put(q, "messages", m.ID, m, []string{"conversation", "sender", "client", "seq"}, s.rowID("conversations", m.ConversationID), s.rowID("users", m.SenderID), client, m.Seq)
}
func (s *Store) findClient(q querier, convID, senderID, clientID string) (*Message, error) {
	if clientID == "" {
		return nil, ErrNotFound
	}
	all, e := listRows[Message](s, q, "messages", "WHERE conversation=? AND sender=? AND client=?", s.rowID("conversations", convID), s.rowID("users", senderID), s.digest("client-message", clientID))
	if e != nil {
		return nil, e
	}
	if len(all) == 0 {
		return nil, ErrNotFound
	}
	return all[0], nil
}
func (s *Store) FindMessageByClientID(convID, senderID, clientID string) (*Message, error) {
	return s.findClient(s.sql, convID, senderID, clientID)
}

// AppendMessage atomically checks membership and idempotency, assigns a gapless
// sequence, inserts the encrypted row and advances the conversation counter.
func (s *Store) AppendMessage(m *Message, now time.Time) (out *Message, err error) {
	err = s.write(func(tx *sql.Tx) error {
		c, e := getRow[Conversation](s, tx, "conversations", m.ConversationID)
		if e != nil {
			return e
		}
		v := cloneMessage(m)
		if v.Kind == "" {
			v.Kind = MessageText
		}
		if v.Kind == MessageSystem {
			if v.SenderID != "" {
				return ErrInvalidMessage
			}
		} else {
			if _, ok := c.Members[v.SenderID]; !ok {
				return ErrNotMember
			}
		}
		if v.ClientMessageID != "" {
			existing, e := s.findClient(tx, v.ConversationID, v.SenderID, v.ClientMessageID)
			if e == nil {
				out = existing
				return nil
			}
			if e != ErrNotFound {
				return e
			}
		}
		if v.Kind == MessageText && strings.TrimSpace(v.Text) == "" && len(v.Attachments) == 0 && len(v.Ciphertext) == 0 {
			return ErrInvalidMessage
		}
		if len(v.Ciphertext) > 0 && (len(v.Nonce) == 0 || v.CryptoVersion == "") {
			return ErrInvalidMessage
		}
		v.ID = ids.New("m")
		v.Seq = c.LastSeq + 1
		if v.CreatedAt.IsZero() {
			v.CreatedAt = now
		}
		if e = s.saveMessage(tx, v); e != nil {
			return e
		}
		c.LastSeq = v.Seq
		c.LastMessageID = v.ID
		c.UpdatedAt = v.CreatedAt
		// Membership is unchanged, so only the conversation row needs updating.
		if e = s.put(tx, "conversations", c.ID, c, nil); e != nil {
			return e
		}
		out = v
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}
func (s *Store) MessageByID(id string) (*Message, error) {
	return getRow[Message](s, s.sql, "messages", id)
}
func (s *Store) UpdateMessage(id string, fn func(*Message)) (out *Message, err error) {
	err = s.write(func(tx *sql.Tx) error {
		v, e := getRow[Message](s, tx, "messages", id)
		if e != nil {
			return e
		}
		conv, sender, client, seq := v.ConversationID, v.SenderID, v.ClientMessageID, v.Seq
		fn(v)
		v.ID = id
		v.ConversationID = conv
		v.SenderID = sender
		v.ClientMessageID = client
		v.Seq = seq
		out = v
		return s.saveMessage(tx, v)
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}
func (s *Store) MessagesOf(convID string, beforeSeq, afterSeq int64, limit int) ([]*Message, bool, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	tx, e := s.sql.Begin()
	if e != nil {
		return nil, false, e
	}
	defer tx.Rollback()
	c, e := getRow[Conversation](s, tx, "conversations", convID)
	if e != nil {
		return nil, false, e
	}
	if limit <= 0 {
		limit = 50
	}
	if limit > maxPageSize {
		limit = maxPageSize
	}
	where := "WHERE conversation=?"
	args := []any{s.rowID("conversations", convID)}
	desc := true
	if afterSeq > 0 {
		where += " AND seq>?"
		args = append(args, afterSeq)
		desc = false
	} else if beforeSeq > 0 {
		where += " AND seq<?"
		args = append(args, beforeSeq)
	}
	if desc {
		where += " ORDER BY seq DESC"
	} else {
		where += " ORDER BY seq ASC"
	}
	where += " LIMIT ?"
	args = append(args, limit)
	out, e := listRows[Message](s, tx, "messages", where, args...)
	if e != nil {
		return nil, false, e
	}
	if desc {
		for i, j := 0, len(out)-1; i < j; i, j = i+1, j-1 {
			out[i], out[j] = out[j], out[i]
		}
	}
	more := false
	if len(out) > 0 {
		more = out[0].Seq > 1
	} else if afterSeq > 0 {
		more = c.LastSeq > 0 && min(afterSeq, c.LastSeq) > 0
	} else if beforeSeq > 0 {
		more = false
	}
	return out, more, nil
}
func (s *Store) UnreadCount(convID, userID string, recentWindow int) int {
	s.mu.RLock()
	defer s.mu.RUnlock()
	tx, e := s.sql.Begin()
	must(e)
	defer tx.Rollback()
	c, e := getRow[Conversation](s, tx, "conversations", convID)
	if e == ErrNotFound {
		return 0
	}
	must(e)
	member, ok := c.Members[userID]
	if !ok {
		return 0
	}
	start := member.LastReadSeq
	if recentWindow > 0 {
		start = max(start, c.LastSeq-int64(recentWindow))
	}
	all, e := listRows[Message](s, tx, "messages", "WHERE conversation=? AND seq>? AND sender<>?", s.rowID("conversations", convID), start, s.rowID("users", userID))
	must(e)
	count := 0
	for _, m := range all {
		if m.Kind != MessageSystem {
			count++
		}
	}
	return count
}

// Text search decrypts only authorized conversation rows: no plaintext search
// index is persisted. Equality and sequence pagination use SQL indexes.
func (s *Store) SearchMessages(convIDs []string, query string, limit int) []*Message {
	if limit <= 0 {
		limit = 30
	}
	q := strings.ToLower(strings.TrimSpace(query))
	out := make([]*Message, 0)
	for _, conv := range convIDs {
		all, e := listRows[Message](s, s.sql, "messages", "WHERE conversation=?", s.rowID("conversations", conv))
		must(e)
		for _, m := range all {
			if !m.Deleted && m.Kind != MessageSystem && (q == "" || strings.Contains(strings.ToLower(m.Text), q)) {
				out = append(out, m)
			}
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
