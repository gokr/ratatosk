package store

import (
	"database/sql"
	"fmt"
	"os"

	"github.com/gokr/ratatosk/server/internal/ids"
)

// DeletionSummary reports what removing an account actually removed, so an
// operator can see the blast radius instead of trusting that it worked.
type DeletionSummary struct {
	Username          string
	UserID            string
	Sessions          int
	DeviceKeys        int
	KeyEnvelopes      int
	Contacts          int
	Invites           int
	Attachments       int
	PushSubscriptions int
	DirectChats       int
	GroupMemberships  int
	Messages          int
}

// DeleteUser removes an account and everything that belongs to it.
//
// Two deliberate choices, because "delete the user" has more than one honest
// answer:
//
//   - A **direct** conversation the user was part of is deleted outright, along
//     with its messages. The other participant is left with nothing to talk to,
//     and an empty thread named after somebody who no longer exists is worse
//     than no thread.
//   - A **group** conversation is kept and the user is removed from its member
//     list. Their messages stay in place: this store keeps messages gapless, and
//     deleting rows from the middle of a conversation would shift every later
//     sequence number, breaking every client's cursor. Those messages remain
//     sealed and readable by the members who already had the key; a reader who
//     never resolved the sender will show an unknown name, which is the correct
//     outcome for a departed account.
//
// Uploaded files are the one thing that cannot be undone by a rollback, so they
// are removed only after the transaction has committed.
func (s *Store) DeleteUser(userID string) (summary DeletionSummary, err error) {
	var attachmentIDs []string
	err = s.write(func(tx *sql.Tx) error {
		user, err := getRow[User](s, tx, "users", userID)
		if err != nil {
			return err
		}
		summary.Username = user.Username
		summary.UserID = user.ID

		owner := s.rowID("users", userID)

		// --- sessions, and the push subscriptions bound to them ---
		sessions, err := listRows[Session](s, tx, "sessions", "WHERE owner=?", owner)
		if err != nil {
			return err
		}
		// Count the account's push subscriptions first: deleting a session also
		// removes the subscriptions bound to it, so counting afterwards would
		// always report zero and the operator would never see that notifications
		// stop.
		if err := tx.QueryRow("SELECT count(*) FROM push_subscriptions WHERE owner=?", owner).Scan(&summary.PushSubscriptions); err != nil {
			return err
		}
		for _, session := range sessions {
			// deleteSession also drops that session's subscriptions.
			if err := s.deleteSession(tx, session.Token); err != nil {
				return err
			}
			summary.Sessions++
		}
		// Anything left over: a subscription whose session the server had already
		// forgotten still names this account.
		if _, err := tx.Exec("DELETE FROM push_subscriptions WHERE owner=?", owner); err != nil {
			return err
		}

		// --- direct conversations: deleted whole ---
		convs, err := listRows[Conversation](s, tx, "conversations",
			"WHERE id IN (SELECT conversation FROM memberships WHERE owner=?)", owner)
		if err != nil {
			return err
		}
		for _, conv := range convs {
			if conv.Kind != KindDirect {
				continue
			}
			convRow := s.rowID("conversations", conv.ID)
			res, err := tx.Exec("DELETE FROM messages WHERE conversation=?", convRow)
			if err != nil {
				return err
			}
			if n, err := res.RowsAffected(); err == nil {
				summary.Messages += int(n)
			}
			if _, err := tx.Exec("DELETE FROM memberships WHERE conversation=?", convRow); err != nil {
				return err
			}
			if err := s.remove(tx, "conversations", conv.ID); err != nil {
				return err
			}
			summary.DirectChats++
		}

		// --- groups: membership only, messages stay gapless ---
		res, err := tx.Exec("DELETE FROM memberships WHERE owner=?", owner)
		if err != nil {
			return err
		}
		if n, err := res.RowsAffected(); err == nil {
			summary.GroupMemberships = int(n)
		}
		// A group the user created keeps its conversation row; ownership is
		// presentation state, and the remaining members should not lose the
		// thread because its creator left. Reassign to the oldest remaining
		// member so the group still has an owner who can rename it.
		for _, conv := range convs {
			if conv.Kind != KindGroup || conv.CreatedBy != userID {
				continue
			}
			if err := reassignOwnership(s, tx, conv, userID); err != nil {
				return err
			}
		}

		// --- the rest of the account's own rows ---
		res, err = tx.Exec("DELETE FROM contacts WHERE owner=? OR peer=?", owner, owner)
		if err != nil {
			return err
		} else if n, err := res.RowsAffected(); err == nil {
			summary.Contacts = int(n)
		}
		if res, err = tx.Exec("DELETE FROM invites WHERE owner=?", owner); err != nil {
			return err
		} else if n, err := res.RowsAffected(); err == nil {
			summary.Invites = int(n)
		}

		keys, err := listRows[DeviceKey](s, tx, "device_keys", "WHERE owner=?", owner)
		if err != nil {
			return err
		}
		for _, key := range keys {
			keyRow := s.rowID("device_keys", key.ID)
			if res, err = tx.Exec("DELETE FROM key_envelopes WHERE recipient=? OR sender=?", keyRow, keyRow); err != nil {
				return err
			} else if n, err := res.RowsAffected(); err == nil {
				summary.KeyEnvelopes += int(n)
			}
			if err := s.remove(tx, "device_keys", key.ID); err != nil {
				return err
			}
			summary.DeviceKeys++
		}

		// Attachments have no owner column: ownership is inside the sealed
		// payload, so this scans and decodes rather than filtering in SQL. That
		// is slower than an indexed lookup but it is the only way to do it
		// without a plaintext owner column, and deletion is a rare operation.
		attachments, err := listRows[Attachment](s, tx, "attachments", "")
		if err != nil {
			return err
		}
		for _, attachment := range attachments {
			if attachment.OwnerID != userID {
				continue
			}
			if err := s.remove(tx, "attachments", attachment.ID); err != nil {
				return err
			}
			attachmentIDs = append(attachmentIDs, attachment.ID)
			summary.Attachments++
		}

		return s.remove(tx, "users", userID)
	})
	if err != nil {
		return DeletionSummary{}, err
	}

	// Bytes on disk: best effort, and never a reason to fail the deletion. The
	// records are already gone, so a file left behind is unreachable through the
	// API rather than leaked.
	for _, id := range attachmentIDs {
		_ = os.Remove(s.AttachmentPath(id))
	}
	return summary, nil
}

