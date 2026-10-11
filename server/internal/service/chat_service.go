package service

import (
	"context"
	"errors"
	"sort"
	"strings"

	"connectrpc.com/connect"

	ratatoskv1 "github.com/gokr/ratatosk/server/gen/ratatosk/v1"
	"github.com/gokr/ratatosk/server/internal/store"
)

// ChatService implements ratatosk.v1.ChatService: conversations, messages and
// the realtime stream.
type ChatService struct {
	*base
}

// NewChatService wires the chat service onto the shared state.
func NewChatService(b *base) *ChatService { return &ChatService{base: b} }

// --- conversations -------------------------------------------------------

func (s *ChatService) ListConversations(ctx context.Context, req *connect.Request[ratatoskv1.ListConversationsRequest]) (*connect.Response[ratatoskv1.ListConversationsResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	convs := s.st.ConversationsOf(user.ID)
	out := make([]*ratatoskv1.Conversation, 0, len(convs))
	for _, c := range convs {
		out = append(out, s.conversationProto(c, user.ID))
	}
	// Pinned conversations float to the top, then newest activity.
	sort.SliceStable(out, func(i, j int) bool {
		if out[i].GetPinned() != out[j].GetPinned() {
			return out[i].GetPinned()
		}
		return out[i].GetUpdatedAt().AsTime().After(out[j].GetUpdatedAt().AsTime())
	})
	return connect.NewResponse(&ratatoskv1.ListConversationsResponse{Conversations: out}), nil
}

func (s *ChatService) GetConversation(ctx context.Context, req *connect.Request[ratatoskv1.GetConversationRequest]) (*connect.Response[ratatoskv1.GetConversationResponse], error) {
	user, c, err := s.memberConversation(ctx, req.Msg.GetConversationId())
	if err != nil {
		return nil, err
	}
	return connect.NewResponse(&ratatoskv1.GetConversationResponse{Conversation: s.conversationProto(c, user.ID)}), nil
}

func (s *ChatService) CreateDirectConversation(ctx context.Context, req *connect.Request[ratatoskv1.CreateDirectConversationRequest]) (*connect.Response[ratatoskv1.CreateDirectConversationResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	peer, err := s.resolveUser(req.Msg.GetUserId(), req.Msg.GetUsername())
	if err != nil {
		return nil, err
	}
	if peer.ID == user.ID {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("you cannot start a conversation with yourself"))
	}
	c, created, err := s.findDirect(user.ID, peer.ID)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	// Tell both sides. A new conversation must appear in the other person's
	// list immediately, not on their next refresh.
	if created {
		s.broadcastConversationCreated(c, user.ID)
		s.broadcastConversationCreated(c, peer.ID)
	}
	return connect.NewResponse(&ratatoskv1.CreateDirectConversationResponse{
		Conversation: s.conversationProto(c, user.ID),
		Created:      created,
	}), nil
}

func (s *ChatService) CreateGroupConversation(ctx context.Context, req *connect.Request[ratatoskv1.CreateGroupConversationRequest]) (*connect.Response[ratatoskv1.CreateGroupConversationResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	title := trimSpace(req.Msg.GetTitle())
	if title == "" {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("a group needs a name"))
	}
	if len(title) > 128 {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("group name must be at most 128 characters"))
	}
	members, err := s.resolveMembers(req.Msg.GetUserIds(), req.Msg.GetUsernames(), user.ID)
	if err != nil {
		return nil, err
	}
	if len(members) == 0 {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("add at least one member"))
	}
	if len(members)+1 > s.cfg.MaxMembers {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("that group would be too large"))
	}
	c, err := s.st.CreateConversation(store.KindGroup, title, user.ID, members, now())
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	s.systemMessage(c.ID, user.DisplayName+" created the group")
	for _, id := range members {
		s.broadcastConversationCreated(c, id)
	}
	fresh, err := s.st.ConversationByID(c.ID)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	return connect.NewResponse(&ratatoskv1.CreateGroupConversationResponse{
		Conversation: s.conversationProto(fresh, user.ID),
	}), nil
}

