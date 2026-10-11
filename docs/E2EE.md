# End-to-end encryption

Ratatosk encrypts message content on the device it is written on and decrypts
it only on the devices it was addressed to. The server stores ciphertext; it
cannot read messages, filenames, attachment contents, or replies, and a
break-in on the server does not reveal them.

This document is the contract. It states what the design protects, what it
deliberately does not, and what is still missing.

## Threat model

**Protected.** An attacker who has the server's database, its disk, a memory
dump of the running server, or full control of the server process learns:

- nothing about message text, replies, filenames, MIME types or attachment
  bytes;
- nothing about which key a client used beyond an opaque key id.

That is the point of the design: the server is treated as untrusted storage and
an untrusted relay.

**Not protected (and cannot be, by any E2EE chat).**

- **Metadata.** Who talks to whom, when, how often, message sizes, conversation
  membership, presence, contact lists, invite codes and account handles are all
  visible to the server. Hiding them needs a much larger design (sealed sender,
  private set intersection, cover traffic), which this project does not have.
- **A compromised device.** Malware on a device that holds the private keys
  reads everything that device can read.
- **Compulsion.** A user who is forced to unlock their device reveals their
  messages.

**Attacked by other means.**

- **A malicious server substituting keys.** The server hands out public keys,
  so it could hand a client its own key instead of the peer's, and read
  everything. This is why safety numbers exist (§6): two users who compare
  them out of band detect the substitution. Until they do, the client shows the
  conversation as unverified.
- **A compromised identity key.** Losing a device's private key exposes the
  messages that key can decrypt, including past ones — see forward secrecy
  below.

## 1. Keys

Each *install* (one account on one device) generates two key pairs on first
use:

| Key | Algorithm | Purpose |
| --- | --- | --- |
| Identity | X25519 | key agreement (ECDH) |
| Signing | Ed25519 | safety numbers, authenticating key envelopes |

The private keys are generated on the device and never leave it. They are
stored in the platform's secure storage (Keychain, Keystore, libsecret, DPAPI)
and are not backed up to the server.

The public halves are published to the server as a **device key**: an opaque id,
the two public keys, a device label and timestamps. The server also keeps a
**fingerprint** (see §6) so clients can display it without recomputing.

One account may have several devices, and each is a separate device key. What
happens with more than one device depends on the conversation kind — an
asymmetry worth stating plainly rather than implying:

* **Groups**: a sender key is distributed to every device of every member —
  *including your own other devices* — so all of a participant's devices can read
  the conversation. Distribution is per recipient and re-checked whenever a
  conversation is prepared, so a device that registers later still receives the
  key from any device that is still running.
* **Direct conversations**: the key is derived from the two *identity keys*, and
  a client derives it against one peer device (the oldest registered one). So a
  second device of the peer cannot read the conversation yet.

The fix for the direct case is to stop deriving and use a sender key there too,
with one envelope per peer device — the same shape groups already use, which
would make the two cases one code path instead of two. Until then the
encryption panel says so, in the conversation, next to the key list.

A limit that distribution cannot remove: a lost device's sender key cannot be
recovered by a new device unless another copy survives. Devices that already
received its key can still read those messages; losing the sender does not
invalidate those copies. But if the sender never shared the key with a device,
and no usable copy or backup remains, that device cannot recover the history.
Clients distinguish a missing key from another of your devices from an in-flight
decryption. Recovery needs key backup or an explicit transfer from a device
that still holds the key; see §9.

## 2. Conversation keys

### Direct conversations

Two devices in a direct conversation derive the same 32-byte conversation key
without any message being exchanged:

```
shared   = X25519(my_identity_private, their_identity_public)      # 32 bytes
conv_key = HKDF-SHA256(
             ikm  = shared,
             salt = "ratatosk/v1/direct",
             info = "ratatosk/v1/pair|" + min(fingerprint_a, fingerprint_b)
                                       + "|" + max(fingerprint_a, fingerprint_b))
```

The fingerprints in `info` bind the key to the exact key pair it was derived
from: if either side's key changes, the derived key changes, so a message
encrypted under the old pair fails to decrypt rather than silently decrypting
under a substituted key. Sorting the two fingerprints means both sides compute
the same `info` without agreeing on an order first.

These are **key fingerprints** — a digest of the two public keys and nothing
else — not the display fingerprints of §6, which also cover the device id. The
device id is assigned by the server, so deriving a conversation key from it would
hand the server a lever over the cryptography: hand out a new id and two peers
stop agreeing on a key with no key material having changed. Keys depend on key
material only.

### Group conversations: sender keys

Groups do not use pairwise keys, because that would multiply one message into
one ciphertext per member. Instead, each device holds a **sender key**: a random
32-byte secret, one per conversation and per *epoch*.

- A device generates its sender key when it first sends in a conversation.
- It distributes that key to every other member's device by wrapping it with
  each pairwise key (§4), one envelope per recipient device.
