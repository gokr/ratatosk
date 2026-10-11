# Running it

Two commands, one url. The Go server also serves the Flutter web app, so the
app, its API, attachment downloads and invitation links all live on one origin
(no CORS, no second port, and invite links work in the same browser as the app).

```bash
make setup     # once: toolchains, code generators, dependencies
make proto     # generate the Go and Dart code from proto/
make server    # build the web app and the server, then run both
```

`make setup` needs no sudo and installs nothing globally: it finds your `go`,
`flutter` and `dart`, downloads `buf` and the four protobuf plugins into
`var/tools/` (pinned versions), and records the paths in `var/tools/env`, which
the Makefile includes. Re-run it after a fresh clone; it is safe to re-run and
skips what is already there. `FORCE=1 make setup` reinstalls the generators, and
`BUF_VERSION=1.50.0 make setup` picks a different buf.

If something does not work, `make doctor` prints what it can and cannot find.

Then open **<http://localhost:8080>** and create an account.

`make server` is a foreground process; `Ctrl-C` shuts it down cleanly. Its data
— accounts, conversations, uploaded blobs, the at-rest encryption key — lives in
`var/data/`.

## Seeing two people talk

One browser profile holds one session, so use two profiles, two browsers, or one
browser and the desktop app:

```bash
make app DEVICE=linux        # a native window beside the browser
```

Then, in one of them:

