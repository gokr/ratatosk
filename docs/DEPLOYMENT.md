# Deployment checklist

The intended first deployment is a single Go server, local SQLite storage and
an HTTPS home-screen web app. No App Store or Play Store submission is needed
for that web app. Do not treat a green desktop build as a real-phone push test.

## Before exposing the server

- Terminate TLS at a reverse proxy and set `RATATOSK_PUBLIC_URL` to the exact
  public HTTPS origin (for example `https://wowbagger.krampe.se`). Serve the app
  and API from that same origin. Disable wildcard CORS unless it is needed.
- Keep the data directory outside the web root, owned by the server account.
  SQLite belongs on local disk, not a shared network filesystem.
- Configure persistent Web Push VAPID credentials and a contact address; never
  regenerate keys on each restart. Losing/changing them requires clients to
  subscribe again. See the running guide for exact environment variables.
- Limit request bodies and login attempts at the proxy while application-level
  abuse controls are still absent. Keep private keys, bearer tokens and push
  endpoints out of logs.
- Back up the database, its external at-rest encryption key and `files/` off
  server. Use SQLite's backup API (or stop the server before copying), rather
  than copying only the live `.db` while WAL writes continue. Retain legacy
  snapshots until migration and restoration are verified.
- Test restoration into a separate directory: log in with an existing account,
  retrieve an old conversation and decrypt an old photo from an existing
  device. Database backups do not back up client encryption keys.

## Home-screen installation

On iOS/iPadOS 16.4 or later, open the HTTPS origin in Safari, choose **Add to
Home Screen**, then open the installed app. Enable notifications using the
app's explicit settings button. A regular Safari tab is not the iOS Web Push
installation flow. Android supports installed web apps and Web Push in
compatible browsers as well.

Notifications contain only a generic new-message notice. Apple/Google or the
browser's push service can still observe delivery timing and endpoints; Web
Push is not metadata anonymity. Permission denial, Focus modes, revoked
subscriptions and OS policy can delay or suppress notifications. Reopening the
app must recover messages from the server regardless of push delivery.

## Real-device acceptance checks

1. Install on one iPhone and one Android phone; sign in as different users.
2. Enable push from a user gesture, background the recipient, then send a
   message. Check there is no content or sender name in the notification.
3. Tap the notification and confirm the app opens and fetches/decrypts history.
4. Repeat with the recipient app closed, after a server restart, with a muted
   conversation, and after signing out. Signed-out subscriptions must not
   receive account notifications.
5. Disable notifications, deny permission, and revoke a subscription; none
   should prevent normal chat.
6. Take a photo, cancel a capture, remove a draft photo, and send a photo. Check
   both the preview and decryption on the other phone. Camera behaviour on the
   web depends on the browser's capture-capable picker; desktop browsers may
   offer a file picker instead.

## Security limits

A database thief cannot decrypt end-to-end sealed message bodies or photos
without client keys. A running-server attacker can read metadata and password
hashes, attempt password guessing, or modify the web app delivered to users to
steal future plaintext/keys. Home-screen installation does not remove that
web-code supply-chain risk. The prototype has no forward secrecy, audited key
backup or durable offline client transcript cache. Read [E2EE.md](E2EE.md)
before making stronger privacy claims.
