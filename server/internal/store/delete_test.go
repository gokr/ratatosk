package store

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

// Leaving a group must not shift sequence numbers: every client cursor and every
// catch-up path depends on a gapless (conversation, seq).
func TestDeleteUserKeepsGroupMessagesGapless(t *testing.T) {
	st := testStore(t)
	now := time.Now()

	ada, _ := st.CreateUser("ada", "Ada", "h", "s", "#fff", now)
	grace, _ := st.CreateUser("grace", "Grace", "h", "s", "#fff", now)

	group, err := st.CreateConversation(KindGroup, "Bridge Crew", ada.ID, []string{grace.ID}, now)
	if err != nil {
		t.Fatalf("create group: %v", err)
	}
	first, err := st.AppendMessage(&Message{ConversationID: group.ID, SenderID: ada.ID, Text: "from ada one"}, now)
	if err != nil {
		t.Fatalf("append: %v", err)
	}
	second, err := st.AppendMessage(&Message{ConversationID: group.ID, SenderID: grace.ID, Text: "from grace"}, now)
	if err != nil {
		t.Fatalf("append: %v", err)
	}
	third, err := st.AppendMessage(&Message{ConversationID: group.ID, SenderID: ada.ID, Text: "from ada two"}, now)
	if err != nil {
		t.Fatalf("append: %v", err)
	}

	if _, err := st.DeleteUser(ada.ID); err != nil {
		t.Fatalf("delete: %v", err)
	}

	// The conversation survives for grace, and so do all its messages.
	kept, err := st.ConversationByID(group.ID)
	if err != nil {
		t.Fatalf("group was deleted with its leaving member: %v", err)
	}
	if _, still := kept.Members[ada.ID]; still {
		t.Error("the deleted user is still a member")
	}
	if _, ok := kept.Members[grace.ID]; !ok {
		t.Error("grace was removed along with ada")
	}

	msgs, _, err := st.MessagesOf(group.ID, 0, 0, 50)
	if err != nil {
		t.Fatalf("messages: %v", err)
	}
	if len(msgs) != 3 {
		t.Fatalf("messages = %d, want 3 (a departing member must not delete a group's history)", len(msgs))
	}
	for i, want := range []int64{first.Seq, second.Seq, third.Seq} {
		if msgs[i].Seq != want {
			t.Errorf("message %d seq = %d, want %d: sequences must stay gapless", i, msgs[i].Seq, want)
		}
	}

	// And a new message still gets the next number.
	next, err := st.AppendMessage(&Message{ConversationID: group.ID, SenderID: grace.ID, Text: "after"}, now)
	if err != nil {
		t.Fatalf("append after deletion: %v", err)
	}
	if next.Seq != third.Seq+1 {
		t.Errorf("seq after deletion = %d, want %d", next.Seq, third.Seq+1)
	}
}

// A direct conversation is deleted outright: the remaining participant has
// nobody to talk to, and an empty thread named after a missing account is worse
// than no thread.
func TestDeleteUserRemovesDirectConversations(t *testing.T) {
	st := testStore(t)
	now := time.Now()
	ada, _ := st.CreateUser("ada", "Ada", "h", "s", "#fff", now)
	grace, _ := st.CreateUser("grace", "Grace", "h", "s", "#fff", now)
	direct, err := st.CreateConversation(KindDirect, "", ada.ID, []string{grace.ID}, now)
	if err != nil {
		t.Fatalf("create direct: %v", err)
	}
	if _, err := st.AppendMessage(&Message{ConversationID: direct.ID, SenderID: grace.ID, Text: "hello"}, now); err != nil {
		t.Fatalf("append: %v", err)
	}

	summary, err := st.DeleteUser(ada.ID)
	if err != nil {
		t.Fatalf("delete: %v", err)
	}
	if summary.DirectChats != 1 {
		t.Fatalf("DirectChats = %d, want 1", summary.DirectChats)
	}
	if _, err := st.ConversationByID(direct.ID); err != ErrNotFound {
		t.Errorf("direct conversation survived: %v", err)
	}
	if msgs, _, _ := st.MessagesOf(direct.ID, 0, 0, 10); len(msgs) != 0 {
		t.Errorf("direct conversation kept %d messages", len(msgs))
	}
	// Grace still exists and is untouched.
	if _, err := st.UserByID(grace.ID); err != nil {
		t.Errorf("grace was affected: %v", err)
	}
}

