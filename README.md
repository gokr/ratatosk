# Ratatosk

A messenger: a Flutter client and a Go server that speak
[ConnectRPC](https://connectrpc.com) over one Protobuf contract, with
end-to-end encrypted messages, groups, attachments and invitation links.

```
proto/ratatosk/v1/     the wire contract (buf generates both sides from it)
server/                Go server: connect-go handlers over an HTTP/2 (h2c) listener
app/                   Flutter client (Android, iOS, Linux, macOS, Web, Windows)
docs/E2EE.md           the encryption design, its threat model and its limits
docs/PROTOCOL.md       accounts, conversations, messages, invites, realtime
```

## What works

- **Chat**: one-to-one and group conversations, a message thread with
  optimistic sends, edit, delete, emoji reactions, replies, read receipts,
  typing indicators, presence, mute/pin, unread counts, search.
- **Attachments**: images and files, sealed client-side like everything else.
- **Invitations**: generate a link, share it, revoke it; the link is a web page
  (`/join/<code>`) *and* a deep link (`ratatosk://join/<code>`) that the app
  handles. Redeeming connects two accounts.
- **Realtime**: one server-streaming `Subscribe` call per client carries
  messages, typing, receipts, presence and conversation changes. A client that
  falls behind reconnects and catches up from the store.
- **End-to-end encryption**: message text, attachment contents, filenames and
  reply targets are sealed on the sending device and opened only on the
  recipients' devices. Safety numbers to verify. The server stores ciphertext
  it cannot read, and everything it *does* store is encrypted at rest.

## What it deliberately does not do

- No voice or video calls.
- No metadata privacy: the server sees who talks to whom, when and how much.
- No forward secrecy yet: a stolen private key exposes recorded history. See
  [docs/E2EE.md](docs/E2EE.md) §9 for the roadmap and what each gap means.

## Requirements

| | |
| --- | --- |
| Go | 1.24+ |
| Flutter | 3.47+ (Dart 3.7+) |
| buf | for regenerating the protobuf code |
| Linux desktop builds | `libsecret-1-dev` (the private keys live in the platform keystore) |

`libsecret-1-dev` is only needed to *build* the Linux desktop app; the server,
the tests and the web build do not need it. On Debian/Ubuntu:

```bash
sudo apt install libsecret-1-dev
```

## Running it

```bash
make proto        # regenerate Go and Dart code from proto/ (needs buf)
make server       # build and run the server on :8080, data in ./data
make app          # run the Flutter app against it
make test         # server tests + client tests (the client's interop tests
                  # need a server on :8080, or RATATOSK_URL pointing at one)
```

The app talks to `http://localhost:8080` unless told otherwise: build with
`--dart-define=RATATOSK_URL=https://chat.example`, or change it in the app's
settings (which is the point of the setting).

To try two users on one machine, run the server once and start the app twice
(`flutter run -d linux` in two terminals, or one desktop and one browser).

**Create an invitation to connect two accounts.** Sign in, tap the invite icon,
copy the link; opening it in a browser shows a landing page that hands off to
the app, and the app's "Accept invitation" makes the two accounts contacts.

## Layout

```
server/
  cmd/ratatoskd/          entry point: flags, signal handling, shutdown
  internal/store/         all state: users, conversations, messages, keys,
                          at-rest encryption of the snapshot
  internal/service/       the four Connect services (auth, chat, social, keys)
  internal/realtime/      fan-out hub, presence, typing expiry
  internal/httpserver/    HTTP wiring, auth interceptor, attachments, invite page
  internal/auth/          password hashing and the request identity
app/lib/src/
  api/                    ChatBackend: the seam between the UI and the wire
  crypto/                 end-to-end encryption (keys, sessions, envelopes)
  gen/                    generated Connect clients and messages
  state/                  AppState: the one manager the UI watches
  ui/                     screens and widgets
```

## Design notes

- **One protocol, one contract.** Everything the client and server do is in
  `proto/ratatosk/v1`; `buf generate` produces connect-go handlers and
  connect-dart clients from the same files. The plain HTTP endpoints are only
  what a browser needs and an RPC cannot do: attachment bytes and the invite
  landing page.
- **One manager.** The Flutter app registers its pieces with `get_it` and the
  UI watches them with `watch_it`; `AppState` is the single source of truth, and
  the private keys never leave `crypto/`.
- **The server is untrusted for content and trusted for metadata.** That is a
  deliberate line, stated in [docs/E2EE.md](docs/E2EE.md) rather than implied.

## Status

This is a working prototype, not a hardened product: it has no rate limiting,
no abuse handling, no push notifications, no key backup and no audit. The
encryption is designed and tested but has not been reviewed by a cryptographer.