func (s *ChatService) UpdateConversation(ctx context.Context, req *connect.Request[ratatoskv1.UpdateConversationRequest]) (*connect.Response[ratatoskv1.UpdateConversationResponse], error) {
	user, c, err := s.memberConversation(ctx, req.Msg.GetConversationId())
	if err != nil {
		return nil, err
	}
	msg := req.Msg
	title := trimSpace(msg.GetTitle())
	if len(title) > 128 {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("group name must be at most 128 characters"))
	}
	if id := msg.GetAvatarAttachmentId(); id != "" {
		if _, err := s.st.AttachmentByID(id); err != nil {
			return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("unknown attachment"))
		}
	}
	if title != "" && c.Kind == store.KindDirect {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("a direct conversation has no title of its own"))
	}
	if (title != "" || msg.GetAvatarAttachmentId() != "" || msg.GetClearAvatar()) && c.Kind == store.KindGroup {
		if !s.isOwner(c, user.ID) {
			return nil, connect.NewError(connect.CodePermissionDenied, errInvalid("only the group owner can rename it"))
		}
	}

	updated, err := s.st.UpdateConversation(c.ID, func(conv *store.Conversation) {
		if c.Kind == store.KindGroup {
			if title != "" {
				conv.Title = title
			}
			if id := msg.GetAvatarAttachmentId(); id != "" {
				conv.Avatar = id
			}
			if msg.GetClearAvatar() {
				conv.Avatar = ""
			}
		}
		// Mute and pin are per viewer, not per conversation.
		if m, ok := conv.Members[user.ID]; ok {
			if msg.Muted != nil {
				m.Muted = msg.GetMuted()
			}
			if msg.Pinned != nil {
				m.Pinned = msg.GetPinned()
			}
		}
		conv.UpdatedAt = now()
	})
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	s.broadcastConversationsRefreshed(updated)
	return connect.NewResponse(&ratatoskv1.UpdateConversationResponse{
		Conversation: s.conversationProto(updated, user.ID),
	}), nil
}

func (s *ChatService) AddMembers(ctx context.Context, req *connect.Request[ratatoskv1.AddMembersRequest]) (*connect.Response[ratatoskv1.AddMembersResponse], error) {
	user, c, err := s.memberConversation(ctx, req.Msg.GetConversationId())
	if err != nil {
		return nil, err
	}
	if c.Kind != store.KindGroup {
		return nil, connect.NewError(connect.CodeFailedPrecondition, errInvalid("this is a direct conversation"))
	}
	if !s.isOwner(c, user.ID) {
		return nil, connect.NewError(connect.CodePermissionDenied, errInvalid("only the group owner can add members"))
	}
	candidates, err := s.resolveMembers(req.Msg.GetUserIds(), req.Msg.GetUsernames(), "")
	if err != nil {
		return nil, err
	}
	var added []*store.User
	for _, id := range candidates {
		if _, exists := c.Members[id]; exists {
			continue
		}
		added = append(added, mustUser(s, id))
	}
	if len(added) == 0 {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("nobody new to add"))
	}
	if len(c.Members)+len(added) > s.cfg.MaxMembers {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("that group would be too large"))
	}
	updated, err := s.st.UpdateConversation(c.ID, func(conv *store.Conversation) {
		for _, u := range added {
			conv.Members[u.ID] = &store.Member{
				UserID:   u.ID,
				Role:     store.RoleMember,
				JoinedAt: now(),
			}
		}
		conv.UpdatedAt = now()
	})
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	names := make([]string, 0, len(added))
	for _, u := range added {
		names = append(names, u.DisplayName)
	}
	s.systemMessage(c.ID, user.DisplayName+" added "+strings.Join(names, ", "))
	// New members need the conversation before its messages arrive.
	for _, u := range added {
		s.broadcastConversationCreated(updated, u.ID)
	}
	s.broadcastConversationsRefreshed(updated)
	return connect.NewResponse(&ratatoskv1.AddMembersResponse{
		Conversation: s.conversationProto(updated, user.ID),
	}), nil
}

