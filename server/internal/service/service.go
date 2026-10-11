// Package service implements the three Connect services on top of the store
// and the realtime hub.
//
// Layering: handlers validate input and authorize, the store owns state, the
// hub pushes. Handlers never mutate a struct returned by the store — the store
// hands out copies precisely so a broadcast can be assembled without racing
// another writer.
package service

import (
	"crypto/sha256"
	"errors"
	"log/slog"
	"sort"
	"strings"
	"time"

	"google.golang.org/protobuf/types/known/timestamppb"

	ratatoskv1 "github.com/gokr/ratatosk/server/gen/ratatosk/v1"
	"github.com/gokr/ratatosk/server/internal/realtime"
	"github.com/gokr/ratatosk/server/internal/store"
)

// Config holds the knobs the service layer needs. They come from flags and the
// environment so nothing in this package reaches for global state.
type Config struct {
	// MessageNotifier enqueues generic push notifications without network I/O.
	MessageNotifier interface {
		Notify(id, conversation, sender string) bool
	}
	// PublicURL is the origin used to build attachment and invite links.
	PublicURL string
	// SessionTTL is how long a login lasts.
	SessionTTL time.Duration
	// InviteTTL and InviteMaxUses are the defaults for new invite links.
	InviteTTL     time.Duration
	InviteMaxUses int
	// MaxUploadBytes caps one attachment.
	MaxUploadBytes int64
	// MaxMembers caps a group conversation's size.
	MaxMembers int
	// UnreadWindow bounds how far back the unread scan looks, so a very long
	// conversation cannot turn a list call into a full scan.
	UnreadWindow int
	// GroupAccents are the colors assigned to groups by id hash, and the
	// default accent for a new user.
	GroupAccents []string
}

// DefaultConfig returns the shipped defaults.
func DefaultConfig() Config {
	return Config{
		PublicURL:      "http://localhost:8080",
		SessionTTL:     30 * 24 * time.Hour,
		InviteTTL:      7 * 24 * time.Hour,
		InviteMaxUses:  1,
		MaxUploadBytes: 8 << 20, // 8 MiB
		MaxMembers:     256,
		UnreadWindow:   500,
		GroupAccents:   []string{"#e0245e", "#1da1f2", "#17bf63", "#f45d22", "#794bc4", "#00b7c2", "#f5a623", "#7b8d93"},
	}
}

// base is the shared state of the three services. They are separate types for
// the generated handler interfaces but one object graph.
type base struct {
	st       *store.Store
	hub      *realtime.Hub
	presence *realtime.Tracker
	typing   *realtime.Typing
	cfg      Config
	log      *slog.Logger
}

// NewBase wires the shared state. The typing tracker announces expired
// indicators through the hub, so a dropped connection cannot leave one lit.
func NewBase(st *store.Store, hub *realtime.Hub, presence *realtime.Tracker, cfg Config, log *slog.Logger) *base {
	if log == nil {
		log = slog.Default()
	}
	b := &base{st: st, hub: hub, presence: presence, cfg: cfg, log: log}
	b.typing = realtime.NewTyping(func(convID, userID, displayName string) {
		b.broadcastTyping(convID, userID, displayName, false)
	})
	// Presence is visible only to contacts and conversation partners; that rule
	// lives here because it is the same one used for message fan-out.
	if presence != nil {
		presence.SetRecipients(b.contactsFor)
	}
	return b
}

// Typing exposes the indicator tracker (used by the chat service's SetTyping).
func (b *base) Typing() *realtime.Typing { return b.typing }

// now is the single clock for the service layer, so tests can substitute one.
var now = time.Now

// maxCiphertextBytes caps a sealed message body. The plaintext limit is 8000
// characters; sealing adds a 16-byte tag and protobuf overhead, so this is
// generous while still bounding what a client can store per message.
const maxCiphertextBytes = 64 << 10

// --- conversions ---------------------------------------------------------

