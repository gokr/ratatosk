package store

import (
	"database/sql"
	"github.com/gokr/ratatosk/server/internal/ids"
	"sort"
	"time"
)

func (s *Store) saveConversation(q querier, c *Conversation) error {
	if e := s.put(q, "conversations", c.ID, c, nil); e != nil {
		return e
	}
	if _, e := q.Exec("DELETE FROM memberships WHERE conversation=?", s.rowID("conversations", c.ID)); e != nil {
		return e
	}
	for id := range c.Members {
		if _, e := q.Exec("INSERT INTO memberships(conversation,owner) VALUES(?,?)", s.rowID("conversations", c.ID), s.rowID("users", id)); e != nil {
			return e
		}
	}
	return nil
}
func (s *Store) CreateConversation(kind, title, creatorID string, memberIDs []string, now time.Time) (out *Conversation, err error) {
	err = s.write(func(tx *sql.Tx) error {
		if _, e := getRow[User](s, tx, "users", creatorID); e != nil {
			if e == ErrNotFound {
				return ErrUnknownUser
			}
			return e
		}
		out = &Conversation{ID: ids.New("c"), Kind: kind, Title: title, CreatedBy: creatorID, CreatedAt: now, UpdatedAt: now, Members: map[string]*Member{creatorID: {UserID: creatorID, Role: RoleOwner, JoinedAt: now}}}
		for _, id := range memberIDs {
			if _, ok := out.Members[id]; ok {
				continue
			}
			if _, e := getRow[User](s, tx, "users", id); e != nil {
				if e == ErrNotFound {
					continue
				}
				return e
			}
			out.Members[id] = &Member{UserID: id, Role: RoleMember, JoinedAt: now}
		}
		return s.saveConversation(tx, out)
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}
func (s *Store) ConversationByID(id string) (*Conversation, error) {
	return getRow[Conversation](s, s.sql, "conversations", id)
}
func (s *Store) ConversationsOf(userID string) []*Conversation {
	out, e := listRows[Conversation](s, s.sql, "conversations", "WHERE id IN (SELECT conversation FROM memberships WHERE owner=?)", s.rowID("users", userID))
	must(e)
	sort.Slice(out, func(i, j int) bool { return out[i].UpdatedAt.After(out[j].UpdatedAt) })
	return out
}
func (s *Store) FindDirectConversation(a, b string) (*Conversation, error) {
	all, e := listRows[Conversation](s, s.sql, "conversations", "WHERE id IN (SELECT conversation FROM memberships WHERE owner=?) AND id IN (SELECT conversation FROM memberships WHERE owner=?)", s.rowID("users", a), s.rowID("users", b))
	if e != nil {
		return nil, e
	}
	for _, c := range all {
		if c.Kind == KindDirect && len(c.Members) == 2 {
			return c, nil
		}
	}
	return nil, ErrNotFound
}
func (s *Store) UpdateConversation(id string, fn func(*Conversation)) (out *Conversation, err error) {
	err = s.write(func(tx *sql.Tx) error {
		c, e := getRow[Conversation](s, tx, "conversations", id)
		if e != nil {
			return e
		}
		seq, last := c.LastSeq, c.LastMessageID
		fn(c)
		c.ID = id
		c.LastSeq = seq
		c.LastMessageID = last
		if c.Members == nil {
			c.Members = map[string]*Member{}
		}
		out = c
		return s.saveConversation(tx, c)
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}
func (s *Store) LastMessage(convID string) (out *Message, err error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	tx, e := s.sql.Begin()
	if e != nil {
		return nil, e
	}
	defer tx.Rollback()
	c, e := getRow[Conversation](s, tx, "conversations", convID)
	if e != nil {
		return nil, e
	}
	if c.LastMessageID == "" {
		return nil, ErrNotFound
	}
	return getRow[Message](s, tx, "messages", c.LastMessageID)
}