func (s *ChatService) RemoveMember(ctx context.Context, req *connect.Request[ratatoskv1.RemoveMemberRequest]) (*connect.Response[ratatoskv1.RemoveMemberResponse], error) {
	user, c, err := s.memberConversation(ctx, req.Msg.GetConversationId())
	if err != nil {
		return nil, err
	}
	if c.Kind != store.KindGroup {
		return nil, connect.NewError(connect.CodeFailedPrecondition, errInvalid("this is a direct conversation"))
	}
	// An empty id in the request means "remove me".
	targetID := req.Msg.GetUserId()
	if targetID == "" {
		targetID = user.ID
	}
	leaving := targetID == user.ID
	if !leaving && !s.isOwner(c, user.ID) {
		return nil, connect.NewError(connect.CodePermissionDenied, errInvalid("only the group owner can remove members"))
	}
	target, err := s.st.UserByID(targetID)
	if err != nil {
		return nil, connect.NewError(connect.CodeNotFound, errInvalid("unknown user"))
	}
	if _, member := c.Members[targetID]; !member {
		return nil, connect.NewError(connect.CodeNotFound, errInvalid("that person is not in this group"))
	}

	// The last member leaving deletes the conversation for everyone.
	if len(c.Members) == 1 {
		if _, err := s.st.UpdateConversation(c.ID, func(conv *store.Conversation) {
			delete(conv.Members, targetID)
			conv.UpdatedAt = now()
		}); err != nil {
			return nil, connect.NewError(connect.CodeInternal, err)
		}
		s.broadcastConversationRemoved(c.ID, targetID)
		return connect.NewResponse(&ratatoskv1.RemoveMemberResponse{
			Conversation: &ratatoskv1.Conversation{Id: c.ID},
		}), nil
	}

	updated, err := s.st.UpdateConversation(c.ID, func(conv *store.Conversation) {
		delete(conv.Members, targetID)
		conv.UpdatedAt = now()
		// Ownership must not die with the owner: hand it to the longest-standing
		// member so the group stays manageable.
		if targetID == conv.CreatedBy || conv.Members[conv.CreatedBy] == nil {
			next := ""
			for id, m := range conv.Members {
				if next == "" || m.JoinedAt.Before(conv.Members[next].JoinedAt) {
					next = id
				}
			}
			if next != "" {
				conv.Members[next].Role = store.RoleOwner
				conv.CreatedBy = next
			}
		}
	})
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	verb := "removed"
	if leaving {
		verb = "left"
	}
	s.systemMessage(c.ID, target.DisplayName+" "+verb+" the group")
	s.broadcastConversationRemoved(c.ID, targetID)
	s.broadcastConversationsRefreshed(updated)
	return connect.NewResponse(&ratatoskv1.RemoveMemberResponse{
		Conversation: s.conversationProto(updated, user.ID),
	}), nil
}

// --- messages ------------------------------------------------------------

func (s *ChatService) ListMessages(ctx context.Context, req *connect.Request[ratatoskv1.ListMessagesRequest]) (*connect.Response[ratatoskv1.ListMessagesResponse], error) {
	_, _, err := s.memberConversation(ctx, req.Msg.GetConversationId())
	if err != nil {
		return nil, err
	}
	msgs, hasMore, err := s.st.MessagesOf(req.Msg.GetConversationId(), req.Msg.GetBeforeSeq(), req.Msg.GetAfterSeq(), int(req.Msg.GetLimit()))
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	out := make([]*ratatoskv1.Message, 0, len(msgs))
	for _, m := range msgs {
		out = append(out, s.messageProto(m))
	}
	return connect.NewResponse(&ratatoskv1.ListMessagesResponse{Messages: out, HasMore: hasMore}), nil
}

