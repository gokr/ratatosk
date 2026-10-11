package store

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/gokr/ratatosk/server/internal/ids"
)

// PutAttachment writes the bytes to disk and records their metadata. The file
// is written before the record, so a crash between the two leaves an orphan
// file rather than a record pointing at nothing.
//
// When `encrypted` is set the bytes are a client-side seal: the server stores
// them as received and records no filename or content type, because it has
// none it can trust. The real values travel inside the message envelope.
func (s *Store) PutAttachment(ownerID, filename, contentType string, data []byte, encrypted bool, width, height int, now time.Time) (*Attachment, error) {
	if _, err := s.UserByID(ownerID); err != nil {
		if err == ErrNotFound {
			return nil, ErrUnknownUser
		}
		return nil, err
	}

	storedName := ""
	if !encrypted {
		storedName = filepath.Base(filename)
	}
	att := &Attachment{
		ID:          ids.New("f"),
		OwnerID:     ownerID,
		Filename:    storedName,
		ContentType: contentType,
		Size:        int64(len(data)),
		Encrypted:   encrypted,
		Width:       width,
		Height:      height,
		CreatedAt:   now,
	}
	path := s.AttachmentPath(att.ID)
	if err := os.WriteFile(path, data, 0o644); err != nil {
		return nil, fmt.Errorf("store: write attachment: %w", err)
	}

	if err := s.write(func(tx *sql.Tx) error { return s.put(tx, "attachments", att.ID, att, nil) }); err != nil {
		return nil, err
	}
	return cloneAttachment(att), nil
}

// AttachmentByID returns a copy of an attachment's metadata.
func (s *Store) AttachmentByID(id string) (*Attachment, error) {
	return getRow[Attachment](s, s.sql, "attachments", id)
}

// AttachmentsByIDs returns metadata for the named attachments, skipping
// unknown ids, in the order given.
func (s *Store) AttachmentsByIDs(ids []string) []*Attachment {
	out := make([]*Attachment, 0, len(ids))
	for _, id := range ids {
		a, err := s.AttachmentByID(id)
		if err == ErrNotFound {
			continue
		}
		must(err)
		out = append(out, a)
	}
	return out
}
