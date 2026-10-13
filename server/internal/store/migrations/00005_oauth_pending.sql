-- +goose Up
-- A verified Google identity waiting for the rest of sign-up.
--
-- The provider confirms who somebody is during the redirect, but an account is only
-- created once they have proved an invitation and chosen a username. Keeping the
-- verified identity here rather than handing it back to the browser means the page
-- between the two steps cannot be forged into an account. Tokens are single-use and
-- short-lived.
CREATE TABLE oauth_pending (id TEXT PRIMARY KEY, payload BLOB NOT NULL);

-- +goose Down
DROP TABLE oauth_pending;