func (s *ChatService) SendMessage(ctx context.Context, req *connect.Request[ratatoskv1.SendMessageRequest]) (*connect.Response[ratatoskv1.SendMessageResponse], error) {
	user, c, err := s.memberConversation(ctx, req.Msg.GetConversationId())
	if err != nil {
		return nil, err
	}
	text := req.Msg.GetText()
	if len(text) > 8000 {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("message is too long"))
	}
	attachmentIDs := req.Msg.GetAttachmentIds()
	ciphertext := req.Msg.GetCiphertext()
	cryptoVersion := req.Msg.GetCryptoVersion()

	// An encrypted message carries its body where the server cannot read it, so
	// the only thing to validate is that the sender was consistent: sealed
	// bytes with no nonce or version could never be decrypted by anyone.
	if len(ciphertext) > 0 {
		if len(req.Msg.GetNonce()) == 0 || cryptoVersion == "" {
			return nil, connect.NewError(connect.CodeInvalidArgument,
				errInvalid("an encrypted message needs its nonce and crypto version"))
		}
		if req.Msg.GetSenderDeviceKeyId() == "" {
			return nil, connect.NewError(connect.CodeInvalidArgument,
				errInvalid("an encrypted message needs a sender device key"))
		}
		if len(ciphertext) > maxCiphertextBytes {
			return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("message is too long"))
		}
		if text != "" {
			return nil, connect.NewError(connect.CodeInvalidArgument,
				errInvalid("send either plaintext or ciphertext, not both"))
		}
	} else if strings.TrimSpace(text) == "" && len(attachmentIDs) == 0 {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("write something first"))
	}
	if len(attachmentIDs) > 10 {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("at most 10 attachments per message"))
	}
	for _, id := range attachmentIDs {
		if _, err := s.st.AttachmentByID(id); err != nil {
			return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("unknown attachment"))
		}
	}

	// Idempotency: a resend with the same client_message_id (the client
	// retrying after a dropped connection) must not double-post.
	clientID := req.Msg.GetClientMessageId()
	if existing, err := s.st.FindMessageByClientID(c.ID, user.ID, clientID); err == nil {
		return connect.NewResponse(&ratatoskv1.SendMessageResponse{Message: s.messageProto(existing)}), nil
	}

	// The reply target is validated whenever the client names it, which is what
	// keeps a reply from pointing outside the conversation. An encrypted client
	// leaves this empty and puts the text it quotes inside the sealed body, so
	// the server does not learn which message is being replied to.
	replyTo := req.Msg.GetReplyToId()
	if replyTo != "" {
		parent, err := s.st.MessageByID(replyTo)
		if err != nil || parent.ConversationID != c.ID {
			return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("cannot reply to that message"))
		}
	}

	saved, err := s.st.AppendMessage(&store.Message{
		ConversationID:  c.ID,
		SenderID:        user.ID,
		Kind:            store.MessageText,
		Text:            text,
		Attachments:     attachmentIDs,
		ReplyToID:       replyTo,
		ClientMessageID: clientID,
		// Sealed content: stored as received, opaque to this server.
		Ciphertext:        ciphertext,
		Nonce:             req.Msg.GetNonce(),
		SenderDeviceKeyID: req.Msg.GetSenderDeviceKeyId(),
		KeyEpoch:          req.Msg.GetKeyEpoch(),
		CryptoVersion:     cryptoVersion,
	}, now())
	if err != nil {
		if errors.Is(err, store.ErrNotMember) {
			return nil, connect.NewError(connect.CodePermissionDenied, errInvalid("you are not in this conversation"))
		}
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	// Only newly appended messages notify: retries, edits and reactions do not.
	s.notifyMessage(saved)

	// Sending implies having read everything up to here.
	s.touchRead(c.ID, user.ID, saved.Seq)
	s.broadcastMessage(saved)
	s.refreshConversation(c.ID)
	return connect.NewResponse(&ratatoskv1.SendMessageResponse{Message: s.messageProto(saved)}), nil
}

