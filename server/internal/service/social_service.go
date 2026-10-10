package service

import (
	"context"
	"strings"
	"time"

	"connectrpc.com/connect"

	ratatoskv1 "github.com/gokr/ratatosk/server/gen/ratatosk/v1"
	"github.com/gokr/ratatosk/server/internal/store"
)

// SocialService implements ratatosk.v1.SocialService: contacts, discovery and
// invitation links.
type SocialService struct {
	*base
}

// NewSocialService wires the social service onto the shared state.
func NewSocialService(b *base) *SocialService { return &SocialService{base: b} }

func (s *SocialService) ListContacts(ctx context.Context, req *connect.Request[ratatoskv1.ListContactsRequest]) (*connect.Response[ratatoskv1.ListContactsResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	entries := s.st.ContactsOf(user.ID)
	out := make([]*ratatoskv1.Contact, 0, len(entries))
	for _, e := range entries {
		u, err := s.st.UserByID(e.UserID)
		if err != nil {
			continue
		}
		contact := &ratatoskv1.Contact{User: s.userProto(u), Since: ts(e.Since)}
		// Older contacts predate their conversation (or it was never opened);
		// reporting the id, when there is one, saves the app a round trip.
		if c, err := s.st.FindDirectConversation(user.ID, e.UserID); err == nil {
			contact.ConversationId = c.ID
		}
		out = append(out, contact)
	}
	return connect.NewResponse(&ratatoskv1.ListContactsResponse{Contacts: out}), nil
}

func (s *SocialService) AddContact(ctx context.Context, req *connect.Request[ratatoskv1.AddContactRequest]) (*connect.Response[ratatoskv1.AddContactResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	target, err := s.st.UserByUsername(req.Msg.GetUsername())
	if err != nil {
		// Allow an exact display-name match too, since that is what people
		// usually type when they are not sure of the handle.
		target = s.findByDisplayName(req.Msg.GetUsername(), user.ID)
		if target == nil {
			return nil, connect.NewError(connect.CodeNotFound, errInvalid("no account with that username"))
		}
	}
	if target.ID == user.ID {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("you cannot add yourself"))
	}

	now := now()
	if err := s.st.AddContact(user.ID, target.ID, now); err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	c, _, err := s.findDirect(user.ID, target.ID)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	s.broadcastContact("added", user.ID, target.ID, c.ID)
	return connect.NewResponse(&ratatoskv1.AddContactResponse{
		Contact: &ratatoskv1.Contact{
			User:           s.userProto(target),
			Since:          ts(now),
			ConversationId: c.ID,
		},
		Conversation: s.conversationProto(c, user.ID),
	}), nil
}

func (s *SocialService) RemoveContact(ctx context.Context, req *connect.Request[ratatoskv1.RemoveContactRequest]) (*connect.Response[ratatoskv1.RemoveContactResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	targetID := req.Msg.GetUserId()
	if _, err := s.st.UserByID(targetID); err != nil {
		return nil, connect.NewError(connect.CodeNotFound, errInvalid("unknown user"))
	}
	// History survives: only the contact link goes away, because delete
	// semantics that silently drop a conversation's messages are a bug people
	// remember.
	s.st.RemoveContact(user.ID, targetID)
	s.broadcastContact("removed", user.ID, targetID, "")
	return connect.NewResponse(&ratatoskv1.RemoveContactResponse{}), nil
}

func (s *SocialService) SearchUsers(ctx context.Context, req *connect.Request[ratatoskv1.SearchUsersRequest]) (*connect.Response[ratatoskv1.SearchUsersResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	users := s.st.SearchUsers(user.ID, req.Msg.GetQuery(), int(req.Msg.GetLimit()))
	out := make([]*ratatoskv1.User, 0, len(users))
	for _, u := range users {
		out = append(out, s.userProto(u))
	}
	return connect.NewResponse(&ratatoskv1.SearchUsersResponse{Users: out}), nil
}

func (s *SocialService) CreateInvite(ctx context.Context, req *connect.Request[ratatoskv1.CreateInviteRequest]) (*connect.Response[ratatoskv1.CreateInviteResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	// 0 means "use the server default", negative means "never expires".
	var expiresAt time.Time
	hours := req.Msg.GetExpiresInHours()
	switch {
	case hours == 0:
		if s.cfg.InviteTTL > 0 {
			expiresAt = now().Add(s.cfg.InviteTTL)
		}
	case hours > 0:
		if hours > 24*365 {
			return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("expiry is too far in the future"))
		}
		expiresAt = now().Add(time.Duration(hours) * time.Hour)
	}

	maxUses := int(req.Msg.GetMaxUses())
	switch {
	case maxUses == 0:
		maxUses = s.cfg.InviteMaxUses
	case maxUses < 0:
		maxUses = 0 // unlimited
	case maxUses > 1000:
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("at most 1000 uses"))
	}

	inv, err := s.st.CreateInvite(user.ID, expiresAt, maxUses, 10, now())
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	return connect.NewResponse(&ratatoskv1.CreateInviteResponse{Invite: s.inviteProto(inv)}), nil
}

func (s *SocialService) ListInvites(ctx context.Context, req *connect.Request[ratatoskv1.ListInvitesRequest]) (*connect.Response[ratatoskv1.ListInvitesResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	invites := s.st.ListInvites(user.ID)
	out := make([]*ratatoskv1.Invite, 0, len(invites))
	for _, inv := range invites {
		out = append(out, s.inviteProto(inv))
	}
	return connect.NewResponse(&ratatoskv1.ListInvitesResponse{Invites: out}), nil
}

func (s *SocialService) RevokeInvite(ctx context.Context, req *connect.Request[ratatoskv1.RevokeInviteRequest]) (*connect.Response[ratatoskv1.RevokeInviteResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	code := parseInviteCode(req.Msg.GetCode())
	inv, err := s.st.InviteByCode(code)
	if err != nil {
		return nil, connect.NewError(connect.CodeNotFound, errInvalid("that invite does not exist"))
	}
	if inv.InviterID != user.ID {
		return nil, connect.NewError(connect.CodePermissionDenied, errInvalid("that invite is not yours"))
	}
	if _, err := s.st.UpdateInvite(code, func(i *store.Invite) { i.Revoked = true }); err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	return connect.NewResponse(&ratatoskv1.RevokeInviteResponse{}), nil
}

func (s *SocialService) PreviewInvite(ctx context.Context, req *connect.Request[ratatoskv1.PreviewInviteRequest]) (*connect.Response[ratatoskv1.PreviewInviteResponse], error) {
	code := parseInviteCode(req.Msg.GetCode())
	inv, err := s.st.InviteByCode(code)
	if err != nil {
		return connect.NewResponse(&ratatoskv1.PreviewInviteResponse{Valid: false, Reason: "unknown"}), nil
	}
	out := &ratatoskv1.PreviewInviteResponse{
		ExpiresAt:     ts(inv.ExpiresAt),
		RemainingUses: int32(remainingUses(inv)),
	}
	if inviter, err := s.st.UserByID(inv.InviterID); err == nil {
		out.Inviter = s.userProto(inviter)
	}
	if reason := inviteInvalidReason(inv); reason != "" {
		out.Valid = false
		out.Reason = reason
		return connect.NewResponse(out), nil
	}
	out.Valid = true
	// Preview is unauthenticated on purpose (the landing page shows who
	// invited you), so it never reveals whether the *caller* is a contact.
	if user, ok := userOrNil(ctx); ok {
		if s.st.AreContacts(user.ID, inv.InviterID) {
			out.AlreadyContacts = true
		}
	}
	return connect.NewResponse(out), nil
}

func (s *SocialService) RedeemInvite(ctx context.Context, req *connect.Request[ratatoskv1.RedeemInviteRequest]) (*connect.Response[ratatoskv1.RedeemInviteResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	code := parseInviteCode(req.Msg.GetCode())
	inv, err := s.st.InviteByCode(code)
	if err != nil {
		return nil, connect.NewError(connect.CodeNotFound, errInvalid("that invite does not exist"))
	}
	if inv.InviterID == user.ID {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("that is your own invite"))
	}
	// Somebody who already redeemed this link keeps the relationship it
	// created, whatever the remaining uses are: re-opening the same link is not
	// a second redemption. This is what makes "tap the invite again" harmless.
	alreadyRedeemed := false
	for _, id := range inv.RedeemedBy {
		if id == user.ID {
			alreadyRedeemed = true
			break
		}
	}
	if reason := inviteInvalidReason(inv); reason != "" && !alreadyRedeemed {
		return nil, connect.NewError(connect.CodeFailedPrecondition, errInvalid("this invite is "+reason))
	}
	inviter, err := s.st.UserByID(inv.InviterID)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, errInvalid("the inviter no longer exists"))
	}

	now := now()
	if err := s.st.AddContact(user.ID, inviter.ID, now); err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	if !alreadyRedeemed {
		if _, err := s.st.UpdateInvite(code, func(i *store.Invite) {
			i.Uses++
			i.RedeemedBy = append([]string{user.ID}, i.RedeemedBy...)
		}); err != nil {
			return nil, connect.NewError(connect.CodeInternal, err)
		}
	}

	c, _, err := s.findDirect(user.ID, inviter.ID)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	s.broadcastContact("added", inviter.ID, user.ID, c.ID)
	s.broadcastContact("added", user.ID, inviter.ID, c.ID)
	// Both sides see the new conversation straight away.
	s.broadcastConversationCreated(c, user.ID)
	s.broadcastConversationCreated(c, inviter.ID)
	return connect.NewResponse(&ratatoskv1.RedeemInviteResponse{
		Inviter:      s.userProto(inviter),
		Conversation: s.conversationProto(c, user.ID),
	}), nil
}

// --- helpers -------------------------------------------------------------

// inviteProto renders an invite with its full shareable URL.
func (s *SocialService) inviteProto(inv *store.Invite) *ratatoskv1.Invite {
	out := &ratatoskv1.Invite{
		Code:      inv.Code,
		Url:       normalPath(s.cfg.PublicURL, "/join/"+inv.Code),
		CreatedAt: ts(inv.CreatedAt),
		ExpiresAt: ts(inv.ExpiresAt),
		MaxUses:   int32(inv.MaxUses),
		Uses:      int32(inv.Uses),
		Revoked:   inv.Revoked,
		Valid:     inviteInvalidReason(inv) == "",
	}
	for _, id := range inv.RedeemedBy {
		if u, err := s.st.UserByID(id); err == nil {
			out.RedeemedBy = append(out.RedeemedBy, u.DisplayName)
		}
	}
	return out
}

// inviteInvalidReason returns "" when the invite can still be redeemed.
func inviteInvalidReason(inv *store.Invite) string {
	switch {
	case inv.Revoked:
		return "revoked"
	case !inv.ExpiresAt.IsZero() && now().After(inv.ExpiresAt):
		return "expired"
	case inv.MaxUses > 0 && inv.Uses >= inv.MaxUses:
		return "exhausted"
	default:
		return ""
	}
}

func remainingUses(inv *store.Invite) int {
	if inv.MaxUses <= 0 {
		return -1 // unlimited
	}
	left := inv.MaxUses - inv.Uses
	if left < 0 {
		return 0
	}
	return left
}

// parseInviteCode accepts either a bare code or a full invite link, because
// both are what people paste.
func parseInviteCode(raw string) string {
	code := strings.TrimSpace(raw)
	if i := strings.LastIndex(code, "/join/"); i >= 0 {
		code = code[i+len("/join/"):]
	}
	if i := strings.IndexAny(code, "?#"); i >= 0 {
		code = code[:i]
	}
	return strings.ToLower(strings.Trim(code, "/"))
}

// findByDisplayName is the fallback lookup for "start a chat with Ada".
func (s *SocialService) findByDisplayName(name, excludeID string) *store.User {
	name = strings.ToLower(trimSpace(name))
	if name == "" {
		return nil
	}
	for _, u := range s.st.SearchUsers(excludeID, name, 10) {
		if strings.ToLower(u.DisplayName) == name {
			return u
		}
	}
	return nil
}
