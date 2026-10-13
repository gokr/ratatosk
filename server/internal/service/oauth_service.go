package service

import (
	"context"
	"strings"
	"time"

	"github.com/gokr/ratatosk/server/internal/googleid"
	"github.com/gokr/ratatosk/server/internal/ids"
	"github.com/gokr/ratatosk/server/internal/store"
)

// Social sign-in, on the two rules the product asked for: everybody gets a
// username, and an account only exists if an invitation invited it.
//
// The consequences are deliberate and worth stating, because they shape the code
// below:
//
//   - Google authenticates; it does not create. A verified identity with no linked
//     account becomes a *pending* registration, not an account.
//   - A pending registration is completed with a username and an invite code. Only
//     then is the account created and the identity linked.
//   - An identity that is already linked signs in directly, invitation or not. The
//     invitation gated the creation, and asking again on every sign-in would lock
//     people out of accounts they already have.
//
// The verified identity never travels back through the browser as a claim to be
// trusted: the browser gets an opaque single-use token and the server remembers
// what it verified.

// PendingLifetime is how long a verified identity waits for a username and an
// invitation. Long enough to find the invite link, short enough that an abandoned
// attempt leaves nothing behind.
const PendingLifetime = 30 * time.Minute

// OAuthSignInResult is the outcome of a verified provider identity: either a session
// for an existing account, or a pending registration needing an invitation.
type OAuthSignInResult struct {
	// Session is set when the identity was already linked to an account.
	Token     string
	User      *store.User
	ExpiresAt time.Time
	// PendingToken is set when the identity needs an invitation and a username.
	PendingToken string
	// SuggestName is a starting point for the username form, from the provider.
	SuggestName string
	Email       string
}

// SignInWithGoogle resolves a verified Google identity.
//
// The verification itself happened before this is called; what happens here decides
// whether the identity is a sign-in or the start of a registration.
func (b *base) StartGoogleSignIn(ctx context.Context, id *googleid.Identity) (*OAuthSignInResult, error) {
	if id == nil || id.Subject == "" {
		return nil, errInvalid("that sign-in is missing an identity")
	}
	now := now()

	// An identity that is already linked is a sign-in. No invitation is asked for:
	// the account exists, and requiring one to reach your own account would be a
	// lockout, not a gate.
	if link, err := b.st.OAuthIdentityBySubject("google", id.Subject); err == nil {
		user, err := b.st.UserByID(link.UserID)
		if err != nil {
			return nil, errInvalid("this account no longer exists")
		}
		// Refresh the copy of the provider's details; the link itself is by subject
		// and never moves.
		_ = b.st.PutOAuthIdentity(&store.OAuthIdentity{
			UserID: user.ID, Provider: "google", Subject: id.Subject,
			Email: id.Email, EmailVerified: id.EmailVerified, Name: id.Name,
			CreatedAt: link.CreatedAt, LastLogin: now,
		})
		session, err := b.st.CreateSession(user.ID, b.cfg.SessionTTL, now)
		if err != nil {
			return nil, err
		}
		return &OAuthSignInResult{Token: session.Token, User: user, ExpiresAt: session.ExpiresAt}, nil
	} else if err != store.ErrNotFound {
		return nil, err
	}

	// Not linked: this is a registration, and it needs an invitation.
	pending := &store.OAuthPending{
		Token:     ids.Token(),
		Provider:  "google",
		Subject:   id.Subject,
		Email:     id.Email,
		Name:      id.Name,
		CreatedAt: now,
		ExpiresAt: now.Add(PendingLifetime),
	}
	if err := b.st.PutOAuthPending(pending); err != nil {
		return nil, err
	}
	return &OAuthSignInResult{
		PendingToken: pending.Token,
		SuggestName:  suggestUsername(id.Name, id.Email),
		Email:        id.Email,
	}, nil
}