func (s *ChatService) EditMessage(ctx context.Context, req *connect.Request[ratatoskv1.EditMessageRequest]) (*connect.Response[ratatoskv1.EditMessageResponse], error) {
	_, msg, err := s.ownMessage(ctx, req.Msg.GetMessageId())
	if err != nil {
		return nil, err
	}
	text := strings.TrimSpace(req.Msg.GetText())
	ciphertext := req.Msg.GetCiphertext()
	switch {
	case len(ciphertext) > 0:
		if len(req.Msg.GetNonce()) == 0 || req.Msg.GetCryptoVersion() == "" {
			return nil, connect.NewError(connect.CodeInvalidArgument,
				errInvalid("an encrypted message needs its nonce and crypto version"))
		}
		if text != "" {
			return nil, connect.NewError(connect.CodeInvalidArgument,
				errInvalid("send either plaintext or ciphertext, not both"))
		}
	case text == "" && len(msg.Attachments) == 0:
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("a message cannot be empty"))
	case len(text) > 8000:
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("message is too long"))
	}
	updated, err := s.st.UpdateMessage(msg.ID, func(m *store.Message) {
		if len(ciphertext) > 0 {
			// Replace the seal wholesale: the old plaintext, if any, must not
			// survive an edit that was supposed to hide it.
			m.Text = ""
			m.Ciphertext = append([]byte(nil), ciphertext...)
			m.Nonce = append([]byte(nil), req.Msg.GetNonce()...)
			m.CryptoVersion = req.Msg.GetCryptoVersion()
		} else {
			m.Text = text
		}
		m.EditedAt = now()
	})
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	s.broadcastMessage(updated)
	s.refreshConversation(msg.ConversationID)
	return connect.NewResponse(&ratatoskv1.EditMessageResponse{Message: s.messageProto(updated)}), nil
}

func (s *ChatService) DeleteMessage(ctx context.Context, req *connect.Request[ratatoskv1.DeleteMessageRequest]) (*connect.Response[ratatoskv1.DeleteMessageResponse], error) {
	_, msg, err := s.ownMessage(ctx, req.Msg.GetMessageId())
	if err != nil {
		return nil, err
	}
	updated, err := s.st.UpdateMessage(msg.ID, func(m *store.Message) {
		// Tombstone rather than delete: seq stays gapless, the bubble keeps
		// its place, replies to it still resolve.
		m.Deleted = true
		m.Text = ""
		m.Attachments = nil
		m.Reactions = nil
		m.EditedAt = now()
	})
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	s.broadcastMessage(updated)
	s.refreshConversation(msg.ConversationID)
	return connect.NewResponse(&ratatoskv1.DeleteMessageResponse{Message: s.messageProto(updated)}), nil
}

func (s *ChatService) AddReaction(ctx context.Context, req *connect.Request[ratatoskv1.AddReactionRequest]) (*connect.Response[ratatoskv1.AddReactionResponse], error) {
	user, msg, err := s.visibleMessage(ctx, req.Msg.GetMessageId())
	if err != nil {
		return nil, err
	}
	emoji := strings.TrimSpace(req.Msg.GetEmoji())
	if emoji == "" || len([]rune(emoji)) > 8 {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("pick an emoji"))
	}
	updated, err := s.st.UpdateMessage(msg.ID, func(m *store.Message) {
		if m.Reactions == nil {
			m.Reactions = map[string][]string{}
		}
		for _, id := range m.Reactions[emoji] {
			if id == user.ID {
				return // already reacted; keep the call idempotent
			}
		}
		m.Reactions[emoji] = append(m.Reactions[emoji], user.ID)
	})
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	s.broadcastMessage(updated)
	return connect.NewResponse(&ratatoskv1.AddReactionResponse{Message: s.messageProto(updated)}), nil
}

