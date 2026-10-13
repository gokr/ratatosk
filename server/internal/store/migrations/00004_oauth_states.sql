-- +goose Up
-- A pending sign-in redirect, held server-side.
--
-- The browser carries only the opaque `state` string; PKCE's verifier stays here.
-- That matters because the verifier is the part that proves the client exchanging
-- the authorization code is the one that started the flow, and keeping it out of
-- the URL and out of any cookie means it cannot be lifted from browser history.
-- Rows are deleted the moment they are read, so a callback is single-use.
CREATE TABLE oauth_states (id TEXT PRIMARY KEY, payload BLOB NOT NULL);

-- +goose Down
DROP TABLE oauth_states;