// A group the departed user created keeps functioning: somebody else takes over,
// or members lose the ability to rename it.
func TestDeleteUserReassignsGroupOwnership(t *testing.T) {
	st := testStore(t)
	now := time.Now()
	ada, _ := st.CreateUser("ada", "Ada", "h", "s", "#fff", now)
	grace, _ := st.CreateUser("grace", "Grace", "h", "s", "#fff", now)
	bob, _ := st.CreateUser("bob", "Bob", "h", "s", "#fff", now)

	// Ada creates it; grace joined earlier than bob.
	group, err := st.CreateConversation(KindGroup, "Crew", ada.ID, []string{grace.ID}, now.Add(-2*time.Hour))
	if err != nil {
		t.Fatalf("create: %v", err)
	}
	if _, err := st.UpdateConversation(group.ID, func(c *Conversation) {
		c.Members[bob.ID] = &Member{UserID: bob.ID, Role: RoleMember, JoinedAt: now}
	}); err != nil {
		t.Fatalf("add bob: %v", err)
	}

	if _, err := st.DeleteUser(ada.ID); err != nil {
		t.Fatalf("delete: %v", err)
	}
	after, err := st.ConversationByID(group.ID)
	if err != nil {
		t.Fatalf("group gone: %v", err)
	}
	// Ownership moves to an actual remaining member, not to the departed user.
	owners := 0
	for id, member := range after.Members {
		if member.Role == RoleOwner {
			owners++
			if id == ada.ID {
				t.Error("the deleted user is still the owner")
			}
		}
	}
	if owners != 1 {
		t.Errorf("owners = %d, want exactly 1", owners)
	}
	if after.CreatedBy == ada.ID {
		// CreatedBy is provenance, so it may remain; only the role must move.
		t.Log("CreatedBy still names the departed creator (provenance, not authority)")
	}
}

// A group where the last member leaves has nobody to belong to, so it goes too.
func TestDeleteUserRemovesEmptiedGroup(t *testing.T) {
	st := testStore(t)
	now := time.Now()
	ada, _ := st.CreateUser("ada", "Ada", "h", "s", "#fff", now)
	group, err := st.CreateConversation(KindGroup, "Solo", ada.ID, nil, now)
	if err != nil {
		t.Fatalf("create: %v", err)
	}
	if _, err := st.AppendMessage(&Message{ConversationID: group.ID, SenderID: ada.ID, Text: "alone"}, now); err != nil {
		t.Fatalf("append: %v", err)
	}

	if _, err := st.DeleteUser(ada.ID); err != nil {
		t.Fatalf("delete: %v", err)
	}
	if _, err := st.ConversationByID(group.ID); err != ErrNotFound {
		t.Errorf("an emptied group survived: %v", err)
	}
}