func (s *ChatService) RemoveReaction(ctx context.Context, req *connect.Request[ratatoskv1.RemoveReactionRequest]) (*connect.Response[ratatoskv1.RemoveReactionResponse], error) {
	user, msg, err := s.visibleMessage(ctx, req.Msg.GetMessageId())
	if err != nil {
		return nil, err
	}
	emoji := strings.TrimSpace(req.Msg.GetEmoji())
	updated, err := s.st.UpdateMessage(msg.ID, func(m *store.Message) {
		if m.Reactions == nil {
			return
		}
		kept := m.Reactions[emoji][:0]
		for _, id := range m.Reactions[emoji] {
			if id != user.ID {
				kept = append(kept, id)
			}
		}
		if len(kept) == 0 {
			delete(m.Reactions, emoji)
		} else {
			m.Reactions[emoji] = kept
		}
	})
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	s.broadcastMessage(updated)
	return connect.NewResponse(&ratatoskv1.RemoveReactionResponse{Message: s.messageProto(updated)}), nil
}

func (s *ChatService) MarkRead(ctx context.Context, req *connect.Request[ratatoskv1.MarkReadRequest]) (*connect.Response[ratatoskv1.MarkReadResponse], error) {
	user, c, err := s.memberConversation(ctx, req.Msg.GetConversationId())
	if err != nil {
		return nil, err
	}
	upTo := req.Msg.GetUpToSeq()
	if upTo <= 0 {
		upTo = c.LastSeq
	}
	seq := s.touchRead(c.ID, user.ID, upTo)
	unread := s.st.UnreadCount(c.ID, user.ID, s.cfg.UnreadWindow)
	return connect.NewResponse(&ratatoskv1.MarkReadResponse{
		ConversationId: c.ID,
		LastReadSeq:    seq,
		UnreadCount:    int32(unread),
	}), nil
}

func (s *ChatService) SetTyping(ctx context.Context, req *connect.Request[ratatoskv1.SetTypingRequest]) (*connect.Response[ratatoskv1.SetTypingResponse], error) {
	user, c, err := s.memberConversation(ctx, req.Msg.GetConversationId())
	if err != nil {
		return nil, err
	}
	if req.Msg.GetTyping() {
		// Re-arm the expiry so a long sentence cannot leave a stuck indicator.
		s.typing.Start(c.ID, user.ID, user.DisplayName)
	} else {
		s.typing.Stop(c.ID, user.ID)
	}
	s.broadcastTyping(c.ID, user.ID, user.DisplayName, req.Msg.GetTyping())
	return connect.NewResponse(&ratatoskv1.SetTypingResponse{}), nil
}