// reassignOwnership hands a group to its earliest-joined remaining member, so a
// departed creator does not leave a group nobody can administer. A group with no
// members left is deleted with its messages: it has no one to belong to.
func reassignOwnership(s *Store, tx *sql.Tx, conv *Conversation, leaving string) error {
	remaining := make([]*Member, 0, len(conv.Members))
	for id, member := range conv.Members {
		if id != leaving {
			remaining = append(remaining, member)
		}
	}
	convRow := s.rowID("conversations", conv.ID)
	if len(remaining) == 0 {
		if _, err := tx.Exec("DELETE FROM messages WHERE conversation=?", convRow); err != nil {
			return err
		}
		if _, err := tx.Exec("DELETE FROM memberships WHERE conversation=?", convRow); err != nil {
			return err
		}
		return s.remove(tx, "conversations", conv.ID)
	}
	// Oldest membership takes over; ties broken by id so the result is stable.
	next := remaining[0]
	for _, member := range remaining[1:] {
		if member.JoinedAt.Before(next.JoinedAt) ||
			(member.JoinedAt.Equal(next.JoinedAt) && member.UserID < next.UserID) {
			next = member
		}
	}
	delete(conv.Members, leaving)
	for _, member := range conv.Members {
		member.Role = RoleMember
	}
	if owner, ok := conv.Members[next.UserID]; ok {
		owner.Role = RoleOwner
	}
	// Write the conversation and its memberships back in one go.
	delete(conv.Members, leaving)
	return s.saveConversation(tx, conv)
}

// DeleteUserByUsername is the operator entry point: a handle is what a person
// has in hand, and an id is what the database has.
func (s *Store) DeleteUserByUsername(username string) (DeletionSummary, error) {
	user, err := s.UserByUsername(username)
	if err != nil {
		if err == ErrNotFound {
			return DeletionSummary{}, fmt.Errorf("no account named %q", username)
		}
		return DeletionSummary{}, err
	}
	return s.DeleteUser(user.ID)
}

// NewIDForTests exposes the id generator so tests elsewhere can build records.
func NewIDForTests(prefix string) string { return ids.New(prefix) }
