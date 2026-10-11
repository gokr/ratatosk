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

- **One url**: the server serves the built web app, so a browser needs nothing
  but `make server`.
- **Chat**: one-to-one and group conversations, a message thread with
  optimistic sends, edit, delete, emoji reactions, replies, read receipts,
  typing indicators, presence, mute/pin, unread counts, search.
- **Attachments**: images and files, sealed client-side like everything else —
  including a **camera capture** straight from the composer.
- **Notifications**: Web Push, so one install covers Android, iPhone (16.4+, from
  the Home Screen) and the desktop browser with no app store involved. The push
  payload is a bare `New message`: nothing about the sender or the content.
- **Invitations**: generate a link and show it as a QR code, send it, or revoke
  it; the link is a web page (`/join/<code>`) *and* a deep link
  (`ratatosk://join/<code>`) that the app handles. Redeeming connects two
  accounts.

  ![The invite sheet, with a QR code of the invitation link](docs/screenshots/invite-qr.png)
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
| Linux desktop builds | `libsecret-1-dev` (the private keys live in the platform keystore) |

`buf` and the four protobuf code generators are **not** a requirement: `make
setup` fetches them into `var/tools/`, pinned to a known version, and writes
`var/tools/env` so every other target finds them. Nothing is installed globally
and no step needs sudo.

`libsecret-1-dev` is only needed to *build* the Linux desktop app; the server,
the tests and the web build do not need it:

```bash
sudo apt install libsecret-1-dev
```

## Running it

```bash
make setup     # once: finds the toolchains, fetches buf + the generators,
               # resolves dependencies. `make doctor` reports without changing.
make proto     # regenerate the Go and Dart code from proto/
make server    # builds the web app + the server, then serves both
```

`make setup` is the only step that needs the network (it downloads buf and runs
`go mod download` / `flutter pub get`).

Then open **<http://localhost:8080>** and create an account. The server serves
the Flutter web app itself, so the app, the API, attachment downloads and
invitation links all live on one origin.

```bash
make app DEVICE=linux       # or run a native window beside the browser
make test                   # server tests + client tests
```

**See two people talk**: sign in, tap the invite icon, copy the link, and open
it in a second browser profile (`docs/RUNNING.md` walks through it, and through
what each screen shows).

The full runbook — two-user walkthrough, configuration, what to look at,
troubleshooting — is [docs/RUNNING.md](docs/RUNNING.md).

## Layout

```
server/
  cmd/ratatoskd/          entry point: flags, signal handling, shutdown
  internal/store/         all state in SQLite (goose migrations): users,
                          conversations, messages, keys. Each row is sealed
                          individually; an HMAC digest keys the indexes. A
                          pre-SQLite JSON snapshot is imported on first start
  internal/push/          Web Push delivery: VAPID-validated, queue-based,
                          SSRF-guarded endpoint checks
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
no abuse handling, no key backup and no audit. The encryption is designed and
tested but has not been reviewed by a cryptographer.

Counting the operations that exist: the database is SQLite with goose
migrations and per-row at-rest encryption; notifications are Web Push with a
content-free payload; a photo can be taken in the composer and is sealed like any
other attachment. Before pointing this at real people, read
[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) — it lists what to configure, what to
back up (and how to test the restore), and which claims about a stolen server are
true and which are not.