func (s *ChatService) SearchMessages(ctx context.Context, req *connect.Request[ratatoskv1.SearchMessagesRequest]) (*connect.Response[ratatoskv1.SearchMessagesResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	var scope []string
	if convID := req.Msg.GetConversationId(); convID != "" {
		if _, _, err := s.memberConversation(ctx, convID); err != nil {
			return nil, err
		}
		scope = []string{convID}
	} else {
		for _, c := range s.st.ConversationsOf(user.ID) {
			scope = append(scope, c.ID)
		}
	}
	hits := s.st.SearchMessages(scope, req.Msg.GetQuery(), int(req.Msg.GetLimit()))
	out := make([]*ratatoskv1.SearchResult, 0, len(hits))
	for _, m := range hits {
		result := &ratatoskv1.SearchResult{
			Message:           s.messageProto(m),
			ConversationId:    m.ConversationID,
			SenderName:        "",
			ConversationTitle: "",
		}
		if c, err := s.st.ConversationByID(m.ConversationID); err == nil {
			conv := s.conversationProto(c, user.ID)
			result.ConversationTitle = conv.GetTitle()
			result.AvatarUrl = conv.GetAvatarUrl()
		}
		if u, err := s.st.UserByID(m.SenderID); err == nil {
			result.SenderName = u.DisplayName
		}
		out = append(out, result)
	}
	return connect.NewResponse(&ratatoskv1.SearchMessagesResponse{Results: out}), nil
}

func (s *ChatService) UploadAttachment(ctx context.Context, req *connect.Request[ratatoskv1.UploadAttachmentRequest]) (*connect.Response[ratatoskv1.UploadAttachmentResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	data := req.Msg.GetData()
	if len(data) == 0 {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("the file is empty"))
	}
	if int64(len(data)) > s.cfg.MaxUploadBytes {
		return nil, connect.NewError(connect.CodeInvalidArgument,
			errInvalid("file is larger than the limit"))
	}
	filename := trimSpace(req.Msg.GetFilename())
	if filename == "" {
		filename = "upload"
	}
	contentType := req.Msg.GetContentType()
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	if req.Msg.GetEncrypted() {
		// The bytes are a client-side seal and the real name and type live
		// inside the message envelope. What the server records is a placeholder
		// so it stores neither the filename nor the content type.
		contentType = "application/octet-stream"
		filename = ""
	}
	att, err := s.st.PutAttachment(user.ID, filename, contentType, data, req.Msg.GetEncrypted(), 0, 0, now())
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	return connect.NewResponse(&ratatoskv1.UploadAttachmentResponse{Attachment: s.attachmentProto(att)}), nil
}

func (s *ChatService) Subscribe(ctx context.Context, req *connect.Request[ratatoskv1.SubscribeRequest], stream *connect.ServerStream[ratatoskv1.Event]) error {
	user, err := s.requireUser(ctx)
	if err != nil {
		return err
	}
	sub, first := s.hub.Subscribe(user.ID)
	defer func() {
		if s.hub.Unsubscribe(sub) {
			s.presence.Disconnect(user.ID)
		}
	}()
	if first {
		s.presence.Connect(user.ID)
	} else {
		// An additional device does not change presence, but it does mean the
		// user is active again.
		s.presence.Active(user.ID)
	}

	// The first frame identifies the viewer so the client can render before it
	// has fetched anything.
	if err := stream.Send(&ratatoskv1.Event{
		Seq: s.hub.NextSeq(),
		At:  ts(now()),
		Payload: &ratatoskv1.Event_Hello{Hello: &ratatoskv1.Hello{
			User:       s.userProto(user),
			ServerTime: ts(now()),
		}},
	}); err != nil {
		return err
	}

	for {
		select {
		case <-ctx.Done():
			return nil
		case <-sub.Overflow():
			// The client fell too far behind to receive a consistent stream.
			// Ending the stream makes it reconnect and resync from the store,
			// which is correct, rather than quietly dropping events.
			return connect.NewError(connect.CodeResourceExhausted, errInvalid("event stream fell behind; reconnect"))
		case ev := <-sub.Events():
			if err := stream.Send(ev); err != nil {
				return err
			}
		}
	}
}

// --- helpers -------------------------------------------------------------

// memberConversation loads a conversation and checks that the caller is in it.
// Every read and write path goes through this, so a non-member can neither see
// nor guess their way into a conversation.
func (s *ChatService) memberConversation(ctx context.Context, convID string) (*store.User, *store.Conversation, error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, nil, err
	}
	c, err := s.st.ConversationByID(convID)
	if err != nil {
		return nil, nil, connect.NewError(connect.CodeNotFound, errInvalid("conversation not found"))
	}
	if _, ok := c.Members[user.ID]; !ok {
		return nil, nil, connect.NewError(connect.CodePermissionDenied, errInvalid("you are not in this conversation"))
	}
	return user, c, nil
}

