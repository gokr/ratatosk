# Protocol

One Protobuf contract in `proto/ratatosk/v1`, four services:

| Service | What it is for |
| --- | --- |
| `AuthService` | accounts, sessions, profile |
| `ChatService` | conversations, messages, the realtime stream |
| `SocialService` | contacts, user search, invitation links |
| `KeyService` | public encryption keys and sealed sender keys (docs/E2EE.md) |

`buf generate` produces connect-go handlers for the server and connect-dart
clients for the app from the same files, so the two sides cannot drift.

## Ordering: `seq`, not time

Every conversation owns a strictly increasing `seq`, assigned by the server on
append, starting at 1 and never skipping. Messages are never deleted, only
tombstoned, so the message list is append-only and index `i` is always
`seq i+1`.

That invariant is what makes the two client operations exact:

- **Scrolling up**: `ListMessages {conversation_id, before_seq, limit}` returns
  the page immediately before a seq.
- **Catching up**: `ListMessages {conversation_id, after_seq, limit}` returns
  everything appended since a seq.

A reconnecting client does not guess what it missed: it asks for everything
after the newest seq it holds. Timestamps are for display only; a clock skew or
a slow write must never lose a message.

## Sending: idempotent by `client_message_id`

Every send carries a client-generated id. A retry with the same id returns the
stored message rather than appending a second one, so a client that reconnects
mid-send cannot double-post. The index is rebuilt from stored messages on
startup, so it survives a restart.

## Realtime

`ChatService.Subscribe` is one server-streaming call carrying every event for
the signed-in user: `hello` (who you are), `message`, `typing`, `read`,
`conversation`, `presence`, `contact`.

- The first frame is `hello`, so a client can render before its first fetch.
- The stream starts at "now": history comes from `ListMessages`, not from the
  stream. A client that connects after a message was sent still gets it, by
  catching up.
- Each connection has a bounded buffer. A client that falls behind is
  disconnected with `RESOURCE_EXHAUSTED` rather than silently losing events;
  it reconnects and catches up, which is correct and cheap.
- Presence is visible only to contacts and conversation partners, so the server
  never confirms whether a stranger is online.

## Push vs pull

| Data | How it reaches the client |
| --- | --- |
| new and changed messages | pushed (`message`) |
| conversation created/removed | pushed (`conversation`) |
| typing | pushed, with a server-side expiry so a crash cannot leave it lit |
| read cursors | pushed (`read`) |
| presence | pushed (`presence`) |
| key envelopes | pulled, when a message cannot be opened yet |

Key envelopes are pulled on purpose: an envelope is useless until a message
references it, so pushing them would leak key-distribution timing without saving
the client any work.

## Attachments

`UploadAttachment` returns an id and a URL. Bytes are fetched from
`GET /files/<id>` with `Authorization: Bearer <token>`, or `?token=` for the
cases where a plain image request cannot set a header.

With end-to-end encryption the uploaded bytes are a client-side seal and the
server knows neither the filename nor the content type; those travel inside the
message envelope. See [E2EE.md](E2EE.md).

## Invitation links

`CreateInvite` mints a code (from a typo-resistant alphabet, excluding `0O1lI2Z5S8B`).
The link is `<public-url>/join/<code>`:

- opened in a browser, it renders a landing page naming the inviter and offering
  both the app (`ratatosk://join/<code>`) and the web app;
- redeemed in the app (`RedeemInvite`), it makes the two accounts contacts and
  opens their conversation.

`PreviewInvite` works without a token, because the landing page has to name the
inviter before anyone signs in. Redeeming is idempotent per person: a single-use
link tapped twice by the same person is not spent twice, and `max_uses: -1`
means unlimited.

## Errors

Connect status codes, with the meanings the client relies on:

| Code | Meaning here |
| --- | --- |
| `UNAUTHENTICATED` | no token, or an expired one — the app returns to sign-in |
| `PERMISSION_DENIED` | you are not in this conversation, or it is not yours |
| `INVALID_ARGUMENT` | a validation failure; the message says which field |
| `FAILED_PRECONDITION` | this invite is revoked/expired/used up |
| `ALREADY_EXISTS` | that username is taken |
| `RESOURCE_EXHAUSTED` | the event stream fell behind; reconnect |
| `NOT_FOUND` | gone, or the conversation no longer exists |

## Schema extensions

None yet. Everything the server enforces is a field in the contract above.
