//
//  Generated code. Do not modify.
//  source: ratatosk/v1/keys.proto
//

import "package:connectrpc/connect.dart" as connect;
import "keys.pb.dart" as ratatoskv1keys;

/// The public half of the end-to-end encryption keys, plus the key envelopes
/// that distribute group sender keys. See docs/E2EE.md for the protocol itself.
/// Nothing here is secret. The server is a directory for public keys and an
/// opaque mailbox for wrapped sender keys; it can neither read a message nor
/// forge a key envelope.
abstract final class KeyService {
  /// Fully-qualified name of the KeyService service.
  static const name = 'ratatosk.v1.KeyService';

  /// Publish (or update) this device's public keys. Idempotent per key id, so a
  /// client may call it on every start.
  static const publishDeviceKey = connect.Spec(
    '/$name/PublishDeviceKey',
    connect.StreamType.unary,
    ratatoskv1keys.PublishDeviceKeyRequest.new,
    ratatoskv1keys.PublishDeviceKeyResponse.new,
  );

  /// The device keys of the named users. Clients need this before they can
  /// encrypt anything, so it is one call for a whole member list.
  static const listDeviceKeys = connect.Spec(
    '/$name/ListDeviceKeys',
    connect.StreamType.unary,
    ratatoskv1keys.ListDeviceKeysRequest.new,
    ratatoskv1keys.ListDeviceKeysResponse.new,
  );

  /// Stop using a device key: it disappears from ListDeviceKeys. Messages
  /// already encrypted to it stay unreadable, which is the point.
  static const revokeDeviceKey = connect.Spec(
    '/$name/RevokeDeviceKey',
    connect.StreamType.unary,
    ratatoskv1keys.RevokeDeviceKeyRequest.new,
    ratatoskv1keys.RevokeDeviceKeyResponse.new,
  );

  /// Deposit a wrapped sender key for one recipient device. The receiver finds
  /// it with ListKeyEnvelopes.
  static const putKeyEnvelope = connect.Spec(
    '/$name/PutKeyEnvelope',
    connect.StreamType.unary,
    ratatoskv1keys.PutKeyEnvelopeRequest.new,
    ratatoskv1keys.PutKeyEnvelopeResponse.new,
  );

  /// The envelopes addressed to this device, newest first. `since` makes the
  /// call cheap to repeat.
  static const listKeyEnvelopes = connect.Spec(
    '/$name/ListKeyEnvelopes',
    connect.StreamType.unary,
    ratatoskv1keys.ListKeyEnvelopesRequest.new,
    ratatoskv1keys.ListKeyEnvelopesResponse.new,
  );

  /// The account's encrypted key backup: an opaque blob this server can neither
  /// read nor usefully alter.
  /// It exists because device private keys live only in that device's keystore, so
  /// reinstalling the app permanently loses the ability to open old history. The
  /// blob is sealed on the device with a key derived from a passphrase the user
  /// chooses; the passphrase is never sent here, so a compromised server yields
  /// nothing.
  static const putKeyBackup = connect.Spec(
    '/$name/PutKeyBackup',
    connect.StreamType.unary,
    ratatoskv1keys.PutKeyBackupRequest.new,
    ratatoskv1keys.PutKeyBackupResponse.new,
  );

  static const getKeyBackup = connect.Spec(
    '/$name/GetKeyBackup',
    connect.StreamType.unary,
    ratatoskv1keys.GetKeyBackupRequest.new,
    ratatoskv1keys.GetKeyBackupResponse.new,
  );

  static const deleteKeyBackup = connect.Spec(
    '/$name/DeleteKeyBackup',
    connect.StreamType.unary,
    ratatoskv1keys.DeleteKeyBackupRequest.new,
    ratatoskv1keys.DeleteKeyBackupResponse.new,
  );
}