// FinishGoogleSignUp turns a pending identity into an account.
//
// The invitation is checked here rather than when the redirect started, because the
// code is what the person has to go and find; holding the pending identity across
// that is exactly what the pending table is for.
func (b *base) CompleteGoogleSignUp(ctx context.Context, pendingToken, username, displayName, inviteCode string) (*store.User, *store.Session, error) {
	pending, err := b.st.TakeOAuthPending(pendingToken, now())
	if err != nil {
		return nil, nil, errInvalid("this sign-up expired; start again")
	}
	// The identity may have been linked between the two steps (the same person
	// finishing in another tab). Treat that as a sign-in rather than a second
	// account.
	if link, err := b.st.OAuthIdentityBySubject(pending.Provider, pending.Subject); err == nil {
		session, err := b.st.CreateSession(link.UserID, b.cfg.SessionTTL, now())
		if err != nil {
			return nil, nil, err
		}
		user, err := b.st.UserByID(link.UserID)
		if err != nil {
			return nil, nil, err
		}
		return user, session, nil
	}

	inv, err := b.ReserveInvite(inviteCode, "")
	if err != nil {
		// Put the pending identity back so a typo in the code is not fatal: the
		// person keeps their verified identity and can try again. A fresh token is
		// not needed because nothing was consumed except the read.
		_ = b.st.PutOAuthPending(pending)
		return nil, nil, err
	}
	displayName = trimSpace(displayName)
	if displayName == "" {
		displayName = trimSpace(pending.Name)
	}
	user, err := b.st.CreateUser(username, displayName, "", "", b.accentFor(username), now())
	if err != nil {
		b.ReleaseInvite(inv.Code, "")
		_ = b.st.PutOAuthPending(pending)
		return nil, nil, err
	}
	// The account has no password at all. Every path that would check one must
	// therefore refuse rather than compare an empty credential — see
	// auth.VerifyPassword, which is where that is enforced.
	if err := b.st.PutOAuthIdentity(&store.OAuthIdentity{
		UserID: user.ID, Provider: pending.Provider, Subject: pending.Subject,
		Email: pending.Email, EmailVerified: true, Name: pending.Name,
		CreatedAt: now(), LastLogin: now(),
	}); err != nil {
		return nil, nil, err
	}
	if err := b.CompleteInvite(inv, user.ID); err != nil {
		return nil, nil, err
	}
	session, err := b.st.CreateSession(user.ID, b.cfg.SessionTTL, now())
	if err != nil {
		return nil, nil, err
	}
	b.log.Info("account created through google sign-in",
		"user", user.ID, "username", user.Username, "invite", inv.Code)
	return user, session, nil
}

// suggestUsername proposes a handle from the provider's name or email.
//
// A suggestion only: it is shown in a field the person edits, and nothing is created
// until they submit. It is offered because typing a handle is the friction in an
// otherwise two-click flow.
func suggestUsername(name, email string) string {
	base := email
	if at := indexByte(base, '@'); at > 0 {
		base = base[:at]
	}
	if trimSpace(name) != "" {
		base = name
	}
	out := make([]rune, 0, len(base))
	for _, r := range foldAccents(lowerASCII(base)) {
		switch {
		case r >= 'a' && r <= 'z', r >= '0' && r <= '9':
			out = append(out, r)
		case r == ' ' || r == '.' || r == '_' || r == '-':
			out = append(out, '-')
		}
	}
	// Collapse runs and trim the ends, so "Göran  Krampe" does not become
	// "--ran--krampe".
	collapsed := make([]rune, 0, len(out))
	for _, r := range out {
		if r == '-' && len(collapsed) > 0 && collapsed[len(collapsed)-1] == '-' {
			continue
		}
		collapsed = append(collapsed, r)
	}
	for len(collapsed) > 0 && collapsed[0] == '-' {
		collapsed = collapsed[1:]
	}
	for len(collapsed) > 0 && collapsed[len(collapsed)-1] == '-' {
		collapsed = collapsed[:len(collapsed)-1]
	}
	if len(collapsed) < 3 {
		return ""
	}
	if len(collapsed) > 32 {
		collapsed = collapsed[:32]
	}
	return string(collapsed)
}

// foldAccents maps the accented Latin letters a name is likely to contain onto
// their ASCII letters, rather than dropping them.
//
// Dropping them is what a naive filter does, and it is visibly wrong: "Göran" became
// "gran", "Åsa" became "sa". Since Swedish is a first-class language here, the
// folding table is worth having.
func foldAccents(s string) string {
	var b strings.Builder
	for _, r := range s {
		if folded, ok := accentFold[r]; ok {
			b.WriteRune(folded)
			continue
		}
		b.WriteRune(r)
	}
	return b.String()
}

