-- +goose Up
-- A single-use ticket authorizing one browser redirect on behalf of an account.
--
-- A redirect cannot carry a bearer token: the browser issues a fresh GET with no
-- Authorization header, so an endpoint reached by navigation has no way to know who
-- is asking. The app therefore trades its session for a short-lived opaque ticket —
-- over an authenticated RPC — and puts that in the URL instead. Single-use, so a
-- ticket copied out of a URL or a history entry cannot be replayed.
CREATE TABLE oauth_tickets (id TEXT PRIMARY KEY, owner TEXT NOT NULL, payload BLOB NOT NULL);
CREATE INDEX oauth_tickets_owner ON oauth_tickets(owner);

-- +goose Down
DROP TABLE oauth_tickets;
