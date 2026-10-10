package store

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/gokr/ratatosk/server/internal/ids"
)

// PutAttachment writes the bytes to disk and records their metadata. The file
// is written before the record, so a crash between the two leaves an orphan
// file rather than a record pointing at nothing.
func (s *Store) PutAttachment(ownerID, filename, contentType string, data []byte, width, height int, now time.Time) (*Attachment, error) {
	s.mu.RLock()
	_, exists := s.db.Users[ownerID]
	s.mu.RUnlock()
	if !exists {
		return nil, ErrUnknownUser
	}

	att := &Attachment{
		ID:          ids.New("f"),
		OwnerID:     ownerID,
		Filename:    filepath.Base(filename),
		ContentType: contentType,
		Size:        int64(len(data)),
		Width:       width,
		Height:      height,
		CreatedAt:   now,
	}
	path := s.AttachmentPath(att.ID)
	if err := os.WriteFile(path, data, 0o644); err != nil {
		return nil, fmt.Errorf("store: write attachment: %w", err)
	}

	s.mu.Lock()
	s.db.Attachments[att.ID] = att
	s.markDirty()
	s.mu.Unlock()
	return cloneAttachment(att), nil
}

// AttachmentByID returns a copy of an attachment's metadata.
func (s *Store) AttachmentByID(id string) (*Attachment, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	a, ok := s.db.Attachments[id]
	if !ok {
		return nil, ErrNotFound
	}
	return cloneAttachment(a), nil
}

// AttachmentsByIDs returns metadata for the named attachments, skipping
// unknown ids, in the order given.
func (s *Store) AttachmentsByIDs(ids []string) []*Attachment {
	s.mu.RLock()
	defer s.mu.RUnlock()
	out := make([]*Attachment, 0, len(ids))
	for _, id := range ids {
		if a, ok := s.db.Attachments[id]; ok {
			out = append(out, cloneAttachment(a))
		}
	}
	return out
}