- It then encrypts every message it sends with its own sender key.
- The message names the sender key (`sender_key_id`, `epoch`), so a recipient
  knows which key to try.

A member who cannot find a key for a message cannot read it. That is the
correct failure: it keeps a newly added member from reading history from before
they joined (§5), and keeps a removed member from reading anything after the
next rotation.

## 3. Message content

A message is a protobuf `MessageContent`, serialized and sealed:

```
MessageContent {
  string text
  string reply_to_id
  repeated EncryptedAttachment attachments
}
EncryptedAttachment {
  string blob_id      # server-side opaque blob, ciphertext
  string filename     # hidden from the server: only the blob id is visible
  string content_type
  bytes  file_key     # 32 bytes, random per attachment
  bytes  nonce        # 24 bytes
  int64  size         # plaintext size, for the download progress bar
}
```

Sealed with XChaCha20-Poly1305:

```
nonce      = 24 random bytes, fresh for every message
aad        = "ratatosk/v1/msg|" + conversation_id + "|" + sender_key_id
ciphertext = XChaCha20Poly1305(conv_key_or_sender_key, nonce).seal(content, aad)
```

The 192-bit nonce makes a random nonce safe for a long-lived key, which is what
allows one conversation key to serve many messages without a counter — a
counter would have to be synchronized across devices that may be offline.

The AAD binds the ciphertext to the conversation and to the key that sealed it,
so a message cannot be replayed into a different conversation or attributed to a
different sender key.

`MessageContent` never leaves the device unwrapped. Deleted messages are
replaced by an empty ciphertext, so the server forgets the content too.

## 4. Key envelopes

When a device distributes a sender key, it wraps it once per recipient device:

```
wrap_key = HKDF-SHA256(
             ikm  = X25519(my_identity_private, recipient_identity_public),
             salt = "ratatosk/v1/wrap",
             info = "ratatosk/v1/pair|" + min(fp, fp) + "|" + max(fp, fp))
sealed   = XChaCha20Poly1305(wrap_key, nonce).seal(sender_key, aad =
             "ratatosk/v1/keyenv|" + conversation_id + "|" + sender_key_id
                                  + "|" + epoch + "|" + recipient_key_id)
```

The server stores the envelopes as opaque bytes, addressed by
`(conversation, sender_key_id, epoch, recipient_key_id)`. It can neither read a
sender key nor forge one: the AAD binds the envelope to the conversation, the
key id, the epoch and the recipient, so moving an envelope elsewhere makes it
fail to open.

## 5. Membership changes