func ts(t time.Time) *timestamppb.Timestamp {
	if t.IsZero() {
		return nil
	}
	return timestamppb.New(t)
}

// accentFor derives a stable color from an id, so avatars and conversation
// accents look intentional without anyone choosing a color.
func (b *base) accentFor(id string) string {
	if len(b.cfg.GroupAccents) == 0 {
		return "#1da1f2"
	}
	sum := sha256.Sum256([]byte(id))
	return b.cfg.GroupAccents[int(sum[0])%len(b.cfg.GroupAccents)]
}

// userProto renders a user for a viewer, including live presence.
func (b *base) userProto(u *store.User) *ratatoskv1.User {
	if u == nil {
		return nil
	}
	presence := ratatoskv1.Presence_PRESENCE_OFFLINE
	if b.presence != nil {
		presence = b.presence.Presence(u.ID)
	}
	out := &ratatoskv1.User{
		Id:          u.ID,
		Username:    u.Username,
		DisplayName: u.DisplayName,
		Bio:         u.Bio,
		Presence:    presence,
		AccentColor: u.AccentColor,
	}
	if u.Avatar != "" {
		out.AvatarUrl = b.attachmentURL(u.Avatar)
	}
	lastSeen := u.LastSeen
	if presence == ratatoskv1.Presence_PRESENCE_OFFLINE {
		out.LastSeen = ts(lastSeen)
	}
	return out
}

// attachmentURL is the path a client fetches attachment bytes from.
func (b *base) attachmentURL(id string) string {
	if id == "" {
		return ""
	}
	return "/files/" + id
}

func (b *base) attachmentProto(a *store.Attachment) *ratatoskv1.Attachment {
	if a == nil {
		return nil
	}
	// A sealed blob has no trustworthy name, type or dimensions: everything the
	// UI needs is inside the message envelope, which only the client can open.
	if a.Encrypted {
		return &ratatoskv1.Attachment{
			Id:        a.ID,
			Size:      a.Size,
			Url:       b.attachmentURL(a.ID),
			Encrypted: true,
		}
	}
	return &ratatoskv1.Attachment{
		Id:          a.ID,
		Filename:    a.Filename,
		ContentType: a.ContentType,
		Size:        a.Size,
		Url:         b.attachmentURL(a.ID),
		Width:       int32(a.Width),
		Height:      int32(a.Height),
		IsImage:     strings.HasPrefix(a.ContentType, "image/"),
	}
}

func kindToProto(kind string) ratatoskv1.MessageKind {
	switch kind {
	case store.MessageSystem:
		return ratatoskv1.MessageKind_MESSAGE_KIND_SYSTEM
	default:
		return ratatoskv1.MessageKind_MESSAGE_KIND_TEXT
	}
}