1. **Create an account** (the sign-in screen's "Create a new account").
2. Tap the **invite** icon, then **Create a link**, then **Copy**.
3. Paste the link into the other client (paste it into the "Have an invitation?"
   box in the other client's invite sheet, or just open the url — the landing
   page offers both "Open in the app" and "Continue in the browser").
4. **Accept invitation.** Both sides become contacts and the conversation opens.
5. Type. Messages appear on the other side without a reload.

The invite sheet also lists your links, with a copy and a revoke button, and the
"Options" toggle sets an expiry and a use count.

## What to look at

| Screen | What it shows |
| --- | --- |
| Sign-in | the account form; a pending invitation is remembered across sign-up |
| Chats | conversation list: avatar with presence dot, unread badge, muted/pinned marks |
| Thread | the padlock badge, mute/pin, the message list, typing indicator, composer |
| Composer | attach a file, or **take a photo** (Android/iOS, and the browser's capture picker on the web). A capture previews locally and is sealed and uploaded only when you press Send — removing it costs nothing |
| Settings → Message notifications | enable/disable browser notifications. Requires HTTPS; on iOS/iPadOS 16.4+ the app must be installed via Share → Add to Home Screen |
| Message actions | long-press (or right-click) a bubble: reactions, reply, edit, delete |
| Details | tap the thread's header: members, add/remove, rename, mute, pin, leave |
| Encryption | tap the padlock: key fingerprints, the safety number, "the numbers match" |
| Invite | create/copy/share/revoke links, or accept one |
| Settings | your profile, contacts, the server address, the realtime state, sign out |

Wide windows show the list and the thread side by side; narrow ones show one at a
time. (Resize the window to see it switch.)

## Trying the encryption

- With two clients that have both opened the app, messages are sealed on the
  sending device: the server only ever holds ciphertext. To see that for
  yourself, look at what the database holds while the server runs:

  ```bash
  sqlite3 var/data/ratatosk.db 'select kind, count(*) from sqlite_master'
  grep -c 'a word from a message' var/data/ratatosk.db   # 0
  ```

  Every record is an AES-256-GCM sealed blob under `var/data/data-key` (or
  `RATATOSK_DATA_KEY`), keyed and indexed by an HMAC digest so the server can
  query rows without reading them, and message bodies are sealed with keys the
  server never has. A stolen disk, a backup or a container image therefore
  yields nothing readable.

- Tap the padlock in a thread, then **The numbers match** to mark the
  conversation verified. Compare the number with the other person over a call or
  in person for it to mean anything (docs/E2EE.md §6).

- A contact who has never opened an app (a script, say) has no public key, so
  the padlock shows **open** and sending is refused with an explanation. That is
  deliberate: the app will not quietly send a message in the clear.

## Configuration

The server takes flags, each also readable from the environment:

```bash
./var/bin/ratatoskd --help
```

The ones that matter when running it for real:

| Flag | Env | Default |
| --- | --- | --- |
| `--addr` | `RATATOSK_ADDR` | `:8080` |
| `--public-url` | `RATATOSK_PUBLIC_URL` | `http://localhost:8080` — the origin in invite and attachment links; **set this behind a proxy** |
| `--data` | `RATATOSK_DATA` | `./data` |
| — | `RATATOSK_VAPID_PUBLIC_KEY` | unset: notifications are off |
| — | `RATATOSK_VAPID_PRIVATE_KEY` | unset: notifications are off |
| — | `RATATOSK_VAPID_CONTACT` | unset: required once the keys are set (`mailto:` or `https:`) |
| `--web` | `RATATOSK_WEB_DIR` | the built web app, or none |
| — | `RATATOSK_DATA_KEY` | 32 bytes, hex or base64; else `var/data/data-key` is generated |

The client points at `http://localhost:8080` unless built with
`--dart-define=RATATOSK_URL=https://chat.example`, or told otherwise in
**Settings → Server** (which takes effect after a restart).

## Notifications

Notifications are **Web Push**, so the same install works for an Android phone,
an iPhone (16.4+, added to the Home Screen) and a desktop browser — no App Store
or Play Store submission. The server sends a fixed `New message` body: it carries
no sender, no conversation and no content, because the push service is a third
party and the message is end-to-end encrypted anyway. Opening the app is what
fetches and decrypts the actual message.

Generate a VAPID key pair once and keep it: changing it silently invalidates
every existing subscription.

```bash
# Any Web Push VAPID generator works; the keys are base64url.
openssl ecparam -genkey -name prime256v1 -noout -out vapid.pem   # or use a library
```

Set the three variables above and restart. Push is off unless all three are set:
a partial configuration is refused at startup rather than half-working. Without
them the app shows notifications as unavailable and chat is unaffected.

A subscription belongs to an account *and* a session. Signing out stops
notifications for that session; a push service that reports an endpoint as gone
has it removed; a muted conversation and the sender's own devices are skipped.
Delivery is best effort — it never blocks message sending and is not retried
across a restart, so a lost notification only means the next app open fetches the
message.

## Where it stores things

```
var/data/
  ratatosk.db     the SQLite database (schema migrated by goose on startup).
                  Each record is a separate sealed row — never a whole-state
                  snapshot — so writes are per-row and durable before the call
                  returns.
  ratatosk.db-wal write-ahead log, synchronous=FULL
  data-key        the key that opens the records, mode 0600
  files/          uploaded blobs: already ciphertext for an encrypted
                  conversation, stored as received
  ratatosk.json   only if you upgraded from a pre-SQLite server: the old sealed
                  snapshot, imported on first start and then left in place as a
                  fallback
```

Losing `data-key` means losing the database: keep a copy with any backup of
`ratatosk.db` and `files/`. Back up with SQLite's own tooling (`.backup`, or the
`sqlite3` backup API) rather than copying the file under a running server, and
check the restore — see [DEPLOYMENT.md](DEPLOYMENT.md).

## What survives a restart

Two different restarts, with different answers.

**Restarting the server.** Nothing is lost. Accounts, sessions, conversations,
key envelopes and messages are all committed rows in `var/data/ratatosk.db`, and the client's
session token is a server-side record, so a client stays signed in and simply
reconnects its stream. Connected clients notice, reconnect, and ask for
everything appended since the newest message they hold (`ListMessages` with
`afterSeq`) — they do not re-download the thread.

**Restarting a client** (closing the app, reloading the page, a new phone).
There is no message cache on disk: history is *fetched from the server* per
conversation, so a client that has never seen a conversation sees all of it.
What is per device is the *key material*: the identity keys live in the platform
keystore, and so do this device's own sender keys (each device registers its own
device key and is addressable on its own). A restarted client therefore reads
history again — including its own group messages, which are opened with the
sender key it saved — but a *different* device of the same account is a
different device to the crypto: see [E2EE.md](E2EE.md) §1 for what that means
for direct conversations versus groups today.

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| `no web app found` on `/` | the build did not run: `make web`, or pass `--web <dir>` |
| The app shows "Could not reach the server" | the server is not running, or `RATATOSK_URL` points somewhere else |
| "unsupported content type text/html" in the console | a client whose base url has a stray `?` or `#`; fixed in `SessionStore.baseUrlFrom`, but a proxy that rewrites the path can do the same |
| Links point at `localhost` behind a proxy | set `--public-url` |
| A message says "Sent from your other device (…), which never shared this conversation's key with this device" | this device has not received the sibling device's sender key. Open the conversation on that other device if it still exists. A lost sender does not invalidate copies already shared, but this device cannot recover a key if no usable copy remains; see [E2EE.md](E2EE.md) §1 |
| `make app DEVICE=linux` fails on `libsecret-1` | `sudo apt install libsecret-1-dev`: the private keys go in the platform keystore |
| `buf is not installed` | `make setup` |
| `make proto` works but a generator is "not found" | `FORCE=1 make setup` to re-fetch them into `var/tools` |
| `go: command not found` from make | `make setup` records the path it found; or pass `GO=/usr/local/go/bin/go` |
| `the data key does not open this database` at start | `RATATOSK_DATA_KEY` (or `var/data/data-key`) is not the key the database was written with. The check runs before any migration, so a wrong key is refused instead of damaging the file |
| `rows exist without key check` at start | the database has content but no key marker: stop and restore a backup rather than letting the server re-initialize over real history |
| Messages from another of your devices stay unreadable although both are online | fixed: distribution used to skip this account's own devices, and stopped after the first pass. `cd app && dart run tool/two_devices.dart http://127.0.0.1:8080` against a running server proves the current behaviour |