// accentFold covers Latin-1 Supplement and the Latin Extended-A letters that occur
// in the languages this server is used in. Anything absent is filtered out by the
// caller, so the table only has to be better than dropping the letter entirely.
var accentFold = map[rune]rune{
	'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a', 'ă': 'a', 'ą': 'a',
	'ç': 'c', 'ć': 'c', 'č': 'c',
	'ð': 'd', 'ď': 'd',
	'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ė': 'e', 'ę': 'e', 'ě': 'e',
	'ğ': 'g', 'ģ': 'g',
	'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i', 'į': 'i', 'ı': 'i',
	'ł': 'l', 'ĺ': 'l', 'ľ': 'l',
	'ñ': 'n', 'ń': 'n', 'ň': 'n',
	'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'ō': 'o', 'ő': 'o',
	'ŕ': 'r', 'ř': 'r',
	'ś': 's', 'š': 's', 'ş': 's', 'ș': 's',
	'ť': 't', 'ț': 't',
	'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'ů': 'u', 'ű': 'u', 'ų': 'u',
	'ý': 'y', 'ÿ': 'y',
	'ź': 'z', 'ż': 'z', 'ž': 'z',
	'þ': 't',
}

func lowerASCII(s string) string {
	out := []rune(s)
	for i, r := range out {
		if r >= 'A' && r <= 'Z' {
			out[i] = r + ('a' - 'A')
			continue
		}
		// Latin-1 uppercase letters sit a fixed distance above their lowercase
		// forms, and Å Ä Ö are the ones that actually turn up.
		if folded, ok := upperAccentFold[r]; ok {
			out[i] = folded
		}
	}
	return string(out)
}

// upperAccentFold maps uppercase accented letters to lowercase, so the folding
// table above only needs one entry per letter.
var upperAccentFold = map[rune]rune{
	'À': 'à', 'Á': 'á', 'Â': 'â', 'Ã': 'ã', 'Ä': 'ä', 'Å': 'å',
	'Ç': 'ç', 'È': 'è', 'É': 'é', 'Ê': 'ê', 'Ë': 'ë',
	'Ì': 'ì', 'Í': 'í', 'Î': 'î', 'Ï': 'ï', 'Ñ': 'ñ',
	'Ò': 'ò', 'Ó': 'ó', 'Ô': 'ô', 'Õ': 'õ', 'Ö': 'ö', 'Ø': 'ø',
	'Ù': 'ù', 'Ú': 'ú', 'Û': 'û', 'Ü': 'ü', 'Ý': 'ý',
}

func indexByte(s string, b byte) int {
	for i := 0; i < len(s); i++ {
		if s[i] == b {
			return i
		}
	}
	return -1
}

// ReserveInvite checks an invite code and consumes one use of it.
//
// Consuming before the account exists is deliberate: two people finishing sign-up
// at the same moment must not both take the last use of a one-use link. The cost is
// that a failure *after* this point has to give the use back, which is what
// ReleaseInvite is for — every path below that can fail calls it.
//
// `claimedBy` is the account the use is being held for. It is recorded in
// RedeemedBy so the invite's own bookkeeping says who used it, and an empty value is
// accepted because the account does not exist yet.
func (b *base) ReserveInvite(rawCode, claimedBy string) (*store.Invite, error) {
	code := parseInviteCode(rawCode)
	if code == "" {
		return nil, errInvalid("an invitation is required to create an account")
	}
	inv, err := b.st.InviteByCode(code)
	if err != nil {
		return nil, errInvalid("that invitation does not exist")
	}
	if reason := inviteInvalidReason(inv); reason != "" {
		return nil, errInvalid("this invitation is " + reason)
	}
	reserved, err := b.st.UpdateInvite(code, func(i *store.Invite) {
		i.Uses++
		if claimedBy != "" {
			i.RedeemedBy = append([]string{claimedBy}, i.RedeemedBy...)
		}
	})
	if err != nil {
		return nil, err
	}
	// Re-check after incrementing: two concurrent redemptions of a one-use link
	// could both have passed the check above, and only one may win.
	if reserved.MaxUses > 0 && reserved.Uses > reserved.MaxUses {
		b.ReleaseInvite(code, claimedBy)
		return nil, errInvalid("this invitation is exhausted")
	}
	return reserved, nil
}

// ReleaseInvite gives back a reserved use. Best effort: it is only called on paths
// that are already failing, and turning "the username is taken" into "the username
// is taken and something else went wrong" helps nobody.
func (b *base) ReleaseInvite(code, claimedBy string) {
	if code == "" {
		return
	}
	_, _ = b.st.UpdateInvite(code, func(i *store.Invite) {
		if i.Uses > 0 {
			i.Uses--
		}
		if claimedBy != "" {
			kept := i.RedeemedBy[:0]
			for _, id := range i.RedeemedBy {
				if id != claimedBy {
					kept = append(kept, id)
				}
			}
			i.RedeemedBy = kept
		}
	})
}

