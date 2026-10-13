// This is a generated file - do not edit.
//
// Generated from ratatosk/v1/keys.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// One install's public keys. The private halves never leave the device.
class DeviceKey extends $pb.GeneratedMessage {
  factory DeviceKey({
    $core.String? id,
    $core.String? userId,
    $core.List<$core.int>? identityPublicKey,
    $core.List<$core.int>? signingPublicKey,
    $core.String? label,
    $core.String? platform,
    $0.Timestamp? createdAt,
    $0.Timestamp? lastSeen,
    $core.String? fingerprint,
    $core.bool? revoked,
  }) {
    final result = DeviceKey._();
    if (id != null) result.id = id;
    if (userId != null) result.userId = userId;
    if (identityPublicKey != null) result.identityPublicKey = identityPublicKey;
    if (signingPublicKey != null) result.signingPublicKey = signingPublicKey;
    if (label != null) result.label = label;
    if (platform != null) result.platform = platform;
    if (createdAt != null) result.createdAt = createdAt;
    if (lastSeen != null) result.lastSeen = lastSeen;
    if (fingerprint != null) result.fingerprint = fingerprint;
    if (revoked != null) result.revoked = revoked;
    return result;
  }

  DeviceKey._();

  factory DeviceKey.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeviceKey()..mergeFromBuffer(data, registry);
  factory DeviceKey.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeviceKey()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceKey',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: DeviceKey.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'identityPublicKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'signingPublicKey', $pb.PbFieldType.OY)
    ..aOS(5, _omitFieldNames ? '' : 'label')
    ..aOS(6, _omitFieldNames ? '' : 'platform')
    ..aOM<$0.Timestamp>(7, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOM<$0.Timestamp>(8, _omitFieldNames ? '' : 'lastSeen',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOS(9, _omitFieldNames ? '' : 'fingerprint')
    ..aOB(10, _omitFieldNames ? '' : 'revoked')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceKey clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceKey copyWith(void Function(DeviceKey) updates) =>
      super.copyWith((message) => updates(message as DeviceKey)) as DeviceKey;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeviceKey() / DeviceKey.new instead')
  static DeviceKey create() => DeviceKey._();
  static $pb.GeneratedMessage $_createMessage() => DeviceKey._();
  @$core.override
  DeviceKey createEmptyInstance() => DeviceKey._();
  @$core.pragma('dart2js:noInline')
  static DeviceKey getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeviceKey>(DeviceKey.$_createMessage);
  static DeviceKey? _defaultInstance;

  /// Opaque server-assigned id, referenced by envelopes and by messages.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  /// X25519 public key (32 bytes), for key agreement.
  @$pb.TagNumber(3)
  $core.List<$core.int> get identityPublicKey => $_getN(2);
  @$pb.TagNumber(3)
  set identityPublicKey($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIdentityPublicKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearIdentityPublicKey() => $_clearField(3);

  /// Ed25519 public key (32 bytes), for signatures and future key transparency.
  @$pb.TagNumber(4)
  $core.List<$core.int> get signingPublicKey => $_getN(3);
  @$pb.TagNumber(4)
  set signingPublicKey($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSigningPublicKey() => $_has(3);
  @$pb.TagNumber(4)
  void clearSigningPublicKey() => $_clearField(4);

  /// Human label, e.g. "Pixel 8" or "Firefox on Linux".
  @$pb.TagNumber(5)
  $core.String get label => $_getSZ(4);
  @$pb.TagNumber(5)
  set label($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLabel() => $_has(4);
  @$pb.TagNumber(5)
  void clearLabel() => $_clearField(5);

  /// The app that owns the key: "linux", "android", "ios", "web", "macos",
  /// "windows". A client shows it to explain where a key came from.
  @$pb.TagNumber(6)
  $core.String get platform => $_getSZ(5);
  @$pb.TagNumber(6)
  set platform($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPlatform() => $_has(5);
  @$pb.TagNumber(6)
  void clearPlatform() => $_clearField(6);

  @$pb.TagNumber(7)
  $0.Timestamp get createdAt => $_getN(6);
  @$pb.TagNumber(7)
  set createdAt($0.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasCreatedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearCreatedAt() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.Timestamp ensureCreatedAt() => $_ensure(6);

  @$pb.TagNumber(8)
  $0.Timestamp get lastSeen => $_getN(7);
  @$pb.TagNumber(8)
  set lastSeen($0.Timestamp value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasLastSeen() => $_has(7);
  @$pb.TagNumber(8)
  void clearLastSeen() => $_clearField(8);
  @$pb.TagNumber(8)
  $0.Timestamp ensureLastSeen() => $_ensure(7);

  /// Hex SHA-256 over both public keys, in the exact form safety numbers digest.
  /// Convenience only: clients verify it themselves.
  @$pb.TagNumber(9)
  $core.String get fingerprint => $_getSZ(8);
  @$pb.TagNumber(9)
  set fingerprint($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasFingerprint() => $_has(8);
  @$pb.TagNumber(9)
  void clearFingerprint() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get revoked => $_getBF(9);
  @$pb.TagNumber(10)
  set revoked($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasRevoked() => $_has(9);
  @$pb.TagNumber(10)
  void clearRevoked() => $_clearField(10);
}

/// A sender key, sealed once per recipient device. The server sees opaque bytes.
///
/// The sender key itself is identified by the triple
/// (conversation_id, sender_device_key_id, epoch): a device's sender key for a
/// conversation, at one generation. Rotating membership means a new epoch.
class KeyEnvelope extends $pb.GeneratedMessage {
  factory KeyEnvelope({
    $core.String? id,
    $core.String? conversationId,
    $core.String? senderDeviceKeyId,
    $core.String? recipientDeviceKeyId,
    $core.int? epoch,
    $core.List<$core.int>? wrappedKey,
    $core.List<$core.int>? nonce,
    $0.Timestamp? createdAt,
  }) {
    final result = KeyEnvelope._();
    if (id != null) result.id = id;
    if (conversationId != null) result.conversationId = conversationId;
    if (senderDeviceKeyId != null) result.senderDeviceKeyId = senderDeviceKeyId;
    if (recipientDeviceKeyId != null)
      result.recipientDeviceKeyId = recipientDeviceKeyId;
    if (epoch != null) result.epoch = epoch;
    if (wrappedKey != null) result.wrappedKey = wrappedKey;
    if (nonce != null) result.nonce = nonce;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  KeyEnvelope._();

  factory KeyEnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      KeyEnvelope()..mergeFromBuffer(data, registry);
  factory KeyEnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      KeyEnvelope()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'KeyEnvelope',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: KeyEnvelope.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'conversationId')
    ..aOS(3, _omitFieldNames ? '' : 'senderDeviceKeyId')
    ..aOS(4, _omitFieldNames ? '' : 'recipientDeviceKeyId')
    ..aI(5, _omitFieldNames ? '' : 'epoch')
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'wrappedKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        7, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..aOM<$0.Timestamp>(8, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $0.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeyEnvelope clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeyEnvelope copyWith(void Function(KeyEnvelope) updates) =>
      super.copyWith((message) => updates(message as KeyEnvelope))
          as KeyEnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use KeyEnvelope() / KeyEnvelope.new instead')
  static KeyEnvelope create() => KeyEnvelope._();
  static $pb.GeneratedMessage $_createMessage() => KeyEnvelope._();
  @$core.override
  KeyEnvelope createEmptyInstance() => KeyEnvelope._();
  @$core.pragma('dart2js:noInline')
  static KeyEnvelope getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<KeyEnvelope>(
          KeyEnvelope.$_createMessage);
  static KeyEnvelope? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get conversationId => $_getSZ(1);
  @$pb.TagNumber(2)
  set conversationId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConversationId() => $_has(1);
  @$pb.TagNumber(2)
  void clearConversationId() => $_clearField(2);

  /// The device whose sender key this wraps.
  @$pb.TagNumber(3)
  $core.String get senderDeviceKeyId => $_getSZ(2);
  @$pb.TagNumber(3)
  set senderDeviceKeyId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSenderDeviceKeyId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSenderDeviceKeyId() => $_clearField(3);

  /// The device the wrapped key is addressed to.
  @$pb.TagNumber(4)
  $core.String get recipientDeviceKeyId => $_getSZ(3);
  @$pb.TagNumber(4)
  set recipientDeviceKeyId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRecipientDeviceKeyId() => $_has(3);
  @$pb.TagNumber(4)
  void clearRecipientDeviceKeyId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get epoch => $_getIZ(4);
  @$pb.TagNumber(5)
  set epoch($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEpoch() => $_has(4);
  @$pb.TagNumber(5)
  void clearEpoch() => $_clearField(5);

  /// XChaCha20-Poly1305 seal of the 32-byte sender key.
  @$pb.TagNumber(6)
  $core.List<$core.int> get wrappedKey => $_getN(5);
  @$pb.TagNumber(6)
  set wrappedKey($core.List<$core.int> value) => $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasWrappedKey() => $_has(5);
  @$pb.TagNumber(6)
  void clearWrappedKey() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.int> get nonce => $_getN(6);
  @$pb.TagNumber(7)
  set nonce($core.List<$core.int> value) => $_setBytes(6, value);
  @$pb.TagNumber(7)
  $core.bool hasNonce() => $_has(6);
  @$pb.TagNumber(7)
  void clearNonce() => $_clearField(7);

  @$pb.TagNumber(8)
  $0.Timestamp get createdAt => $_getN(7);
  @$pb.TagNumber(8)
  set createdAt($0.Timestamp value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasCreatedAt() => $_has(7);
  @$pb.TagNumber(8)
  void clearCreatedAt() => $_clearField(8);
  @$pb.TagNumber(8)
  $0.Timestamp ensureCreatedAt() => $_ensure(7);
}

class PublishDeviceKeyRequest extends $pb.GeneratedMessage {
  factory PublishDeviceKeyRequest({
    $core.String? id,
    $core.List<$core.int>? identityPublicKey,
    $core.List<$core.int>? signingPublicKey,
    $core.String? label,
    $core.String? platform,
  }) {
    final result = PublishDeviceKeyRequest._();
    if (id != null) result.id = id;
    if (identityPublicKey != null) result.identityPublicKey = identityPublicKey;
    if (signingPublicKey != null) result.signingPublicKey = signingPublicKey;
    if (label != null) result.label = label;
    if (platform != null) result.platform = platform;
    return result;
  }

  PublishDeviceKeyRequest._();

  factory PublishDeviceKeyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PublishDeviceKeyRequest()..mergeFromBuffer(data, registry);
  factory PublishDeviceKeyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PublishDeviceKeyRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PublishDeviceKeyRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: PublishDeviceKeyRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'identityPublicKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'signingPublicKey', $pb.PbFieldType.OY)
    ..aOS(4, _omitFieldNames ? '' : 'label')
    ..aOS(5, _omitFieldNames ? '' : 'platform')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishDeviceKeyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishDeviceKeyRequest copyWith(
          void Function(PublishDeviceKeyRequest) updates) =>
      super.copyWith((message) => updates(message as PublishDeviceKeyRequest))
          as PublishDeviceKeyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PublishDeviceKeyRequest() / PublishDeviceKeyRequest.new instead')
  static PublishDeviceKeyRequest create() => PublishDeviceKeyRequest._();
  static $pb.GeneratedMessage $_createMessage() => PublishDeviceKeyRequest._();
  @$core.override
  PublishDeviceKeyRequest createEmptyInstance() => PublishDeviceKeyRequest._();
  @$core.pragma('dart2js:noInline')
  static PublishDeviceKeyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PublishDeviceKeyRequest>(
          PublishDeviceKeyRequest.$_createMessage);
  static PublishDeviceKeyRequest? _defaultInstance;

  /// Set to rotate an existing key; empty registers a new device.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get identityPublicKey => $_getN(1);
  @$pb.TagNumber(2)
  set identityPublicKey($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIdentityPublicKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearIdentityPublicKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get signingPublicKey => $_getN(2);
  @$pb.TagNumber(3)
  set signingPublicKey($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSigningPublicKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearSigningPublicKey() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get label => $_getSZ(3);
  @$pb.TagNumber(4)
  set label($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLabel() => $_has(3);
  @$pb.TagNumber(4)
  void clearLabel() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get platform => $_getSZ(4);
  @$pb.TagNumber(5)
  set platform($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPlatform() => $_has(4);
  @$pb.TagNumber(5)
  void clearPlatform() => $_clearField(5);
}

class PublishDeviceKeyResponse extends $pb.GeneratedMessage {
  factory PublishDeviceKeyResponse({
    DeviceKey? deviceKey,
  }) {
    final result = PublishDeviceKeyResponse._();
    if (deviceKey != null) result.deviceKey = deviceKey;
    return result;
  }

  PublishDeviceKeyResponse._();

  factory PublishDeviceKeyResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PublishDeviceKeyResponse()..mergeFromBuffer(data, registry);
  factory PublishDeviceKeyResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PublishDeviceKeyResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PublishDeviceKeyResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: PublishDeviceKeyResponse.$_createMessage)
    ..aOM<DeviceKey>(1, _omitFieldNames ? '' : 'deviceKey',
        subBuilder: DeviceKey.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishDeviceKeyResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishDeviceKeyResponse copyWith(
          void Function(PublishDeviceKeyResponse) updates) =>
      super.copyWith((message) => updates(message as PublishDeviceKeyResponse))
          as PublishDeviceKeyResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PublishDeviceKeyResponse() / PublishDeviceKeyResponse.new instead')
  static PublishDeviceKeyResponse create() => PublishDeviceKeyResponse._();
  static $pb.GeneratedMessage $_createMessage() => PublishDeviceKeyResponse._();
  @$core.override
  PublishDeviceKeyResponse createEmptyInstance() =>
      PublishDeviceKeyResponse._();
  @$core.pragma('dart2js:noInline')
  static PublishDeviceKeyResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PublishDeviceKeyResponse>(
          PublishDeviceKeyResponse.$_createMessage);
  static PublishDeviceKeyResponse? _defaultInstance;

  @$pb.TagNumber(1)
  DeviceKey get deviceKey => $_getN(0);
  @$pb.TagNumber(1)
  set deviceKey(DeviceKey value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceKey() => $_clearField(1);
  @$pb.TagNumber(1)
  DeviceKey ensureDeviceKey() => $_ensure(0);
}

class ListDeviceKeysRequest extends $pb.GeneratedMessage {
  factory ListDeviceKeysRequest({
    $core.Iterable<$core.String>? userIds,
    $core.bool? includeRevoked,
  }) {
    final result = ListDeviceKeysRequest._();
    if (userIds != null) result.userIds.addAll(userIds);
    if (includeRevoked != null) result.includeRevoked = includeRevoked;
    return result;
  }

  ListDeviceKeysRequest._();

  factory ListDeviceKeysRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListDeviceKeysRequest()..mergeFromBuffer(data, registry);
  factory ListDeviceKeysRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListDeviceKeysRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListDeviceKeysRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: ListDeviceKeysRequest.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'userIds')
    ..aOB(2, _omitFieldNames ? '' : 'includeRevoked')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDeviceKeysRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDeviceKeysRequest copyWith(
          void Function(ListDeviceKeysRequest) updates) =>
      super.copyWith((message) => updates(message as ListDeviceKeysRequest))
          as ListDeviceKeysRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListDeviceKeysRequest() / ListDeviceKeysRequest.new instead')
  static ListDeviceKeysRequest create() => ListDeviceKeysRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListDeviceKeysRequest._();
  @$core.override
  ListDeviceKeysRequest createEmptyInstance() => ListDeviceKeysRequest._();
  @$core.pragma('dart2js:noInline')
  static ListDeviceKeysRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListDeviceKeysRequest>(
          ListDeviceKeysRequest.$_createMessage);
  static ListDeviceKeysRequest? _defaultInstance;

  /// Users whose device keys are wanted. Empty lists the caller's own.
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get userIds => $_getList(0);

  /// Include revoked keys, for auditing what a conversation's history was
  /// encrypted to.
  @$pb.TagNumber(2)
  $core.bool get includeRevoked => $_getBF(1);
  @$pb.TagNumber(2)
  set includeRevoked($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIncludeRevoked() => $_has(1);
  @$pb.TagNumber(2)
  void clearIncludeRevoked() => $_clearField(2);
}

class ListDeviceKeysResponse extends $pb.GeneratedMessage {
  factory ListDeviceKeysResponse({
    $core.Iterable<DeviceKey>? deviceKeys,
  }) {
    final result = ListDeviceKeysResponse._();
    if (deviceKeys != null) result.deviceKeys.addAll(deviceKeys);
    return result;
  }

  ListDeviceKeysResponse._();

  factory ListDeviceKeysResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListDeviceKeysResponse()..mergeFromBuffer(data, registry);
  factory ListDeviceKeysResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListDeviceKeysResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListDeviceKeysResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: ListDeviceKeysResponse.$_createMessage)
    ..pPM<DeviceKey>(1, _omitFieldNames ? '' : 'deviceKeys',
        subBuilder: DeviceKey.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDeviceKeysResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDeviceKeysResponse copyWith(
          void Function(ListDeviceKeysResponse) updates) =>
      super.copyWith((message) => updates(message as ListDeviceKeysResponse))
          as ListDeviceKeysResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListDeviceKeysResponse() / ListDeviceKeysResponse.new instead')
  static ListDeviceKeysResponse create() => ListDeviceKeysResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListDeviceKeysResponse._();
  @$core.override
  ListDeviceKeysResponse createEmptyInstance() => ListDeviceKeysResponse._();
  @$core.pragma('dart2js:noInline')
  static ListDeviceKeysResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListDeviceKeysResponse>(
          ListDeviceKeysResponse.$_createMessage);
  static ListDeviceKeysResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<DeviceKey> get deviceKeys => $_getList(0);
}

class RevokeDeviceKeyRequest extends $pb.GeneratedMessage {
  factory RevokeDeviceKeyRequest({
    $core.String? id,
  }) {
    final result = RevokeDeviceKeyRequest._();
    if (id != null) result.id = id;
    return result;
  }

  RevokeDeviceKeyRequest._();

  factory RevokeDeviceKeyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeDeviceKeyRequest()..mergeFromBuffer(data, registry);
  factory RevokeDeviceKeyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeDeviceKeyRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeDeviceKeyRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: RevokeDeviceKeyRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeDeviceKeyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeDeviceKeyRequest copyWith(
          void Function(RevokeDeviceKeyRequest) updates) =>
      super.copyWith((message) => updates(message as RevokeDeviceKeyRequest))
          as RevokeDeviceKeyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RevokeDeviceKeyRequest() / RevokeDeviceKeyRequest.new instead')
  static RevokeDeviceKeyRequest create() => RevokeDeviceKeyRequest._();
  static $pb.GeneratedMessage $_createMessage() => RevokeDeviceKeyRequest._();
  @$core.override
  RevokeDeviceKeyRequest createEmptyInstance() => RevokeDeviceKeyRequest._();
  @$core.pragma('dart2js:noInline')
  static RevokeDeviceKeyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RevokeDeviceKeyRequest>(
          RevokeDeviceKeyRequest.$_createMessage);
  static RevokeDeviceKeyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class RevokeDeviceKeyResponse extends $pb.GeneratedMessage {
  factory RevokeDeviceKeyResponse() => RevokeDeviceKeyResponse._();

  RevokeDeviceKeyResponse._();

  factory RevokeDeviceKeyResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeDeviceKeyResponse()..mergeFromBuffer(data, registry);
  factory RevokeDeviceKeyResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeDeviceKeyResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeDeviceKeyResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: RevokeDeviceKeyResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeDeviceKeyResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeDeviceKeyResponse copyWith(
          void Function(RevokeDeviceKeyResponse) updates) =>
      super.copyWith((message) => updates(message as RevokeDeviceKeyResponse))
          as RevokeDeviceKeyResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RevokeDeviceKeyResponse() / RevokeDeviceKeyResponse.new instead')
  static RevokeDeviceKeyResponse create() => RevokeDeviceKeyResponse._();
  static $pb.GeneratedMessage $_createMessage() => RevokeDeviceKeyResponse._();
  @$core.override
  RevokeDeviceKeyResponse createEmptyInstance() => RevokeDeviceKeyResponse._();
  @$core.pragma('dart2js:noInline')
  static RevokeDeviceKeyResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RevokeDeviceKeyResponse>(
          RevokeDeviceKeyResponse.$_createMessage);
  static RevokeDeviceKeyResponse? _defaultInstance;
}

class PutKeyEnvelopeRequest extends $pb.GeneratedMessage {
  factory PutKeyEnvelopeRequest({
    $core.String? conversationId,
    $core.String? senderDeviceKeyId,
    $core.String? recipientDeviceKeyId,
    $core.int? epoch,
    $core.List<$core.int>? wrappedKey,
    $core.List<$core.int>? nonce,
  }) {
    final result = PutKeyEnvelopeRequest._();
    if (conversationId != null) result.conversationId = conversationId;
    if (senderDeviceKeyId != null) result.senderDeviceKeyId = senderDeviceKeyId;
    if (recipientDeviceKeyId != null)
      result.recipientDeviceKeyId = recipientDeviceKeyId;
    if (epoch != null) result.epoch = epoch;
    if (wrappedKey != null) result.wrappedKey = wrappedKey;
    if (nonce != null) result.nonce = nonce;
    return result;
  }

  PutKeyEnvelopeRequest._();

  factory PutKeyEnvelopeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutKeyEnvelopeRequest()..mergeFromBuffer(data, registry);
  factory PutKeyEnvelopeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutKeyEnvelopeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PutKeyEnvelopeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: PutKeyEnvelopeRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aOS(2, _omitFieldNames ? '' : 'senderDeviceKeyId')
    ..aOS(3, _omitFieldNames ? '' : 'recipientDeviceKeyId')
    ..aI(4, _omitFieldNames ? '' : 'epoch')
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'wrappedKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutKeyEnvelopeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutKeyEnvelopeRequest copyWith(
          void Function(PutKeyEnvelopeRequest) updates) =>
      super.copyWith((message) => updates(message as PutKeyEnvelopeRequest))
          as PutKeyEnvelopeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PutKeyEnvelopeRequest() / PutKeyEnvelopeRequest.new instead')
  static PutKeyEnvelopeRequest create() => PutKeyEnvelopeRequest._();
  static $pb.GeneratedMessage $_createMessage() => PutKeyEnvelopeRequest._();
  @$core.override
  PutKeyEnvelopeRequest createEmptyInstance() => PutKeyEnvelopeRequest._();
  @$core.pragma('dart2js:noInline')
  static PutKeyEnvelopeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PutKeyEnvelopeRequest>(
          PutKeyEnvelopeRequest.$_createMessage);
  static PutKeyEnvelopeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get senderDeviceKeyId => $_getSZ(1);
  @$pb.TagNumber(2)
  set senderDeviceKeyId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSenderDeviceKeyId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSenderDeviceKeyId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get recipientDeviceKeyId => $_getSZ(2);
  @$pb.TagNumber(3)
  set recipientDeviceKeyId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRecipientDeviceKeyId() => $_has(2);
  @$pb.TagNumber(3)
  void clearRecipientDeviceKeyId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get epoch => $_getIZ(3);
  @$pb.TagNumber(4)
  set epoch($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEpoch() => $_has(3);
  @$pb.TagNumber(4)
  void clearEpoch() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get wrappedKey => $_getN(4);
  @$pb.TagNumber(5)
  set wrappedKey($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWrappedKey() => $_has(4);
  @$pb.TagNumber(5)
  void clearWrappedKey() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.int> get nonce => $_getN(5);
  @$pb.TagNumber(6)
  set nonce($core.List<$core.int> value) => $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasNonce() => $_has(5);
  @$pb.TagNumber(6)
  void clearNonce() => $_clearField(6);
}

class PutKeyEnvelopeResponse extends $pb.GeneratedMessage {
  factory PutKeyEnvelopeResponse({
    KeyEnvelope? envelope,
  }) {
    final result = PutKeyEnvelopeResponse._();
    if (envelope != null) result.envelope = envelope;
    return result;
  }

  PutKeyEnvelopeResponse._();

  factory PutKeyEnvelopeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutKeyEnvelopeResponse()..mergeFromBuffer(data, registry);
  factory PutKeyEnvelopeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutKeyEnvelopeResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PutKeyEnvelopeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: PutKeyEnvelopeResponse.$_createMessage)
    ..aOM<KeyEnvelope>(1, _omitFieldNames ? '' : 'envelope',
        subBuilder: KeyEnvelope.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutKeyEnvelopeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutKeyEnvelopeResponse copyWith(
          void Function(PutKeyEnvelopeResponse) updates) =>
      super.copyWith((message) => updates(message as PutKeyEnvelopeResponse))
          as PutKeyEnvelopeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PutKeyEnvelopeResponse() / PutKeyEnvelopeResponse.new instead')
  static PutKeyEnvelopeResponse create() => PutKeyEnvelopeResponse._();
  static $pb.GeneratedMessage $_createMessage() => PutKeyEnvelopeResponse._();
  @$core.override
  PutKeyEnvelopeResponse createEmptyInstance() => PutKeyEnvelopeResponse._();
  @$core.pragma('dart2js:noInline')
  static PutKeyEnvelopeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PutKeyEnvelopeResponse>(
          PutKeyEnvelopeResponse.$_createMessage);
  static PutKeyEnvelopeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  KeyEnvelope get envelope => $_getN(0);
  @$pb.TagNumber(1)
  set envelope(KeyEnvelope value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasEnvelope() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnvelope() => $_clearField(1);
  @$pb.TagNumber(1)
  KeyEnvelope ensureEnvelope() => $_ensure(0);
}

class ListKeyEnvelopesRequest extends $pb.GeneratedMessage {
  factory ListKeyEnvelopesRequest({
    $core.String? conversationId,
    $0.Timestamp? since,
  }) {
    final result = ListKeyEnvelopesRequest._();
    if (conversationId != null) result.conversationId = conversationId;
    if (since != null) result.since = since;
    return result;
  }

  ListKeyEnvelopesRequest._();

  factory ListKeyEnvelopesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListKeyEnvelopesRequest()..mergeFromBuffer(data, registry);
  factory ListKeyEnvelopesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListKeyEnvelopesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListKeyEnvelopesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: ListKeyEnvelopesRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'since',
        subBuilder: $0.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListKeyEnvelopesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListKeyEnvelopesRequest copyWith(
          void Function(ListKeyEnvelopesRequest) updates) =>
      super.copyWith((message) => updates(message as ListKeyEnvelopesRequest))
          as ListKeyEnvelopesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListKeyEnvelopesRequest() / ListKeyEnvelopesRequest.new instead')
  static ListKeyEnvelopesRequest create() => ListKeyEnvelopesRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListKeyEnvelopesRequest._();
  @$core.override
  ListKeyEnvelopesRequest createEmptyInstance() => ListKeyEnvelopesRequest._();
  @$core.pragma('dart2js:noInline')
  static ListKeyEnvelopesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListKeyEnvelopesRequest>(
          ListKeyEnvelopesRequest.$_createMessage);
  static ListKeyEnvelopesRequest? _defaultInstance;

  /// Only envelopes for this conversation; empty means all of them.
  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  /// Only envelopes created after this time, for cheap polling.
  @$pb.TagNumber(2)
  $0.Timestamp get since => $_getN(1);
  @$pb.TagNumber(2)
  set since($0.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSince() => $_has(1);
  @$pb.TagNumber(2)
  void clearSince() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureSince() => $_ensure(1);
}

class ListKeyEnvelopesResponse extends $pb.GeneratedMessage {
  factory ListKeyEnvelopesResponse({
    $core.Iterable<KeyEnvelope>? envelopes,
  }) {
    final result = ListKeyEnvelopesResponse._();
    if (envelopes != null) result.envelopes.addAll(envelopes);
    return result;
  }

  ListKeyEnvelopesResponse._();

  factory ListKeyEnvelopesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListKeyEnvelopesResponse()..mergeFromBuffer(data, registry);
  factory ListKeyEnvelopesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListKeyEnvelopesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListKeyEnvelopesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: ListKeyEnvelopesResponse.$_createMessage)
    ..pPM<KeyEnvelope>(1, _omitFieldNames ? '' : 'envelopes',
        subBuilder: KeyEnvelope.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListKeyEnvelopesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListKeyEnvelopesResponse copyWith(
          void Function(ListKeyEnvelopesResponse) updates) =>
      super.copyWith((message) => updates(message as ListKeyEnvelopesResponse))
          as ListKeyEnvelopesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListKeyEnvelopesResponse() / ListKeyEnvelopesResponse.new instead')
  static ListKeyEnvelopesResponse create() => ListKeyEnvelopesResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListKeyEnvelopesResponse._();
  @$core.override
  ListKeyEnvelopesResponse createEmptyInstance() =>
      ListKeyEnvelopesResponse._();
  @$core.pragma('dart2js:noInline')
  static ListKeyEnvelopesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListKeyEnvelopesResponse>(
          ListKeyEnvelopesResponse.$_createMessage);
  static ListKeyEnvelopesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<KeyEnvelope> get envelopes => $_getList(0);
}

/// An encrypted key backup. Every field is produced on the device.
class KeyBackup extends $pb.GeneratedMessage {
  factory KeyBackup({
    $core.List<$core.int>? salt,
    $core.List<$core.int>? nonce,
    $core.List<$core.int>? blob,
    $core.String? kdf,
    $core.int? memoryKib,
    $core.int? iterations,
    $core.int? parallelism,
    $core.String? version,
    $0.Timestamp? updatedAt,
  }) {
    final result = KeyBackup._();
    if (salt != null) result.salt = salt;
    if (nonce != null) result.nonce = nonce;
    if (blob != null) result.blob = blob;
    if (kdf != null) result.kdf = kdf;
    if (memoryKib != null) result.memoryKib = memoryKib;
    if (iterations != null) result.iterations = iterations;
    if (parallelism != null) result.parallelism = parallelism;
    if (version != null) result.version = version;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  KeyBackup._();

  factory KeyBackup.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      KeyBackup()..mergeFromBuffer(data, registry);
  factory KeyBackup.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      KeyBackup()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'KeyBackup',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: KeyBackup.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'salt', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'blob', $pb.PbFieldType.OY)
    ..aOS(4, _omitFieldNames ? '' : 'kdf')
    ..aI(5, _omitFieldNames ? '' : 'memoryKib')
    ..aI(6, _omitFieldNames ? '' : 'iterations')
    ..aI(7, _omitFieldNames ? '' : 'parallelism')
    ..aOS(8, _omitFieldNames ? '' : 'version')
    ..aOM<$0.Timestamp>(9, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $0.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeyBackup clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeyBackup copyWith(void Function(KeyBackup) updates) =>
      super.copyWith((message) => updates(message as KeyBackup)) as KeyBackup;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use KeyBackup() / KeyBackup.new instead')
  static KeyBackup create() => KeyBackup._();
  static $pb.GeneratedMessage $_createMessage() => KeyBackup._();
  @$core.override
  KeyBackup createEmptyInstance() => KeyBackup._();
  @$core.pragma('dart2js:noInline')
  static KeyBackup getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<KeyBackup>(KeyBackup.$_createMessage);
  static KeyBackup? _defaultInstance;

  /// Argon2id salt the passphrase was stretched with.
  @$pb.TagNumber(1)
  $core.List<$core.int> get salt => $_getN(0);
  @$pb.TagNumber(1)
  set salt($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSalt() => $_has(0);
  @$pb.TagNumber(1)
  void clearSalt() => $_clearField(1);

  /// Nonce of the AEAD that sealed the payload.
  @$pb.TagNumber(2)
  $core.List<$core.int> get nonce => $_getN(1);
  @$pb.TagNumber(2)
  set nonce($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNonce() => $_has(1);
  @$pb.TagNumber(2)
  void clearNonce() => $_clearField(2);

  /// The sealed payload: the device's key material.
  @$pb.TagNumber(3)
  $core.List<$core.int> get blob => $_getN(2);
  @$pb.TagNumber(3)
  set blob($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBlob() => $_has(2);
  @$pb.TagNumber(3)
  void clearBlob() => $_clearField(3);

  /// "argon2id"; named so a future algorithm can be added without guessing.
  @$pb.TagNumber(4)
  $core.String get kdf => $_getSZ(3);
  @$pb.TagNumber(4)
  set kdf($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasKdf() => $_has(3);
  @$pb.TagNumber(4)
  void clearKdf() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get memoryKib => $_getIZ(4);
  @$pb.TagNumber(5)
  set memoryKib($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMemoryKib() => $_has(4);
  @$pb.TagNumber(5)
  void clearMemoryKib() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get iterations => $_getIZ(5);
  @$pb.TagNumber(6)
  set iterations($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIterations() => $_has(5);
  @$pb.TagNumber(6)
  void clearIterations() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get parallelism => $_getIZ(6);
  @$pb.TagNumber(7)
  set parallelism($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasParallelism() => $_has(6);
  @$pb.TagNumber(7)
  void clearParallelism() => $_clearField(7);

  /// Payload format version, so an old backup stays restorable.
  @$pb.TagNumber(8)
  $core.String get version => $_getSZ(7);
  @$pb.TagNumber(8)
  set version($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasVersion() => $_has(7);
  @$pb.TagNumber(8)
  void clearVersion() => $_clearField(8);

  @$pb.TagNumber(9)
  $0.Timestamp get updatedAt => $_getN(8);
  @$pb.TagNumber(9)
  set updatedAt($0.Timestamp value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasUpdatedAt() => $_has(8);
  @$pb.TagNumber(9)
  void clearUpdatedAt() => $_clearField(9);
  @$pb.TagNumber(9)
  $0.Timestamp ensureUpdatedAt() => $_ensure(8);
}

class PutKeyBackupRequest extends $pb.GeneratedMessage {
  factory PutKeyBackupRequest({
    KeyBackup? backup,
  }) {
    final result = PutKeyBackupRequest._();
    if (backup != null) result.backup = backup;
    return result;
  }

  PutKeyBackupRequest._();

  factory PutKeyBackupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutKeyBackupRequest()..mergeFromBuffer(data, registry);
  factory PutKeyBackupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutKeyBackupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PutKeyBackupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: PutKeyBackupRequest.$_createMessage)
    ..aOM<KeyBackup>(1, _omitFieldNames ? '' : 'backup',
        subBuilder: KeyBackup.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutKeyBackupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutKeyBackupRequest copyWith(void Function(PutKeyBackupRequest) updates) =>
      super.copyWith((message) => updates(message as PutKeyBackupRequest))
          as PutKeyBackupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use PutKeyBackupRequest() / PutKeyBackupRequest.new instead')
  static PutKeyBackupRequest create() => PutKeyBackupRequest._();
  static $pb.GeneratedMessage $_createMessage() => PutKeyBackupRequest._();
  @$core.override
  PutKeyBackupRequest createEmptyInstance() => PutKeyBackupRequest._();
  @$core.pragma('dart2js:noInline')
  static PutKeyBackupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PutKeyBackupRequest>(
          PutKeyBackupRequest.$_createMessage);
  static PutKeyBackupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  KeyBackup get backup => $_getN(0);
  @$pb.TagNumber(1)
  set backup(KeyBackup value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBackup() => $_has(0);
  @$pb.TagNumber(1)
  void clearBackup() => $_clearField(1);
  @$pb.TagNumber(1)
  KeyBackup ensureBackup() => $_ensure(0);
}

class PutKeyBackupResponse extends $pb.GeneratedMessage {
  factory PutKeyBackupResponse({
    KeyBackup? backup,
  }) {
    final result = PutKeyBackupResponse._();
    if (backup != null) result.backup = backup;
    return result;
  }

  PutKeyBackupResponse._();

  factory PutKeyBackupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutKeyBackupResponse()..mergeFromBuffer(data, registry);
  factory PutKeyBackupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutKeyBackupResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PutKeyBackupResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: PutKeyBackupResponse.$_createMessage)
    ..aOM<KeyBackup>(1, _omitFieldNames ? '' : 'backup',
        subBuilder: KeyBackup.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutKeyBackupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutKeyBackupResponse copyWith(void Function(PutKeyBackupResponse) updates) =>
      super.copyWith((message) => updates(message as PutKeyBackupResponse))
          as PutKeyBackupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PutKeyBackupResponse() / PutKeyBackupResponse.new instead')
  static PutKeyBackupResponse create() => PutKeyBackupResponse._();
  static $pb.GeneratedMessage $_createMessage() => PutKeyBackupResponse._();
  @$core.override
  PutKeyBackupResponse createEmptyInstance() => PutKeyBackupResponse._();
  @$core.pragma('dart2js:noInline')
  static PutKeyBackupResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PutKeyBackupResponse>(
          PutKeyBackupResponse.$_createMessage);
  static PutKeyBackupResponse? _defaultInstance;

  @$pb.TagNumber(1)
  KeyBackup get backup => $_getN(0);
  @$pb.TagNumber(1)
  set backup(KeyBackup value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBackup() => $_has(0);
  @$pb.TagNumber(1)
  void clearBackup() => $_clearField(1);
  @$pb.TagNumber(1)
  KeyBackup ensureBackup() => $_ensure(0);
}

class GetKeyBackupRequest extends $pb.GeneratedMessage {
  factory GetKeyBackupRequest() => GetKeyBackupRequest._();

  GetKeyBackupRequest._();

  factory GetKeyBackupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetKeyBackupRequest()..mergeFromBuffer(data, registry);
  factory GetKeyBackupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetKeyBackupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetKeyBackupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: GetKeyBackupRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKeyBackupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKeyBackupRequest copyWith(void Function(GetKeyBackupRequest) updates) =>
      super.copyWith((message) => updates(message as GetKeyBackupRequest))
          as GetKeyBackupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use GetKeyBackupRequest() / GetKeyBackupRequest.new instead')
  static GetKeyBackupRequest create() => GetKeyBackupRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetKeyBackupRequest._();
  @$core.override
  GetKeyBackupRequest createEmptyInstance() => GetKeyBackupRequest._();
  @$core.pragma('dart2js:noInline')
  static GetKeyBackupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetKeyBackupRequest>(
          GetKeyBackupRequest.$_createMessage);
  static GetKeyBackupRequest? _defaultInstance;
}

/// Absent when the account has no backup yet, which is the normal state.
class GetKeyBackupResponse extends $pb.GeneratedMessage {
  factory GetKeyBackupResponse({
    KeyBackup? backup,
  }) {
    final result = GetKeyBackupResponse._();
    if (backup != null) result.backup = backup;
    return result;
  }

  GetKeyBackupResponse._();

  factory GetKeyBackupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetKeyBackupResponse()..mergeFromBuffer(data, registry);
  factory GetKeyBackupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetKeyBackupResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetKeyBackupResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: GetKeyBackupResponse.$_createMessage)
    ..aOM<KeyBackup>(1, _omitFieldNames ? '' : 'backup',
        subBuilder: KeyBackup.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKeyBackupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKeyBackupResponse copyWith(void Function(GetKeyBackupResponse) updates) =>
      super.copyWith((message) => updates(message as GetKeyBackupResponse))
          as GetKeyBackupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetKeyBackupResponse() / GetKeyBackupResponse.new instead')
  static GetKeyBackupResponse create() => GetKeyBackupResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetKeyBackupResponse._();
  @$core.override
  GetKeyBackupResponse createEmptyInstance() => GetKeyBackupResponse._();
  @$core.pragma('dart2js:noInline')
  static GetKeyBackupResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetKeyBackupResponse>(
          GetKeyBackupResponse.$_createMessage);
  static GetKeyBackupResponse? _defaultInstance;

  @$pb.TagNumber(1)
  KeyBackup get backup => $_getN(0);
  @$pb.TagNumber(1)
  set backup(KeyBackup value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBackup() => $_has(0);
  @$pb.TagNumber(1)
  void clearBackup() => $_clearField(1);
  @$pb.TagNumber(1)
  KeyBackup ensureBackup() => $_ensure(0);
}

class DeleteKeyBackupRequest extends $pb.GeneratedMessage {
  factory DeleteKeyBackupRequest() => DeleteKeyBackupRequest._();

  DeleteKeyBackupRequest._();

  factory DeleteKeyBackupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteKeyBackupRequest()..mergeFromBuffer(data, registry);
  factory DeleteKeyBackupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteKeyBackupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteKeyBackupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: DeleteKeyBackupRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteKeyBackupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteKeyBackupRequest copyWith(
          void Function(DeleteKeyBackupRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteKeyBackupRequest))
          as DeleteKeyBackupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DeleteKeyBackupRequest() / DeleteKeyBackupRequest.new instead')
  static DeleteKeyBackupRequest create() => DeleteKeyBackupRequest._();
  static $pb.GeneratedMessage $_createMessage() => DeleteKeyBackupRequest._();
  @$core.override
  DeleteKeyBackupRequest createEmptyInstance() => DeleteKeyBackupRequest._();
  @$core.pragma('dart2js:noInline')
  static DeleteKeyBackupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteKeyBackupRequest>(
          DeleteKeyBackupRequest.$_createMessage);
  static DeleteKeyBackupRequest? _defaultInstance;
}

class DeleteKeyBackupResponse extends $pb.GeneratedMessage {
  factory DeleteKeyBackupResponse() => DeleteKeyBackupResponse._();

  DeleteKeyBackupResponse._();

  factory DeleteKeyBackupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteKeyBackupResponse()..mergeFromBuffer(data, registry);
  factory DeleteKeyBackupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteKeyBackupResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteKeyBackupResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: DeleteKeyBackupResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteKeyBackupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteKeyBackupResponse copyWith(
          void Function(DeleteKeyBackupResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteKeyBackupResponse))
          as DeleteKeyBackupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DeleteKeyBackupResponse() / DeleteKeyBackupResponse.new instead')
  static DeleteKeyBackupResponse create() => DeleteKeyBackupResponse._();
  static $pb.GeneratedMessage $_createMessage() => DeleteKeyBackupResponse._();
  @$core.override
  DeleteKeyBackupResponse createEmptyInstance() => DeleteKeyBackupResponse._();
  @$core.pragma('dart2js:noInline')
  static DeleteKeyBackupResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteKeyBackupResponse>(
          DeleteKeyBackupResponse.$_createMessage);
  static DeleteKeyBackupResponse? _defaultInstance;
}

/// The public half of the end-to-end encryption keys, plus the key envelopes
/// that distribute group sender keys. See docs/E2EE.md for the protocol itself.
///
/// Nothing here is secret. The server is a directory for public keys and an
/// opaque mailbox for wrapped sender keys; it can neither read a message nor
/// forge a key envelope.
class KeyServiceApi {
  final $pb.RpcClient _client;

  KeyServiceApi(this._client);

  /// Publish (or update) this device's public keys. Idempotent per key id, so a
  /// client may call it on every start.
  $async.Future<PublishDeviceKeyResponse> publishDeviceKey(
          $pb.ClientContext? ctx, PublishDeviceKeyRequest request) =>
      _client.invoke<PublishDeviceKeyResponse>(ctx, 'KeyService',
          'PublishDeviceKey', request, PublishDeviceKeyResponse());

  /// The device keys of the named users. Clients need this before they can
  /// encrypt anything, so it is one call for a whole member list.
  $async.Future<ListDeviceKeysResponse> listDeviceKeys(
          $pb.ClientContext? ctx, ListDeviceKeysRequest request) =>
      _client.invoke<ListDeviceKeysResponse>(ctx, 'KeyService',
          'ListDeviceKeys', request, ListDeviceKeysResponse());

  /// Stop using a device key: it disappears from ListDeviceKeys. Messages
  /// already encrypted to it stay unreadable, which is the point.
  $async.Future<RevokeDeviceKeyResponse> revokeDeviceKey(
          $pb.ClientContext? ctx, RevokeDeviceKeyRequest request) =>
      _client.invoke<RevokeDeviceKeyResponse>(ctx, 'KeyService',
          'RevokeDeviceKey', request, RevokeDeviceKeyResponse());

  /// Deposit a wrapped sender key for one recipient device. The receiver finds
  /// it with ListKeyEnvelopes.
  $async.Future<PutKeyEnvelopeResponse> putKeyEnvelope(
          $pb.ClientContext? ctx, PutKeyEnvelopeRequest request) =>
      _client.invoke<PutKeyEnvelopeResponse>(ctx, 'KeyService',
          'PutKeyEnvelope', request, PutKeyEnvelopeResponse());

  /// The envelopes addressed to this device, newest first. `since` makes the
  /// call cheap to repeat.
  $async.Future<ListKeyEnvelopesResponse> listKeyEnvelopes(
          $pb.ClientContext? ctx, ListKeyEnvelopesRequest request) =>
      _client.invoke<ListKeyEnvelopesResponse>(ctx, 'KeyService',
          'ListKeyEnvelopes', request, ListKeyEnvelopesResponse());

  /// The account's encrypted key backup: an opaque blob this server can neither
  /// read nor usefully alter.
  ///
  /// It exists because device private keys live only in that device's keystore, so
  /// reinstalling the app permanently loses the ability to open old history. The
  /// blob is sealed on the device with a key derived from a passphrase the user
  /// chooses; the passphrase is never sent here, so a compromised server yields
  /// nothing.
  $async.Future<PutKeyBackupResponse> putKeyBackup(
          $pb.ClientContext? ctx, PutKeyBackupRequest request) =>
      _client.invoke<PutKeyBackupResponse>(
          ctx, 'KeyService', 'PutKeyBackup', request, PutKeyBackupResponse());
  $async.Future<GetKeyBackupResponse> getKeyBackup(
          $pb.ClientContext? ctx, GetKeyBackupRequest request) =>
      _client.invoke<GetKeyBackupResponse>(
          ctx, 'KeyService', 'GetKeyBackup', request, GetKeyBackupResponse());
  $async.Future<DeleteKeyBackupResponse> deleteKeyBackup(
          $pb.ClientContext? ctx, DeleteKeyBackupRequest request) =>
      _client.invoke<DeleteKeyBackupResponse>(ctx, 'KeyService',
          'DeleteKeyBackup', request, DeleteKeyBackupResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
