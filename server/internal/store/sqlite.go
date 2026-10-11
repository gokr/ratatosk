package store

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"database/sql"
	"embed"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/pressly/goose/v3"
	_ "modernc.org/sqlite"
)

//go:embed migrations/*.sql
var migrations embed.FS

type querier interface {
	Exec(string, ...any) (sql.Result, error)
	Query(string, ...any) (*sql.Rows, error)
	QueryRow(string, ...any) *sql.Row
}

// must is used only by legacy APIs whose signatures have no error result.
// Storage failure must fail closed, never acknowledge a non-durable mutation.
func must(err error) {
	if err != nil {
		panic(fmt.Errorf("store: persistence failure: %w", err))
	}
}

func (s *Store) digest(domain, value string) string {
	h := hmac.New(sha256.New, s.dataKeyValue)
	h.Write([]byte("ratatosk/sqlite/v1/" + domain + "\x00" + value))
	return hex.EncodeToString(h.Sum(nil))
}
func (s *Store) rowID(table, id string) string { return s.digest(table, id) }

// Row identity is included inside the authenticated ciphertext. Copying a
// ciphertext into another table or row cannot silently substitute its value.
func (s *Store) encodeRow(table, id string, value any) ([]byte, error) {
	raw, err := json.Marshal(struct {
		Table, ID string
		Value     any
	}{table, id, value})
	if err != nil {
		return nil, err
	}
	return s.sealSnapshot(raw)
}
func (s *Store) decodeRow(table, hash string, raw []byte, value any) error {
	plain, err := s.unsealSnapshot(raw)
	if err != nil {
		return err
	}
	var row struct {
		Table, ID string
		Value     json.RawMessage
	}
	if err = json.Unmarshal(plain, &row); err != nil {
		return err
	}
	if row.Table != table || s.rowID(table, row.ID) != hash {
		return errors.New("store: encrypted row identity mismatch")
	}
	return json.Unmarshal(row.Value, value)
}
func getRow[T any](s *Store, q querier, table, id string) (*T, error) {
	return getHash[T](s, q, table, s.rowID(table, id))
}
func getHash[T any](s *Store, q querier, table, hash string) (*T, error) {
	var raw []byte
	if err := q.QueryRow("SELECT payload FROM "+table+" WHERE id=?", hash).Scan(&raw); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	var out T
	if err := s.decodeRow(table, hash, raw, &out); err != nil {
		return nil, err
	}
	return &out, nil
}
func listRows[T any](s *Store, q querier, table, where string, args ...any) ([]*T, error) {
	rows, err := q.Query("SELECT id,payload FROM "+table+" "+where, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := make([]*T, 0)
	for rows.Next() {
		var id string
		var raw []byte
		if err = rows.Scan(&id, &raw); err != nil {
			return nil, err
		}
		var v T
		if err = s.decodeRow(table, id, raw, &v); err != nil {
			return nil, err
		}
		out = append(out, &v)
	}
	return out, rows.Err()
}
func (s *Store) put(q querier, table, id string, value any, columns []string, values ...any) error {
	raw, err := s.encodeRow(table, id, value)
	if err != nil {
		return err
	}
	names := append([]string{"id", "payload"}, columns...)
	vals := append([]any{s.rowID(table, id), raw}, values...)
	placeholders := make([]string, len(names))
	updates := make([]string, 0, len(names)-1)
	for i, n := range names {
		placeholders[i] = "?"
		if i > 0 {
			updates = append(updates, n+"=excluded."+n)
		}
	}
	_, err = q.Exec("INSERT INTO "+table+"("+strings.Join(names, ",")+") VALUES("+strings.Join(placeholders, ",")+") ON CONFLICT(id) DO UPDATE SET "+strings.Join(updates, ","), vals...)
	return err
}
func (s *Store) remove(q querier, table, id string) error {
	_, err := q.Exec("DELETE FROM "+table+" WHERE id=?", s.rowID(table, id))
	return err
}
func (s *Store) write(fn func(*sql.Tx) error) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	tx, err := s.sql.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if err = fn(tx); err != nil {
		return err
	}
	return tx.Commit()
}

func (s *Store) openSQLite() error {
	path := filepath.Join(s.dir, databaseName)
	// Do not replace a lost key for an existing encrypted database or snapshot.
	if os.Getenv(dataKeyEnvVar) == "" {
		if _, err := os.Stat(filepath.Join(s.dir, dataKeyFile)); errors.Is(err, os.ErrNotExist) {
			for _, name := range []string{databaseName, snapshotName} {
				raw, e := os.ReadFile(filepath.Join(s.dir, name))
				if e == nil && (name == databaseName || strings.HasPrefix(string(raw), snapshotMagic)) {
					return ErrNoDataKey
				}
				if e != nil && !errors.Is(e, os.ErrNotExist) {
					return e
				}
			}
		}
	}
	if _, err := s.dataKey(); err != nil {
		return err
	}
	// Precreate privately, so SQLite and its WAL never inherit world permissions.
	f, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0600)
	if err != nil {
		return err
	}
	if err = f.Close(); err != nil {
		return err
	}
	if err = os.Chmod(path, 0600); err != nil {
		return err
	}
	// _txlock=immediate serializes read-modify-write across processes, not just
	// goroutines. Every pooled connection gets these PRAGMAs.
	dsn, err := sqliteURI(path)
	if err != nil {
		return err
	}
	s.sql, err = sql.Open("sqlite", dsn)
	if err != nil {
		return err
	}
	s.sql.SetMaxOpenConns(1)
	// Verify the key BEFORE any migration can write. A wrong key must be a
	// startup failure, not a half-migrated database over the real one.
	if err = s.checkExistingKey(s.sql); err != nil {
		return err
	}
	fs, err := subMigrations()
	if err != nil {
		return err
	}
	provider, err := goose.NewProvider(goose.DialectSQLite3, s.sql, fs)
	if err != nil {
		return err
	}
	if _, err = provider.Up(context.Background()); err != nil {
		return fmt.Errorf("store: migrations: %w", err)
	}
	return s.write(func(tx *sql.Tx) error {
		var check []byte
		err := tx.QueryRow("SELECT value FROM metadata WHERE key='key-check'").Scan(&check)
		if err == nil {
			plain, e := s.unsealSnapshot(check)
			if e != nil {
				return e
			}
			if string(plain) != sqliteKeyCheck {
				return errors.New("store: invalid key check")
			}
			var imported string
			e = tx.QueryRow("SELECT CAST(value AS TEXT) FROM metadata WHERE key='legacy-import'").Scan(&imported)
			if e != nil {
				return fmt.Errorf("store: missing import marker: %w", e)
			}
			return nil
		}
		if !errors.Is(err, sql.ErrNoRows) {
			return err
		}
		// A database missing its key check is only fresh if it has no data.
		for _, table := range rowTables {
			var n int
			if err = tx.QueryRow("SELECT count(*) FROM " + table).Scan(&n); err != nil {
				return err
			}
			if n != 0 {
				return errors.New("store: rows exist without key check; refusing empty initialization")
			}
		}
		if err = s.importLegacy(tx); err != nil {
			return err
		}
		check, err = s.sealSnapshot([]byte(sqliteKeyCheck))
		if err != nil {
			return err
		}
		_, err = tx.Exec("INSERT INTO metadata(key,value) VALUES('key-check',?),('legacy-import','complete')", check)
		return err
	})
}
