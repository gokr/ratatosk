// This is a generated file - do not edit.
//
// Generated from ratatosk/v1/common.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $0;

import 'common.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'common.pbenum.dart';

/// A user account. Never carries credentials.
class User extends $pb.GeneratedMessage {
  factory User({
    $core.String? id,
    $core.String? username,
    $core.String? displayName,
    $core.String? avatarUrl,
    $core.String? bio,
    Presence? presence,
    $0.Timestamp? lastSeen,
    $core.String? accentColor,
  }) {
    final result = User._();
    if (id != null) result.id = id;
    if (username != null) result.username = username;
    if (displayName != null) result.displayName = displayName;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    if (bio != null) result.bio = bio;
    if (presence != null) result.presence = presence;
    if (lastSeen != null) result.lastSeen = lastSeen;
    if (accentColor != null) result.accentColor = accentColor;
    return result;
  }

  User._();

  factory User.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      User()..mergeFromBuffer(data, registry);
  factory User.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      User()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'User',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: User.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(3, _omitFieldNames ? '' : 'displayName')
    ..aOS(4, _omitFieldNames ? '' : 'avatarUrl')
    ..aOS(5, _omitFieldNames ? '' : 'bio')
    ..aE<Presence>(6, _omitFieldNames ? '' : 'presence',
        enumValues: Presence.values)
    ..aOM<$0.Timestamp>(7, _omitFieldNames ? '' : 'lastSeen',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOS(8, _omitFieldNames ? '' : 'accentColor')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  User clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  User copyWith(void Function(User) updates) =>
      super.copyWith((message) => updates(message as User)) as User;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use User() / User.new instead')
  static User create() => User._();
  static $pb.GeneratedMessage $_createMessage() => User._();
  @$core.override
  User createEmptyInstance() => User._();
  @$core.pragma('dart2js:noInline')
  static User getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<User>(User.$_createMessage);
  static User? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Unique handle, lowercase, used to find people and to log in.
  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get displayName => $_getSZ(2);
  @$pb.TagNumber(3)
  set displayName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDisplayName() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisplayName() => $_clearField(3);

  /// URL path of the profile picture attachment, empty when unset.
  @$pb.TagNumber(4)
  $core.String get avatarUrl => $_getSZ(3);
  @$pb.TagNumber(4)
  set avatarUrl($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAvatarUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearAvatarUrl() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get bio => $_getSZ(4);
  @$pb.TagNumber(5)
  set bio($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBio() => $_has(4);
  @$pb.TagNumber(5)
  void clearBio() => $_clearField(5);

  @$pb.TagNumber(6)
  Presence get presence => $_getN(5);
  @$pb.TagNumber(6)
  set presence(Presence value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasPresence() => $_has(5);
  @$pb.TagNumber(6)
  void clearPresence() => $_clearField(6);

  @$pb.TagNumber(7)
  $0.Timestamp get lastSeen => $_getN(6);
  @$pb.TagNumber(7)
  set lastSeen($0.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasLastSeen() => $_has(6);
  @$pb.TagNumber(7)
  void clearLastSeen() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.Timestamp ensureLastSeen() => $_ensure(6);

  /// Stable hex color derived from the user id, used to render initials
  /// avatars and conversation accents when no picture is set.
  @$pb.TagNumber(8)
  $core.String get accentColor => $_getSZ(7);
  @$pb.TagNumber(8)
  set accentColor($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAccentColor() => $_has(7);
  @$pb.TagNumber(8)
  void clearAccentColor() => $_clearField(8);
}

/// A stored file. Bytes live on disk on the server; clients only see the URL.
///
/// With end-to-end encryption the stored bytes are ciphertext and the original
/// filename and content type travel inside the message's sealed content, so the
/// server sees neither. The fields here are then the server's own view:
/// `filename` is the opaque blob id, `content_type` is
/// "application/octet-stream", and `encrypted` is true. Clients read the real
/// values from the decrypted envelope (docs/E2EE.md).
class Attachment extends $pb.GeneratedMessage {
  factory Attachment({
    $core.String? id,
    $core.String? filename,
    $core.String? contentType,
    $fixnum.Int64? size,
    $core.String? url,
    $core.int? width,
    $core.int? height,
    $core.bool? isImage,
    $core.bool? encrypted,
  }) {
    final result = Attachment._();
    if (id != null) result.id = id;
    if (filename != null) result.filename = filename;
    if (contentType != null) result.contentType = contentType;
    if (size != null) result.size = size;
    if (url != null) result.url = url;
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (isImage != null) result.isImage = isImage;
    if (encrypted != null) result.encrypted = encrypted;
    return result;
  }

  Attachment._();

  factory Attachment.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Attachment()..mergeFromBuffer(data, registry);
  factory Attachment.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Attachment()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Attachment',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: Attachment.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'filename')
    ..aOS(3, _omitFieldNames ? '' : 'contentType')
    ..aInt64(4, _omitFieldNames ? '' : 'size')
    ..aOS(5, _omitFieldNames ? '' : 'url')
    ..aI(6, _omitFieldNames ? '' : 'width')
    ..aI(7, _omitFieldNames ? '' : 'height')
    ..aOB(8, _omitFieldNames ? '' : 'isImage')
    ..aOB(9, _omitFieldNames ? '' : 'encrypted')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Attachment clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Attachment copyWith(void Function(Attachment) updates) =>
      super.copyWith((message) => updates(message as Attachment)) as Attachment;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Attachment() / Attachment.new instead')
  static Attachment create() => Attachment._();
  static $pb.GeneratedMessage $_createMessage() => Attachment._();
  @$core.override
  Attachment createEmptyInstance() => Attachment._();
  @$core.pragma('dart2js:noInline')
  static Attachment getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Attachment>(Attachment.$_createMessage);
  static Attachment? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get filename => $_getSZ(1);
  @$pb.TagNumber(2)
  set filename($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFilename() => $_has(1);
  @$pb.TagNumber(2)
  void clearFilename() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get contentType => $_getSZ(2);
  @$pb.TagNumber(3)
  set contentType($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContentType() => $_has(2);
  @$pb.TagNumber(3)
  void clearContentType() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get size => $_getI64(3);
  @$pb.TagNumber(4)
  set size($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearSize() => $_clearField(4);

  /// Server-relative path, e.g. "/files/8f1c...". Clients append their own
  /// origin and auth token.
  @$pb.TagNumber(5)
  $core.String get url => $_getSZ(4);
  @$pb.TagNumber(5)
  set url($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearUrl() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get width => $_getIZ(5);
  @$pb.TagNumber(6)
  set width($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasWidth() => $_has(5);
  @$pb.TagNumber(6)
  void clearWidth() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get height => $_getIZ(6);
  @$pb.TagNumber(7)
  set height($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasHeight() => $_has(6);
  @$pb.TagNumber(7)
  void clearHeight() => $_clearField(7);

  /// True for content types under image/.
  @$pb.TagNumber(8)
  $core.bool get isImage => $_getBF(7);
  @$pb.TagNumber(8)
  set isImage($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIsImage() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsImage() => $_clearField(8);

  /// The bytes on the server are a client-side seal, not the file itself.
  @$pb.TagNumber(9)
  $core.bool get encrypted => $_getBF(8);
  @$pb.TagNumber(9)
  set encrypted($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasEncrypted() => $_has(8);
  @$pb.TagNumber(9)
  void clearEncrypted() => $_clearField(9);
}

/// A compact quote of the message being replied to.
class ReplyPreview extends $pb.GeneratedMessage {
  factory ReplyPreview({
    $core.String? messageId,
    $core.String? senderId,
    $core.String? senderName,
    $core.String? text,
    $core.bool? deleted,
    $core.bool? hasAttachment,
  }) {
    final result = ReplyPreview._();
    if (messageId != null) result.messageId = messageId;
    if (senderId != null) result.senderId = senderId;
    if (senderName != null) result.senderName = senderName;
    if (text != null) result.text = text;
    if (deleted != null) result.deleted = deleted;
    if (hasAttachment != null) result.hasAttachment = hasAttachment;
    return result;
  }

  ReplyPreview._();

  factory ReplyPreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReplyPreview()..mergeFromBuffer(data, registry);
  factory ReplyPreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReplyPreview()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReplyPreview',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: ReplyPreview.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'senderId')
    ..aOS(3, _omitFieldNames ? '' : 'senderName')
    ..aOS(4, _omitFieldNames ? '' : 'text')
    ..aOB(5, _omitFieldNames ? '' : 'deleted')
    ..aOB(6, _omitFieldNames ? '' : 'hasAttachment')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplyPreview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplyPreview copyWith(void Function(ReplyPreview) updates) =>
      super.copyWith((message) => updates(message as ReplyPreview))
          as ReplyPreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReplyPreview() / ReplyPreview.new instead')
  static ReplyPreview create() => ReplyPreview._();
  static $pb.GeneratedMessage $_createMessage() => ReplyPreview._();
  @$core.override
  ReplyPreview createEmptyInstance() => ReplyPreview._();
  @$core.pragma('dart2js:noInline')
  static ReplyPreview getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReplyPreview>(
          ReplyPreview.$_createMessage);
  static ReplyPreview? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get senderId => $_getSZ(1);
  @$pb.TagNumber(2)
  set senderId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSenderId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSenderId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get senderName => $_getSZ(2);
  @$pb.TagNumber(3)
  set senderName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSenderName() => $_has(2);
  @$pb.TagNumber(3)
  void clearSenderName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get text => $_getSZ(3);
  @$pb.TagNumber(4)
  set text($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasText() => $_has(3);
  @$pb.TagNumber(4)
  void clearText() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get deleted => $_getBF(4);
  @$pb.TagNumber(5)
  set deleted($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDeleted() => $_has(4);
  @$pb.TagNumber(5)
  void clearDeleted() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get hasAttachment => $_getBF(5);
  @$pb.TagNumber(6)
  set hasAttachment($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasHasAttachment() => $_has(5);
  @$pb.TagNumber(6)
  void clearHasAttachment() => $_clearField(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