- **Adding** a member: they receive no sender keys from before their arrival, so
  history stays unreadable to them (the group shows a "messages from before you
  joined" separator). New messages are readable because senders re-distribute
  their current sender key to the new device.
- **Removing** a member: the owner rotates every sender key it can (new epoch,
  fresh random key, distributed to the remaining members). A removed member
  keeps whatever they already received — E2EE cannot un-send a message — but
  cannot read the next epoch. Recipients prefer the highest epoch they can open,
  which is what makes the rotation take effect.

## 6. Safety numbers

A safety number is a digest of both identity keys, rendered as 12 groups of 5
digits:

```
digest = SHA-256("ratatosk/v1/safety|" + min(kfp_a, kfp_b) + "|" + max(kfp_a, kfp_b))
```

`kfp` is the **key fingerprint**: `SHA-256("ratatosk/v1/keyfp|" + identity_pub +
"|" + signing_pub)`. It covers key material only, so the number changes when a
key changes and stays put when the server re-registers a device under a new id.
The per-device *display* fingerprint, which does include the id, is shown in the
device list of the encryption panel — that is the place for it.

Both users compute the same number. Comparing it over a channel the server does
not control (in person, on a call, by reading it aloud) rules out a
key-substitution attack. The UI shows a conversation as **unverified** until the
user says they compared it, and keeps that verdict per conversation locally.

The signing key (§1) exists so a device can also sign its own key material,
which lets a future version authenticate a key history (a "key transparency"
log) rather than only the current key.

## 7. What the server can still do

Even with all of the above, a server can:

- drop, delay or reorder messages, and disconnect clients;
- refuse to serve a public key, making a conversation unusable;
- claim a message is from someone else (the client checks the sender key
  against the conversation's members, so this is caught, but the server can
  still claim *a* member sent it);
- learn the metadata listed above;
- serve an old key for a user whose key has since rotated, unless the client has
  seen the newer one (mitigated by pinning: a client that has seen a
  fingerprint for a device refuses a different one and warns loudly).

## 8. At rest on the server

E2EE protects content. Everything the server *does* keep — accounts, the social
graph, conversation membership, timestamps, system notes and message lengths —
is additionally encrypted at rest:

- The store snapshot is sealed with AES-256-GCM under a key that lives outside
  the database: `RATATOSK_DATA_KEY` (hex or base64) or a generated
  `data-key` file with `0600` permissions next to the data.
- Attachment blobs are already ciphertext, so they are stored as received.

That means a stolen database file, a backup, or a disk image yields nothing
without the key — which is not in the same place as the data.

## 9. What is implemented today

Everything above except the roadmap items below:

| Piece | Where |
| --- | --- |
| Primitives (X25519, Ed25519, HKDF-SHA256, XChaCha20-Poly1305) | `app/lib/src/crypto/crypto.dart` |
| Identity, key storage, registration | `app/lib/src/crypto/identity.dart`, `secure_storage.dart` |
| Conversation keys, sender keys, envelopes, encrypt/decrypt | `app/lib/src/crypto/session.dart` |
| The sealed message envelope and file sealing | `app/lib/src/crypto/message_content.dart` |
| The UI-facing façade (device keys, safety numbers) | `app/lib/src/crypto/manager.dart` |
| Key registry and envelope relay | `server/internal/service/key_service.go`, `store/keys.go` |
| Re-registration when the server has forgotten a device | `app/lib/src/crypto/identity.dart` (`_register`) |
| Own sender keys persisted, so a restart keeps your own group history | `app/lib/src/crypto/session.dart`, `manager.dart` |
| Rotation when a group's membership changes | `app/lib/src/crypto/manager.dart` (`prepareConversation`) |
| Public key directory, immutable device keys | `server/internal/store/keys.go` |
| Encryption at rest of the snapshot | `server/internal/store/atrest.go` |
| Safety numbers and the verify screen | `app/lib/src/ui/encryption_sheet.dart` |

What the tests pin, and where:

- `app/test/crypto_test.dart` — key derivation does not depend on the
  server-assigned device id (a re-registration keeps the conversation key and the
  safety number), key agreement is symmetric and peer-specific,
  sealing rejects a wrong key / wrong AAD / flipped byte, nonces never repeat,
  safety numbers agree and differ under substitution, the envelope path
  distributes a sender key that opens a group message and refuses a device it
  was not addressed to, an unknown envelope version is refused, and an identity
  survives a restart without being re-generated.
- `app/test/backend_interop_test.dart` — against a real server: a sealed message
  is relayed and opened by the peer and by nobody else, the ciphertext contains
  no plaintext, safety numbers agree across two devices, and a sealed attachment
  round-trips byte for byte.
- `server/internal/store/crypto_test.go` — the snapshot on disk contains no
  plaintext, the wrong data key refuses to open it, a plaintext-era snapshot is
  adopted and re-sealed, device keys are immutable, and envelopes require shared
  membership.
- `server/internal/httpserver/e2ee_test.go` — the RPC path: a sealed message
  round-trips with `text` empty, mixing plaintext and ciphertext is refused,
  server-side search cannot match a sealed body, a sealed upload carries neither
  filename nor content type, key enumeration is limited to contacts, a stranger
  cannot read the conversation, and the data directory reveals nothing.

## 10. Roadmap: what is missing

Listed in the order that matters, so nobody mistakes the current state for the
end state:

1. **Forward secrecy and post-compromise security.** Conversation keys are
   derived from long-term identity keys, so an attacker who records ciphertext
   and *later* steals an identity private key can decrypt the history. A Double
   Ratchet (symmetric chain + DH ratchet with skipped-message keys) removes
   that, at the cost of real complexity: out-of-order and offline delivery have
   to be handled per message. This is the single most valuable next step.
2. **Key transparency.** Pinning and safety numbers detect substitution, but
   only if users compare. An append-only, auditable log of key material (with
   the Ed25519 signing keys doing the signing) turns "trust this response" into
   "verify this proof".
3. **Direct conversations on more than one device.** Today a direct conversation
   is encrypted to the peer's oldest device only (§1). Deriving is what makes the
   first device special; distributing a sender key per device removes the
   asymmetry and deletes the second code path. Until this lands, a second device
   shows real messages as unopenable — the panel explains why, but the honest
   fix is to make it work.
4. **Per-device verification.** Safety numbers currently cover the account, not
   each device; a per-device view would make a rogue device visible.
5. **Sender-key recovery for a lost device.** Your own history dies with the
   device that wrote it (§1). Backup of sender keys, or re-sealing a
   conversation's history to the account's remaining devices, is what would make
   "log in somewhere new" show the whole thread.
6. **Metadata resistance.** Sealed sender, padding to fixed sizes, and
   traffic-shaping would hide the social graph from the server.
7. **Backup and multi-device onboarding.** Today a lost device means lost
   history, because the private key has no backup and the messages are not
   readable without it. An encrypted, passphrase-protected key backup (and
   history transfer between a user's own devices, sender keys included) is the
   practical fix — the same item as (5) seen from the other direction.

## 11. Versioning

The scheme string `ratatosk/v1` appears in every HKDF salt and AAD, so a future
protocol can be introduced alongside this one instead of breaking it: a message
carries the version that sealed it, and a client that does not know a version
says so rather than guessing.
