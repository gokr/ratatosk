-- +goose Up
-- One encrypted key backup per account.
--
-- The server stores this and cannot read it: the blob is sealed with a key
-- derived from a passphrase the user chose, and the passphrase never leaves the
-- device. It is what lets a new device open history the user already had — the
-- private keys are otherwise only ever in one device's keystore, so reinstalling
-- the app loses them for good.
--
-- The KDF parameters travel with the blob rather than being hard-coded on the
-- server: a backup made on an old client must stay readable after the defaults
-- are raised, so the values used to create it are what restore it.
CREATE TABLE key_backups (id TEXT PRIMARY KEY, owner TEXT NOT NULL, payload BLOB NOT NULL);
CREATE INDEX key_backups_owner ON key_backups(owner);

-- +goose Down
DROP TABLE key_backups;
