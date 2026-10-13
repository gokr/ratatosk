-- +goose Up
-- External sign-in links (Google), one row per (provider, subject).
--
-- `provider` and `subject` are columns rather than only part of the payload so a
-- unique link per provider identity is enforced by the primary key. The `sub`
-- claim is the identity, not the email: an email can be changed or reassigned on
-- the provider's side, which is exactly how social logins get taken over.
CREATE TABLE oauth_identities (id TEXT PRIMARY KEY, owner TEXT NOT NULL, provider TEXT NOT NULL, subject TEXT NOT NULL, payload BLOB NOT NULL);
CREATE INDEX oauth_identities_owner ON oauth_identities(owner);

-- +goose Down
DROP TABLE oauth_identities;