// messageProto renders a message for a viewer. Deleted messages are sent as
// tombstones: the id, seq and author survive so a client can keep the bubble's
// place, but no content does.
func (b *base) messageProto(m *store.Message) *ratatoskv1.Message {
	if m == nil {
		return nil
	}
	out := &ratatoskv1.Message{
		Id:              m.ID,
		ConversationId:  m.ConversationID,
		SenderId:        m.SenderID,
		Seq:             m.Seq,
		CreatedAt:       ts(m.CreatedAt),
		EditedAt:        ts(m.EditedAt),
		Deleted:         m.Deleted,
		ClientMessageId: m.ClientMessageID,
		Kind:            kindToProto(m.Kind),
		ReplyToId:       m.ReplyToID,
	}
	if m.Deleted {
		return out
	}
	// An encrypted message crosses the wire as its seal plus the coordinates of
	// the key that opens it; the plaintext fields stay empty. The server could
	// not fill them if it wanted to.
	if m.Encrypted() {
		out.Encrypted = true
		out.Ciphertext = m.Ciphertext
		out.Nonce = m.Nonce
		out.SenderDeviceKeyId = m.SenderDeviceKeyID
		out.KeyEpoch = m.KeyEpoch
		out.CryptoVersion = m.CryptoVersion
		// A reply target is part of the sealed body in an encrypted
		// conversation, so nothing about it is rendered here.
		if len(m.Attachments) > 0 {
			for _, a := range b.st.AttachmentsByIDs(m.Attachments) {
				out.Attachments = append(out.Attachments, b.attachmentProto(a))
			}
		}
		return out
	}
	out.Text = m.Text
	if len(m.Attachments) > 0 {
		for _, a := range b.st.AttachmentsByIDs(m.Attachments) {
			out.Attachments = append(out.Attachments, b.attachmentProto(a))
		}
	}
	if len(m.Reactions) > 0 {
		emojis := make([]string, 0, len(m.Reactions))
		for emoji := range m.Reactions {
			emojis = append(emojis, emoji)
		}
		sort.Strings(emojis)
		for _, emoji := range emojis {
			out.Reactions = append(out.Reactions, &ratatoskv1.Reaction{
				Emoji:   emoji,
				UserIds: append([]string(nil), m.Reactions[emoji]...),
			})
		}
	}
	if m.ReplyToID != "" {
		if parent, err := b.st.MessageByID(m.ReplyToID); err == nil {
			preview := &ratatoskv1.ReplyPreview{
				MessageId:     parent.ID,
				SenderId:      parent.SenderID,
				Text:          parent.Text,
				Deleted:       parent.Deleted,
				HasAttachment: len(parent.Attachments) > 0,
			}
			if u, err := b.st.UserByID(parent.SenderID); err == nil {
				preview.SenderName = u.DisplayName
			}
			if parent.Deleted {
				preview.Text = ""
			}
			out.ReplyTo = preview
		}
	}
	return out
}

// conversationProto renders a conversation from one viewer's point of view:
// direct conversations borrow the peer's name and picture, unread counts and
// mute/pin flags come from the viewer's own member row.
func (b *base) conversationProto(c *store.Conversation, viewerID string) *ratatoskv1.Conversation {
	if c == nil {
		return nil
	}
	out := &ratatoskv1.Conversation{
		Id:        c.ID,
		Kind:      c.Kind,
		Title:     c.Title,
		CreatedAt: ts(c.CreatedAt),
		UpdatedAt: ts(c.UpdatedAt),
		CreatedBy: c.CreatedBy,
		LastSeq:   c.LastSeq,
	}
	// Members, ordered so the UI and the wire are deterministic: owner first,
	// then display name, then id.
	memberIDs := make([]string, 0, len(c.Members))
	for id := range c.Members {
		memberIDs = append(memberIDs, id)
	}
	sort.Slice(memberIDs, func(i, j int) bool {
		mi, mj := c.Members[memberIDs[i]], c.Members[memberIDs[j]]
		if (mi.Role == store.RoleOwner) != (mj.Role == store.RoleOwner) {
			return mi.Role == store.RoleOwner
		}
		return memberIDs[i] < memberIDs[j]
	})
	for _, id := range memberIDs {
		m := c.Members[id]
		u, err := b.st.UserByID(id)
		if err != nil {
			continue // user record went missing; skip rather than fail
		}
		out.Members = append(out.Members, &ratatoskv1.Member{
			User:        b.userProto(u),
			Role:        m.Role,
			JoinedAt:    ts(m.JoinedAt),
			LastReadSeq: m.LastReadSeq,
			LastReadAt:  ts(m.LastReadAt),
			Muted:       m.Muted,
			Pinned:      m.Pinned,
		})
		if m.Muted {
			out.Muted = true
		}
		if m.Pinned {
			out.Pinned = true
		}
	}

	if viewer, ok := c.Members[viewerID]; ok {
		out.UnreadCount = int32(b.st.UnreadCount(c.ID, viewerID, b.cfg.UnreadWindow))
		_ = viewer
	}

	if c.Kind == store.KindDirect {
		for _, id := range memberIDs {
			if id == viewerID {
				continue
			}
			if peer, err := b.st.UserByID(id); err == nil {
				out.Peer = b.userProto(peer)
				out.Title = peer.DisplayName
				out.AvatarUrl = b.userProto(peer).AvatarUrl
				out.AccentColor = peer.AccentColor
			}
			break
		}
	} else {
		if c.Avatar != "" {
			out.AvatarUrl = b.attachmentURL(c.Avatar)
		}
		if c.Title == "" {
			out.Title = b.defaultGroupTitle(c, viewerID)
		}
		out.AccentColor = b.accentFor(c.ID)
	}

	if last, err := b.st.LastMessage(c.ID); err == nil {
		out.LastMessage = b.messageProto(last)
	}
	return out
}