// ownMessage loads a message the caller wrote, in a conversation they are in.
func (s *ChatService) ownMessage(ctx context.Context, msgID string) (*store.User, *store.Message, error) {
	user, msg, err := s.visibleMessage(ctx, msgID)
	if err != nil {
		return nil, nil, err
	}
	if msg.SenderID != user.ID {
		return nil, nil, connect.NewError(connect.CodePermissionDenied, errInvalid("you can only change your own messages"))
	}
	if msg.Deleted {
		return nil, nil, connect.NewError(connect.CodeFailedPrecondition, errInvalid("that message was deleted"))
	}
	if msg.Kind == store.MessageSystem {
		return nil, nil, connect.NewError(connect.CodePermissionDenied, errInvalid("system messages cannot be edited"))
	}
	return user, msg, nil
}

// visibleMessage loads a message the caller may see.
func (s *ChatService) visibleMessage(ctx context.Context, msgID string) (*store.User, *store.Message, error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, nil, err
	}
	msg, err := s.st.MessageByID(msgID)
	if err != nil {
		return nil, nil, connect.NewError(connect.CodeNotFound, errInvalid("message not found"))
	}
	c, err := s.st.ConversationByID(msg.ConversationID)
	if err != nil {
		return nil, nil, connect.NewError(connect.CodeNotFound, errInvalid("conversation not found"))
	}
	if _, ok := c.Members[user.ID]; !ok {
		return nil, nil, connect.NewError(connect.CodePermissionDenied, errInvalid("you are not in this conversation"))
	}
	return user, msg, nil
}

// resolveUser accepts either an id or a handle, for calls that take one person.
func (s *ChatService) resolveUser(userID, username string) (*store.User, error) {
	switch {
	case userID != "":
		u, err := s.st.UserByID(userID)
		if err != nil {
			return nil, connect.NewError(connect.CodeNotFound, errInvalid("unknown user"))
		}
		return u, nil
	case trimSpace(username) != "":
		u, err := s.st.UserByUsername(username)
		if err != nil {
			return nil, connect.NewError(connect.CodeNotFound, errInvalid("no account with that username"))
		}
		return u, nil
	default:
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("say who you mean"))
	}
}

// resolveMembers turns ids and handles into a deduplicated member id list.
func (s *ChatService) resolveMembers(userIDs, usernames []string, exclude string) ([]string, error) {
	seen := map[string]struct{}{}
	var out []string
	add := func(id string) {
		if id == exclude {
			return
		}
		if _, ok := seen[id]; ok {
			return
		}
		seen[id] = struct{}{}
		out = append(out, id)
	}
	for _, id := range userIDs {
		if id == "" {
			continue
		}
		u, err := s.st.UserByID(id)
		if err != nil {
			return nil, connect.NewError(connect.CodeNotFound, errInvalid("unknown user"))
		}
		add(u.ID)
	}
	for _, name := range usernames {
		if trimSpace(name) == "" {
			continue
		}
		u, err := s.st.UserByUsername(name)
		if err != nil {
			return nil, connect.NewError(connect.CodeNotFound,
				errInvalid("no account with the username "+trimSpace(name)))
		}
		add(u.ID)
	}
	return out, nil
}

func (s *ChatService) isOwner(c *store.Conversation, userID string) bool {
	m, ok := c.Members[userID]
	return ok && m.Role == store.RoleOwner
}

// touchRead advances the caller's read cursor, never moving it backwards
// (marking a conversation read on one device must not un-read it on another).
func (s *ChatService) touchRead(convID, userID string, upTo int64) int64 {
	updated, err := s.st.UpdateConversation(convID, func(c *store.Conversation) {
		if m, ok := c.Members[userID]; ok {
			if upTo > m.LastReadSeq {
				m.LastReadSeq = upTo
				m.LastReadAt = now()
			}
		}
	})
	if err != nil {
		return upTo
	}
	seq := int64(0)
	if m, ok := updated.Members[userID]; ok {
		seq = m.LastReadSeq
	}
	s.broadcastRead(convID, userID, seq)
	return seq
}

// mustUser loads a user that a previous check already proved exists.
func mustUser(s *ChatService, id string) *store.User {
	u, err := s.st.UserByID(id)
	if err != nil {
		return &store.User{ID: id, DisplayName: "Someone"}
	}
	return u
}
