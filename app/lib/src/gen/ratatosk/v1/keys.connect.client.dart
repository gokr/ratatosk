//
//  Generated code. Do not modify.
//  source: ratatosk/v1/keys.proto
//

import "package:connectrpc/connect.dart" as connect;
import "keys.pb.dart" as ratatoskv1keys;
import "keys.connect.spec.dart" as specs;

/// The public half of the end-to-end encryption keys, plus the key envelopes
/// that distribute group sender keys. See docs/E2EE.md for the protocol itself.
/// Nothing here is secret. The server is a directory for public keys and an
/// opaque mailbox for wrapped sender keys; it can neither read a message nor
/// forge a key envelope.
extension type KeyServiceClient (connect.Transport _transport) {
  /// Publish (or update) this device's public keys. Idempotent per key id, so a
  /// client may call it on every start.
  Future<ratatoskv1keys.PublishDeviceKeyResponse> publishDeviceKey(
    ratatoskv1keys.PublishDeviceKeyRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.KeyService.publishDeviceKey,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// The device keys of the named users. Clients need this before they can
  /// encrypt anything, so it is one call for a whole member list.
  Future<ratatoskv1keys.ListDeviceKeysResponse> listDeviceKeys(
    ratatoskv1keys.ListDeviceKeysRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.KeyService.listDeviceKeys,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Stop using a device key: it disappears from ListDeviceKeys. Messages
  /// already encrypted to it stay unreadable, which is the point.
  Future<ratatoskv1keys.RevokeDeviceKeyResponse> revokeDeviceKey(
    ratatoskv1keys.RevokeDeviceKeyRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.KeyService.revokeDeviceKey,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Deposit a wrapped sender key for one recipient device. The receiver finds
  /// it with ListKeyEnvelopes.
  Future<ratatoskv1keys.PutKeyEnvelopeResponse> putKeyEnvelope(
    ratatoskv1keys.PutKeyEnvelopeRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.KeyService.putKeyEnvelope,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// The envelopes addressed to this device, newest first. `since` makes the
  /// call cheap to repeat.
  Future<ratatoskv1keys.ListKeyEnvelopesResponse> listKeyEnvelopes(
    ratatoskv1keys.ListKeyEnvelopesRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.KeyService.listKeyEnvelopes,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// The account's encrypted key backup: an opaque blob this server can neither
  /// read nor usefully alter.
  /// It exists because device private keys live only in that device's keystore, so
  /// reinstalling the app permanently loses the ability to open old history. The
  /// blob is sealed on the device with a key derived from a passphrase the user
  /// chooses; the passphrase is never sent here, so a compromised server yields
  /// nothing.
  Future<ratatoskv1keys.PutKeyBackupResponse> putKeyBackup(
    ratatoskv1keys.PutKeyBackupRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.KeyService.putKeyBackup,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<ratatoskv1keys.GetKeyBackupResponse> getKeyBackup(
    ratatoskv1keys.GetKeyBackupRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.KeyService.getKeyBackup,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<ratatoskv1keys.DeleteKeyBackupResponse> deleteKeyBackup(
    ratatoskv1keys.DeleteKeyBackupRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.KeyService.deleteKeyBackup,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }
}