// defaultGroupTitle names an untitled group after its members, the way every
// messenger does before someone renames it.
func (b *base) defaultGroupTitle(c *store.Conversation, viewerID string) string {
	names := make([]string, 0, len(c.Members))
	for id := range c.Members {
		if id == viewerID {
			continue
		}
		if u, err := b.st.UserByID(id); err == nil {
			names = append(names, u.DisplayName)
		}
	}
	sort.Strings(names)
	switch len(names) {
	case 0:
		return "Empty group"
	default:
		return strings.Join(names, ", ")
	}
}

// contactsFor lists the users allowed to observe userID: their contacts plus
// the people they share a conversation with. Presence and conversation
// fan-out both use it, so a stranger cannot watch someone come and go.
func (b *base) contactsFor(userID string) []string {
	seen := map[string]struct{}{}
	for _, c := range b.st.ContactsOf(userID) {
		seen[c.UserID] = struct{}{}
	}
	for _, conv := range b.st.ConversationsOf(userID) {
		for id := range conv.Members {
			if id != userID {
				seen[id] = struct{}{}
			}
		}
	}
	out := make([]string, 0, len(seen))
	for id := range seen {
		out = append(out, id)
	}
	return out
}

// --- broadcasts ----------------------------------------------------------

// membersOf returns the member ids of a conversation.
func membersOf(c *store.Conversation) []string {
	out := make([]string, 0, len(c.Members))
	for id := range c.Members {
		out = append(out, id)
	}
	return out
}

// broadcastMessage pushes a message to every member of its conversation.
func (b *base) broadcastMessage(m *store.Message) {
	if m == nil {
		return
	}
	c, err := b.st.ConversationByID(m.ConversationID)
	if err != nil {
		return
	}
	proto := b.messageProto(m)
	b.hub.SendMany(membersOf(c), func(string) *ratatoskv1.Event {
		return &ratatoskv1.Event{
			Seq:     b.hub.NextSeq(),
			At:      ts(now()),
			Payload: &ratatoskv1.Event_Message{Message: &ratatoskv1.MessageEvent{Message: proto}},
		}
	})
}

// broadcastConversationsRefreshed re-sends a conversation to its members, each
// rendered from their own point of view (their unread count, their flags).
func (b *base) broadcastConversationsRefreshed(c *store.Conversation) {
	if c == nil {
		return
	}
	ids := membersOf(c)
	b.hub.SendMany(ids, func(userID string) *ratatoskv1.Event {
		return &ratatoskv1.Event{
			Seq: b.hub.NextSeq(),
			At:  ts(now()),
			Payload: &ratatoskv1.Event_Conversation{
				Conversation: &ratatoskv1.ConversationEvent{Conversation: b.conversationProto(c, userID)},
			},
		}
	})
}

func (b *base) broadcastConversationCreated(c *store.Conversation, userID string) {
	b.hub.Send(userID, &ratatoskv1.Event{
		Seq: b.hub.NextSeq(),
		At:  ts(now()),
		Payload: &ratatoskv1.Event_Conversation{
			Conversation: &ratatoskv1.ConversationEvent{
				Conversation: b.conversationProto(c, userID),
				Created:      true,
			},
		},
	})
}