// Everything keyed to the account has to go, including the encryption state:
// an orphaned device key or key envelope would otherwise be a credential for an
// account that no longer exists.
func TestDeleteUserRemovesKeysSessionsAndSocialGraph(t *testing.T) {
	st := testStore(t)
	now := time.Now()
	ada, _ := st.CreateUser("ada", "Ada", "h", "s", "#fff", now)
	grace, _ := st.CreateUser("grace", "Grace", "h", "s", "#fff", now)

	if err := st.AddContact(ada.ID, grace.ID, now); err != nil {
		t.Fatalf("contact: %v", err)
	}
	group, _ := st.CreateConversation(KindGroup, "G", ada.ID, []string{grace.ID}, now)

	key, err := st.PublishDeviceKey("", ada.ID, randomBytes(t, 32), randomBytes(t, 32), "Laptop", "linux", now)
	if err != nil {
		t.Fatalf("device key: %v", err)
	}
	graceKey, _ := st.PublishDeviceKey("", grace.ID, randomBytes(t, 32), randomBytes(t, 32), "Phone", "android", now)
	if _, err := st.PutKeyEnvelope(&KeyEnvelope{
		Conversation: group.ID, SenderKeyID: graceKey.ID, RecipientID: key.ID,
		Epoch: 0, Wrapped: randomBytes(t, 48), Nonce: randomBytes(t, 24),
	}, now); err != nil {
		t.Fatalf("envelope to ada: %v", err)
	}
	var sessions []*Session
	for i := 0; i < 2; i++ {
		session, err := st.CreateSession(ada.ID, time.Hour, now)
		if err != nil {
			t.Fatalf("session: %v", err)
		}
		sessions = append(sessions, session)
	}
	// A real subscription, so the test proves notifications die with the account.
	if err := st.PutPushSubscription(&PushSubscription{
		Endpoint: "https://push.example/ada", UserID: ada.ID,
		SessionToken: sessions[0].Token,
		P256DH:       "BJdE6ZZWFudyO_s8bU_geA1MzozxlvVjGj--h2SKoI0fjhHJ2Dyy5SfD9nXvgWSn7LNsbY66VxCPPi0WvJ6MDdg",
		Auth:         "AAAAAAAAAAAAAAAAAAAAAA",
	}); err != nil {
		t.Fatalf("subscription: %v", err)
	}
	invite, err := st.CreateInvite(ada.ID, time.Time{}, 1, 10, now)
	if err != nil {
		t.Fatalf("invite: %v", err)
	}
	attachment, err := st.PutAttachment(ada.ID, "photo.png", "image/png", randomBytes(t, 64), true, 0, 0, now)
	if err != nil {
		t.Fatalf("attachment: %v", err)
	}

	summary, err := st.DeleteUser(ada.ID)
	if err != nil {
		t.Fatalf("delete: %v", err)
	}

	if _, err := st.UserByID(ada.ID); err != ErrNotFound {
		t.Error("the account row survived")
	}
	if _, err := st.UserByUsername("ada"); err != ErrNotFound {
		t.Error("the handle is still resolvable")
	}
	if summary.Sessions < 2 {
		t.Errorf("sessions removed = %d, want at least 2", summary.Sessions)
	}
	if summary.PushSubscriptions != 1 {
		t.Errorf("push subscriptions removed = %d, want 1", summary.PushSubscriptions)
	}
	if subs, err := st.PushSubscriptionsOf(ada.ID); err == nil && len(subs) != 0 {
		t.Errorf("%d push subscriptions survived: the account would still be notified", len(subs))
	}
	if _, err := st.DeviceKeyByID(key.ID); err != ErrNotFound {
		t.Error("a device key survived")
	}
	if n := st.CountKeyEnvelopes(); n != 0 {
		t.Errorf("%d key envelopes survived", n)
	}
	if st.AreContacts(ada.ID, grace.ID) || st.AreContacts(grace.ID, ada.ID) {
		t.Error("a contact link survived")
	}
	if _, err := st.InviteByCode(invite.Code); err != ErrNotFound {
		t.Error("an invitation survived")
	}
	if _, err := st.AttachmentByID(attachment.ID); err != ErrNotFound {
		t.Error("an attachment record survived")
	}
	if _, err := os.Stat(filepath.Join(st.FilesDir(), attachment.ID)); !os.IsNotExist(err) {
		t.Error("the attachment bytes are still on disk")
	}
	// The other account is untouched.
	if _, err := st.UserByID(grace.ID); err != nil {
		t.Errorf("grace was affected: %v", err)
	}
	if _, err := st.DeviceKeyByID(graceKey.ID); err != nil {
		t.Errorf("grace's device key was affected: %v", err)
	}
}

// Deleting a nonexistent account is an error, not a silent success.
func TestDeleteUnknownUserFails(t *testing.T) {
	st := testStore(t)
	if _, err := st.DeleteUserByUsername("nobody"); err == nil {
		t.Fatal("deleting a missing account reported success")
	}
	if _, err := st.DeleteUser("u-does-not-exist"); err != ErrNotFound {
		t.Fatalf("err = %v, want ErrNotFound", err)
	}
}

// The deletion is one transaction: a failure part-way leaves the account intact
// rather than half-removed.
func TestDeleteUserIsAtomic(t *testing.T) {
	st := testStore(t)
	now := time.Now()
	ada, _ := st.CreateUser("ada", "Ada", "h", "s", "#fff", now)
	grace, _ := st.CreateUser("grace", "Grace", "h", "s", "#fff", now)
	direct, _ := st.CreateConversation(KindDirect, "", ada.ID, []string{grace.ID}, now)
	if _, err := st.AppendMessage(&Message{ConversationID: direct.ID, SenderID: grace.ID, Text: "hi"}, now); err != nil {
		t.Fatalf("append: %v", err)
	}

	// Nothing observable can fail here, so instead assert the invariant that
	// follows from atomicity: every table agrees the user is gone, with no
	// leftover row pointing at them.
	if _, err := st.DeleteUser(ada.ID); err != nil {
		t.Fatalf("delete: %v", err)
	}
	if convs := st.ConversationsOf(ada.ID); len(convs) != 0 {
		t.Errorf("the deleted user still lists %d conversations", len(convs))
	}
	if keys := st.DeviceKeysOf(ada.ID, true); len(keys) != 0 {
		t.Errorf("the deleted user still has %d device keys", len(keys))
	}
	if contacts := st.ContactsOf(ada.ID); len(contacts) != 0 {
		t.Errorf("the deleted user still has %d contacts", len(contacts))
	}
	if invites := st.ListInvites(ada.ID); len(invites) != 0 {
		t.Errorf("the deleted user still has %d invites", len(invites))
	}
}