// CompleteInvite records the inviter relationship and the contact the invitation
// promised, once the account exists.
func (b *base) CompleteInvite(inv *store.Invite, newUserID string) error {
	if inv == nil || inv.InviterID == "" {
		return nil
	}
	inviter, err := b.st.UserByID(inv.InviterID)
	if err != nil {
		return err
	}
	if err := b.st.AddContact(newUserID, inviter.ID, now()); err != nil {
		return err
	}
	c, _, err := b.findDirect(newUserID, inviter.ID)
	if err != nil {
		return err
	}
	b.broadcastContact("added", inviter.ID, newUserID, c.ID)
	b.broadcastContact("added", newUserID, inviter.ID, c.ID)
	b.broadcastConversationCreated(c, newUserID)
	b.broadcastConversationCreated(c, inviter.ID)
	return nil
}

// LinkGoogleIdentity attaches a verified Google identity to an existing account.
//
// Separate from signing in because the trust is different. Signing in answers "who is
// this?"; linking has to answer "may this person add this identity to *that*
// account?" — and the person is already authenticated, so the only new question is
// whether the identity is spoken for.
//
// The one refusal that matters: an identity already linked elsewhere is never moved.
// Re-pointing it would mean that signing in with Google could take over whichever
// account happened to be in the URL, so it is an error the person can read instead.
func (b *base) LinkGoogleIdentity(ctx context.Context, userID string, id *googleid.Identity) error {
	if id == nil || id.Subject == "" {
		return errInvalid("that sign-in is missing an identity")
	}
	user, err := b.st.UserByID(userID)
	if err != nil {
		return errInvalid("this account no longer exists")
	}

	existing, err := b.st.OAuthIdentityBySubject("google", id.Subject)
	switch {
	case err == nil && existing.UserID == user.ID:
		// Already linked to this very account. Idempotent: connecting twice is not an
		// error, and saying so beats a message about a conflict that is not one.
		return nil
	case err == nil:
		// Linked to somebody else. Refused, and the message deliberately does not say
		// whose account it is: that would confirm an account exists to anyone who can
		// sign in with that Google identity.
		return errInvalid("that Google account is already connected to a different Ratatosk account")
	case err != store.ErrNotFound:
		return err
	}

	// The identity is free, so attach it.
	now := now()
	if err := b.st.PutOAuthIdentity(&store.OAuthIdentity{
		UserID: user.ID, Provider: "google", Subject: id.Subject,
		Email: id.Email, EmailVerified: id.EmailVerified, Name: id.Name,
		CreatedAt: now, LastLogin: now,
	}); err != nil {
		return err
	}
	b.log.Info("google account connected", "user", user.ID, "username", user.Username)
	return nil
}

// IssueOAuthTicket mints a single-use ticket for one redirect on this account's
// behalf.
//
// The equivalent of the app's session, scoped to one navigation: the browser cannot
// send a bearer token, so this is what identifies the account when it arrives.
func (b *base) IssueOAuthTicket(userID, purpose string) (string, error) {
	now := now()
	ticket := &store.OAuthTicket{
		Token:     ids.Token() + ids.Token(),
		UserID:    userID,
		Purpose:   purpose,
		CreatedAt: now,
		ExpiresAt: now.Add(5 * time.Minute),
	}
	if err := b.st.PutOAuthTicket(ticket); err != nil {
		return "", err
	}
	return ticket.Token, nil
}

// UnlinkGoogleIdentity removes a linked Google identity.
//
// Refused when it is the account's *only* way in: an account with no password and no
// linked identity could never be signed into again, and that is a support request
// nobody can resolve. The check is here rather than in the client because the client
// is not what makes it true.
func (b *base) UnlinkGoogleIdentity(ctx context.Context, userID string) error {
	user, err := b.st.UserByID(userID)
	if err != nil {
		return errInvalid("this account no longer exists")
	}
	links := b.st.OAuthIdentitiesOf(user.ID)
	if len(links) == 0 {
		return errInvalid("no Google account is connected")
	}
	if user.PasswordHash == "" {
		return errInvalid("set a password first: Google is the only way into this account")
	}
	if err := b.st.DeleteOAuthIdentity(user.ID, "google"); err != nil {
		return err
	}
	b.log.Info("google account disconnected", "user", user.ID, "username", user.Username)
	return nil
}