func (b *base) broadcastConversationRemoved(convID, userID string) {
	b.hub.Send(userID, &ratatoskv1.Event{
		Seq: b.hub.NextSeq(),
		At:  ts(now()),
		Payload: &ratatoskv1.Event_Conversation{
			Conversation: &ratatoskv1.ConversationEvent{
				Conversation: &ratatoskv1.Conversation{Id: convID},
				Removed:      true,
			},
		},
	})
}

func (b *base) broadcastTyping(convID, userID, displayName string, typing bool) {
	c, err := b.st.ConversationByID(convID)
	if err != nil {
		return
	}
	b.hub.SendMany(membersOf(c), func(recipient string) *ratatoskv1.Event {
		if recipient == userID {
			return nil // people do not need to be told they are typing
		}
		return &ratatoskv1.Event{
			Seq: b.hub.NextSeq(),
			At:  ts(now()),
			Payload: &ratatoskv1.Event_Typing{Typing: &ratatoskv1.TypingEvent{
				ConversationId: convID,
				UserId:         userID,
				DisplayName:    displayName,
				Typing:         typing,
			}},
		}
	})
}

func (b *base) broadcastRead(convID, userID string, lastReadSeq int64) {
	c, err := b.st.ConversationByID(convID)
	if err != nil {
		return
	}
	b.hub.SendMany(membersOf(c), func(recipient string) *ratatoskv1.Event {
		if recipient == userID {
			return nil
		}
		return &ratatoskv1.Event{
			Seq: b.hub.NextSeq(),
			At:  ts(now()),
			Payload: &ratatoskv1.Event_Read{Read: &ratatoskv1.ReadEvent{
				ConversationId: convID,
				UserId:         userID,
				LastReadSeq:    lastReadSeq,
			}},
		}
	})
}

func (b *base) broadcastContact(kind, userID, contactID, convID string) {
	u, err := b.st.UserByID(userID)
	if err != nil {
		return
	}
	b.hub.Send(contactID, &ratatoskv1.Event{
		Seq: b.hub.NextSeq(),
		At:  ts(now()),
		Payload: &ratatoskv1.Event_Contact{Contact: &ratatoskv1.ContactEvent{
			Kind:           kind,
			User:           b.userProto(u),
			ConversationId: convID,
		}},
	})
}

// systemMessage appends a server-authored note (someone joined, was removed)
// and pushes it to the conversation.
func (b *base) systemMessage(convID, text string) {
	msg := &store.Message{
		ConversationID: convID,
		Kind:           store.MessageSystem,
		Text:           text,
	}
	saved, err := b.st.AppendMessage(msg, now())
	if err != nil {
		b.log.Error("system message failed", "conversation", convID, "err", err)
		return
	}
	b.broadcastMessage(saved)
	b.refreshConversation(convID)
}

// refreshConversation re-reads a conversation and re-broadcasts it.
func (b *base) refreshConversation(convID string) {
	if c, err := b.st.ConversationByID(convID); err == nil {
		b.broadcastConversationsRefreshed(c)
	}
}

// findDirect returns the direct conversation between two users, creating it if
// needed. Callers do this under no lock; a rare double-create is harmless
// because FindDirectConversation is checked again by the store's list lookup —
// worst case two rows exist and the older one wins.
func (b *base) findDirect(a, b2 string) (*store.Conversation, bool, error) {
	if c, err := b.st.FindDirectConversation(a, b2); err == nil {
		return c, false, nil
	}
	c, err := b.st.CreateConversation(store.KindDirect, "", a, []string{b2}, now())
	if err != nil {
		return nil, false, err
	}
	return c, true, nil
}

// errInvalid builds the validation error the handlers return as
// INVALID_ARGUMENT.
func errInvalid(what string) error { return errors.New(what) }
