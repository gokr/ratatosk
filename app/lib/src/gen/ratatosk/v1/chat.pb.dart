// This is a generated file - do not edit.
//
// Generated from ratatosk/v1/chat.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $1;

import 'chat.pbenum.dart';
import 'common.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'chat.pbenum.dart';

/// Reaction to a message: one emoji, the users who picked it.
class Reaction extends $pb.GeneratedMessage {
  factory Reaction({
    $core.String? emoji,
    $core.Iterable<$core.String>? userIds,
  }) {
    final result = Reaction._();
    if (emoji != null) result.emoji = emoji;
    if (userIds != null) result.userIds.addAll(userIds);
    return result;
  }

  Reaction._();

  factory Reaction.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Reaction()..mergeFromBuffer(data, registry);
  factory Reaction.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Reaction()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Reaction',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: Reaction.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'emoji')
    ..pPS(2, _omitFieldNames ? '' : 'userIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Reaction clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Reaction copyWith(void Function(Reaction) updates) =>
      super.copyWith((message) => updates(message as Reaction)) as Reaction;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Reaction() / Reaction.new instead')
  static Reaction create() => Reaction._();
  static $pb.GeneratedMessage $_createMessage() => Reaction._();
  @$core.override
  Reaction createEmptyInstance() => Reaction._();
  @$core.pragma('dart2js:noInline')
  static Reaction getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Reaction>(Reaction.$_createMessage);
  static Reaction? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get emoji => $_getSZ(0);
  @$pb.TagNumber(1)
  set emoji($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEmoji() => $_has(0);
  @$pb.TagNumber(1)
  void clearEmoji() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get userIds => $_getList(1);
}

class Message extends $pb.GeneratedMessage {
  factory Message({
    $core.String? id,
    $core.String? conversationId,
    $core.String? senderId,
    $core.String? text,
    $core.Iterable<$0.Attachment>? attachments,
    $1.Timestamp? createdAt,
    $1.Timestamp? editedAt,
    $core.bool? deleted,
    $core.Iterable<Reaction>? reactions,
    $core.String? clientMessageId,
    MessageKind? kind,
    $fixnum.Int64? seq,
    $0.ReplyPreview? replyTo,
    $core.String? replyToId,
    $core.List<$core.int>? ciphertext,
    $core.List<$core.int>? nonce,
    $core.String? senderDeviceKeyId,
    $core.int? keyEpoch,
    $core.bool? encrypted,
    $core.String? cryptoVersion,
  }) {
    final result = Message._();
    if (id != null) result.id = id;
    if (conversationId != null) result.conversationId = conversationId;
    if (senderId != null) result.senderId = senderId;
    if (text != null) result.text = text;
    if (attachments != null) result.attachments.addAll(attachments);
    if (createdAt != null) result.createdAt = createdAt;
    if (editedAt != null) result.editedAt = editedAt;
    if (deleted != null) result.deleted = deleted;
    if (reactions != null) result.reactions.addAll(reactions);
    if (clientMessageId != null) result.clientMessageId = clientMessageId;
    if (kind != null) result.kind = kind;
    if (seq != null) result.seq = seq;
    if (replyTo != null) result.replyTo = replyTo;
    if (replyToId != null) result.replyToId = replyToId;
    if (ciphertext != null) result.ciphertext = ciphertext;
    if (nonce != null) result.nonce = nonce;
    if (senderDeviceKeyId != null) result.senderDeviceKeyId = senderDeviceKeyId;
    if (keyEpoch != null) result.keyEpoch = keyEpoch;
    if (encrypted != null) result.encrypted = encrypted;
    if (cryptoVersion != null) result.cryptoVersion = cryptoVersion;
    return result;
  }

  Message._();

  factory Message.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Message()..mergeFromBuffer(data, registry);
  factory Message.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Message()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Message',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: Message.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'conversationId')
    ..aOS(3, _omitFieldNames ? '' : 'senderId')
    ..aOS(4, _omitFieldNames ? '' : 'text')
    ..pPM<$0.Attachment>(5, _omitFieldNames ? '' : 'attachments',
        subBuilder: $0.Attachment.$_createMessage)
    ..aOM<$1.Timestamp>(6, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aOM<$1.Timestamp>(7, _omitFieldNames ? '' : 'editedAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aOB(8, _omitFieldNames ? '' : 'deleted')
    ..pPM<Reaction>(9, _omitFieldNames ? '' : 'reactions',
        subBuilder: Reaction.$_createMessage)
    ..aOS(10, _omitFieldNames ? '' : 'clientMessageId')
    ..aE<MessageKind>(11, _omitFieldNames ? '' : 'kind',
        enumValues: MessageKind.values)
    ..aInt64(12, _omitFieldNames ? '' : 'seq')
    ..aOM<$0.ReplyPreview>(13, _omitFieldNames ? '' : 'replyTo',
        subBuilder: $0.ReplyPreview.$_createMessage)
    ..aOS(14, _omitFieldNames ? '' : 'replyToId')
    ..a<$core.List<$core.int>>(
        15, _omitFieldNames ? '' : 'ciphertext', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        16, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..aOS(17, _omitFieldNames ? '' : 'senderDeviceKeyId')
    ..aI(18, _omitFieldNames ? '' : 'keyEpoch')
    ..aOB(19, _omitFieldNames ? '' : 'encrypted')
    ..aOS(20, _omitFieldNames ? '' : 'cryptoVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Message clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Message copyWith(void Function(Message) updates) =>
      super.copyWith((message) => updates(message as Message)) as Message;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Message() / Message.new instead')
  static Message create() => Message._();
  static $pb.GeneratedMessage $_createMessage() => Message._();
  @$core.override
  Message createEmptyInstance() => Message._();
  @$core.pragma('dart2js:noInline')
  static Message getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Message>(Message.$_createMessage);
  static Message? _defaultInstance;

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

  @$pb.TagNumber(3)
  $core.String get senderId => $_getSZ(2);
  @$pb.TagNumber(3)
  set senderId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSenderId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSenderId() => $_clearField(3);

  /// Plain text, used only for server-authored system notes ("Ada added
  /// Grace") and for messages written before encryption was introduced. User
  /// messages carry their text inside `ciphertext` instead.
  @$pb.TagNumber(4)
  $core.String get text => $_getSZ(3);
  @$pb.TagNumber(4)
  set text($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasText() => $_has(3);
  @$pb.TagNumber(4)
  void clearText() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$0.Attachment> get attachments => $_getList(4);

  @$pb.TagNumber(6)
  $1.Timestamp get createdAt => $_getN(5);
  @$pb.TagNumber(6)
  set createdAt($1.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasCreatedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreatedAt() => $_clearField(6);
  @$pb.TagNumber(6)
  $1.Timestamp ensureCreatedAt() => $_ensure(5);

  /// Set when the text was rewritten after sending.
  @$pb.TagNumber(7)
  $1.Timestamp get editedAt => $_getN(6);
  @$pb.TagNumber(7)
  set editedAt($1.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasEditedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearEditedAt() => $_clearField(7);
  @$pb.TagNumber(7)
  $1.Timestamp ensureEditedAt() => $_ensure(6);

  /// Tombstone: content is cleared, the row keeps its place.
  @$pb.TagNumber(8)
  $core.bool get deleted => $_getBF(7);
  @$pb.TagNumber(8)
  set deleted($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDeleted() => $_has(7);
  @$pb.TagNumber(8)
  void clearDeleted() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<Reaction> get reactions => $_getList(8);

  /// Idempotency key supplied by the sender.
  @$pb.TagNumber(10)
  $core.String get clientMessageId => $_getSZ(9);
  @$pb.TagNumber(10)
  set clientMessageId($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasClientMessageId() => $_has(9);
  @$pb.TagNumber(10)
  void clearClientMessageId() => $_clearField(10);

  @$pb.TagNumber(11)
  MessageKind get kind => $_getN(10);
  @$pb.TagNumber(11)
  set kind(MessageKind value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasKind() => $_has(10);
  @$pb.TagNumber(11)
  void clearKind() => $_clearField(11);

  /// Position in the conversation; strictly increasing, gapless per view.
  @$pb.TagNumber(12)
  $fixnum.Int64 get seq => $_getI64(11);
  @$pb.TagNumber(12)
  set seq($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasSeq() => $_has(11);
  @$pb.TagNumber(12)
  void clearSeq() => $_clearField(12);

  @$pb.TagNumber(13)
  $0.ReplyPreview get replyTo => $_getN(12);
  @$pb.TagNumber(13)
  set replyTo($0.ReplyPreview value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasReplyTo() => $_has(12);
  @$pb.TagNumber(13)
  void clearReplyTo() => $_clearField(13);
  @$pb.TagNumber(13)
  $0.ReplyPreview ensureReplyTo() => $_ensure(12);

  /// The message being replied to, for sends and for clients that need it.
  @$pb.TagNumber(14)
  $core.String get replyToId => $_getSZ(13);
  @$pb.TagNumber(14)
  set replyToId($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasReplyToId() => $_has(13);
  @$pb.TagNumber(14)
  void clearReplyToId() => $_clearField(14);

  /// XChaCha20-Poly1305 seal of the message content: text, attachments and the
  /// reply preview all live in here. Empty for system notes and for
  /// unencrypted legacy messages. The server never holds the key.
  @$pb.TagNumber(15)
  $core.List<$core.int> get ciphertext => $_getN(14);
  @$pb.TagNumber(15)
  set ciphertext($core.List<$core.int> value) => $_setBytes(14, value);
  @$pb.TagNumber(15)
  $core.bool hasCiphertext() => $_has(14);
  @$pb.TagNumber(15)
  void clearCiphertext() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.List<$core.int> get nonce => $_getN(15);
  @$pb.TagNumber(16)
  set nonce($core.List<$core.int> value) => $_setBytes(15, value);
  @$pb.TagNumber(16)
  $core.bool hasNonce() => $_has(15);
  @$pb.TagNumber(16)
  void clearNonce() => $_clearField(16);

  /// Which device's sender key sealed this. In a direct conversation the key is
  /// derived from both identity keys, so the field is informational there; in a
  /// group it names the sender key to unwrap. With `key_epoch` it identifies
  /// the key to try.
  @$pb.TagNumber(17)
  $core.String get senderDeviceKeyId => $_getSZ(16);
  @$pb.TagNumber(17)
  set senderDeviceKeyId($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasSenderDeviceKeyId() => $_has(16);
  @$pb.TagNumber(17)
  void clearSenderDeviceKeyId() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.int get keyEpoch => $_getIZ(17);
  @$pb.TagNumber(18)
  set keyEpoch($core.int value) => $_setSignedInt32(17, value);
  @$pb.TagNumber(18)
  $core.bool hasKeyEpoch() => $_has(17);
  @$pb.TagNumber(18)
  void clearKeyEpoch() => $_clearField(18);

  /// True when `ciphertext` holds the content, which means `text`, `attachments`
  /// and `reply_to` are empty on the wire.
  @$pb.TagNumber(19)
  $core.bool get encrypted => $_getBF(18);
  @$pb.TagNumber(19)
  set encrypted($core.bool value) => $_setBool(18, value);
  @$pb.TagNumber(19)
  $core.bool hasEncrypted() => $_has(18);
  @$pb.TagNumber(19)
  void clearEncrypted() => $_clearField(19);

  /// Encryption scheme that produced the ciphertext, e.g. "ratatosk/v1".
  @$pb.TagNumber(20)
  $core.String get cryptoVersion => $_getSZ(19);
  @$pb.TagNumber(20)
  set cryptoVersion($core.String value) => $_setString(19, value);
  @$pb.TagNumber(20)
  $core.bool hasCryptoVersion() => $_has(19);
  @$pb.TagNumber(20)
  void clearCryptoVersion() => $_clearField(20);
}

/// A conversation participant, from the viewer's point of view.
class Member extends $pb.GeneratedMessage {
  factory Member({
    $0.User? user,
    $core.String? role,
    $1.Timestamp? joinedAt,
    $fixnum.Int64? lastReadSeq,
    $1.Timestamp? lastReadAt,
    $core.bool? muted,
    $core.bool? pinned,
  }) {
    final result = Member._();
    if (user != null) result.user = user;
    if (role != null) result.role = role;
    if (joinedAt != null) result.joinedAt = joinedAt;
    if (lastReadSeq != null) result.lastReadSeq = lastReadSeq;
    if (lastReadAt != null) result.lastReadAt = lastReadAt;
    if (muted != null) result.muted = muted;
    if (pinned != null) result.pinned = pinned;
    return result;
  }

  Member._();

  factory Member.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Member()..mergeFromBuffer(data, registry);
  factory Member.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Member()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Member',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: Member.$_createMessage)
    ..aOM<$0.User>(1, _omitFieldNames ? '' : 'user',
        subBuilder: $0.User.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'role')
    ..aOM<$1.Timestamp>(3, _omitFieldNames ? '' : 'joinedAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aInt64(4, _omitFieldNames ? '' : 'lastReadSeq')
    ..aOM<$1.Timestamp>(5, _omitFieldNames ? '' : 'lastReadAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aOB(6, _omitFieldNames ? '' : 'muted')
    ..aOB(7, _omitFieldNames ? '' : 'pinned')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Member clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Member copyWith(void Function(Member) updates) =>
      super.copyWith((message) => updates(message as Member)) as Member;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Member() / Member.new instead')
  static Member create() => Member._();
  static $pb.GeneratedMessage $_createMessage() => Member._();
  @$core.override
  Member createEmptyInstance() => Member._();
  @$core.pragma('dart2js:noInline')
  static Member getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Member>(Member.$_createMessage);
  static Member? _defaultInstance;

  @$pb.TagNumber(1)
  $0.User get user => $_getN(0);
  @$pb.TagNumber(1)
  set user($0.User value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasUser() => $_has(0);
  @$pb.TagNumber(1)
  void clearUser() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.User ensureUser() => $_ensure(0);

  /// "owner" for the creator of a group, "member" otherwise.
  @$pb.TagNumber(2)
  $core.String get role => $_getSZ(1);
  @$pb.TagNumber(2)
  set role($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRole() => $_has(1);
  @$pb.TagNumber(2)
  void clearRole() => $_clearField(2);

  @$pb.TagNumber(3)
  $1.Timestamp get joinedAt => $_getN(2);
  @$pb.TagNumber(3)
  set joinedAt($1.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasJoinedAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearJoinedAt() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.Timestamp ensureJoinedAt() => $_ensure(2);

  /// Highest seq this member has read.
  @$pb.TagNumber(4)
  $fixnum.Int64 get lastReadSeq => $_getI64(3);
  @$pb.TagNumber(4)
  set lastReadSeq($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLastReadSeq() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastReadSeq() => $_clearField(4);

  @$pb.TagNumber(5)
  $1.Timestamp get lastReadAt => $_getN(4);
  @$pb.TagNumber(5)
  set lastReadAt($1.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasLastReadAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastReadAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.Timestamp ensureLastReadAt() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.bool get muted => $_getBF(5);
  @$pb.TagNumber(6)
  set muted($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMuted() => $_has(5);
  @$pb.TagNumber(6)
  void clearMuted() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get pinned => $_getBF(6);
  @$pb.TagNumber(7)
  set pinned($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPinned() => $_has(6);
  @$pb.TagNumber(7)
  void clearPinned() => $_clearField(7);
}

class Conversation extends $pb.GeneratedMessage {
  factory Conversation({
    $core.String? id,
    $core.String? kind,
    $core.String? title,
    $core.String? avatarUrl,
    $core.Iterable<Member>? members,
    Message? lastMessage,
    $core.int? unreadCount,
    $1.Timestamp? createdAt,
    $1.Timestamp? updatedAt,
    $core.String? createdBy,
    $fixnum.Int64? lastSeq,
    $core.bool? muted,
    $core.bool? pinned,
    $core.String? accentColor,
    $0.User? peer,
  }) {
    final result = Conversation._();
    if (id != null) result.id = id;
    if (kind != null) result.kind = kind;
    if (title != null) result.title = title;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    if (members != null) result.members.addAll(members);
    if (lastMessage != null) result.lastMessage = lastMessage;
    if (unreadCount != null) result.unreadCount = unreadCount;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (createdBy != null) result.createdBy = createdBy;
    if (lastSeq != null) result.lastSeq = lastSeq;
    if (muted != null) result.muted = muted;
    if (pinned != null) result.pinned = pinned;
    if (accentColor != null) result.accentColor = accentColor;
    if (peer != null) result.peer = peer;
    return result;
  }

  Conversation._();

  factory Conversation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Conversation()..mergeFromBuffer(data, registry);
  factory Conversation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Conversation()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Conversation',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: Conversation.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'kind')
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'avatarUrl')
    ..pPM<Member>(5, _omitFieldNames ? '' : 'members',
        subBuilder: Member.$_createMessage)
    ..aOM<Message>(6, _omitFieldNames ? '' : 'lastMessage',
        subBuilder: Message.$_createMessage)
    ..aI(7, _omitFieldNames ? '' : 'unreadCount')
    ..aOM<$1.Timestamp>(8, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aOM<$1.Timestamp>(9, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aOS(10, _omitFieldNames ? '' : 'createdBy')
    ..aInt64(11, _omitFieldNames ? '' : 'lastSeq')
    ..aOB(12, _omitFieldNames ? '' : 'muted')
    ..aOB(13, _omitFieldNames ? '' : 'pinned')
    ..aOS(14, _omitFieldNames ? '' : 'accentColor')
    ..aOM<$0.User>(15, _omitFieldNames ? '' : 'peer',
        subBuilder: $0.User.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Conversation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Conversation copyWith(void Function(Conversation) updates) =>
      super.copyWith((message) => updates(message as Conversation))
          as Conversation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Conversation() / Conversation.new instead')
  static Conversation create() => Conversation._();
  static $pb.GeneratedMessage $_createMessage() => Conversation._();
  @$core.override
  Conversation createEmptyInstance() => Conversation._();
  @$core.pragma('dart2js:noInline')
  static Conversation getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Conversation>(
          Conversation.$_createMessage);
  static Conversation? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// "direct" or "group".
  @$pb.TagNumber(2)
  $core.String get kind => $_getSZ(1);
  @$pb.TagNumber(2)
  set kind($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  /// Group title; for direct conversations the peer's display name.
  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  /// Group picture, or the peer's picture for direct conversations.
  @$pb.TagNumber(4)
  $core.String get avatarUrl => $_getSZ(3);
  @$pb.TagNumber(4)
  set avatarUrl($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAvatarUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearAvatarUrl() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<Member> get members => $_getList(4);

  /// Most recent message, absent in a conversation with no messages yet.
  @$pb.TagNumber(6)
  Message get lastMessage => $_getN(5);
  @$pb.TagNumber(6)
  set lastMessage(Message value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasLastMessage() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastMessage() => $_clearField(6);
  @$pb.TagNumber(6)
  Message ensureLastMessage() => $_ensure(5);

  @$pb.TagNumber(7)
  $core.int get unreadCount => $_getIZ(6);
  @$pb.TagNumber(7)
  set unreadCount($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUnreadCount() => $_has(6);
  @$pb.TagNumber(7)
  void clearUnreadCount() => $_clearField(7);

  @$pb.TagNumber(8)
  $1.Timestamp get createdAt => $_getN(7);
  @$pb.TagNumber(8)
  set createdAt($1.Timestamp value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasCreatedAt() => $_has(7);
  @$pb.TagNumber(8)
  void clearCreatedAt() => $_clearField(8);
  @$pb.TagNumber(8)
  $1.Timestamp ensureCreatedAt() => $_ensure(7);

  @$pb.TagNumber(9)
  $1.Timestamp get updatedAt => $_getN(8);
  @$pb.TagNumber(9)
  set updatedAt($1.Timestamp value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasUpdatedAt() => $_has(8);
  @$pb.TagNumber(9)
  void clearUpdatedAt() => $_clearField(9);
  @$pb.TagNumber(9)
  $1.Timestamp ensureUpdatedAt() => $_ensure(8);

  @$pb.TagNumber(10)
  $core.String get createdBy => $_getSZ(9);
  @$pb.TagNumber(10)
  set createdBy($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCreatedBy() => $_has(9);
  @$pb.TagNumber(10)
  void clearCreatedBy() => $_clearField(10);

  /// Highest seq in the conversation, read or not.
  @$pb.TagNumber(11)
  $fixnum.Int64 get lastSeq => $_getI64(10);
  @$pb.TagNumber(11)
  set lastSeq($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasLastSeq() => $_has(10);
  @$pb.TagNumber(11)
  void clearLastSeq() => $_clearField(11);

  /// The viewer's own flags, mirrored from their Member row.
  @$pb.TagNumber(12)
  $core.bool get muted => $_getBF(11);
  @$pb.TagNumber(12)
  set muted($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasMuted() => $_has(11);
  @$pb.TagNumber(12)
  void clearMuted() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.bool get pinned => $_getBF(12);
  @$pb.TagNumber(13)
  set pinned($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasPinned() => $_has(12);
  @$pb.TagNumber(13)
  void clearPinned() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get accentColor => $_getSZ(13);
  @$pb.TagNumber(14)
  set accentColor($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasAccentColor() => $_has(13);
  @$pb.TagNumber(14)
  void clearAccentColor() => $_clearField(14);

  /// For direct conversations: the other participant, empty in groups.
  @$pb.TagNumber(15)
  $0.User get peer => $_getN(14);
  @$pb.TagNumber(15)
  set peer($0.User value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasPeer() => $_has(14);
  @$pb.TagNumber(15)
  void clearPeer() => $_clearField(15);
  @$pb.TagNumber(15)
  $0.User ensurePeer() => $_ensure(14);
}

class ListConversationsRequest extends $pb.GeneratedMessage {
  factory ListConversationsRequest() => ListConversationsRequest._();

  ListConversationsRequest._();

  factory ListConversationsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListConversationsRequest()..mergeFromBuffer(data, registry);
  factory ListConversationsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListConversationsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListConversationsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: ListConversationsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConversationsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConversationsRequest copyWith(
          void Function(ListConversationsRequest) updates) =>
      super.copyWith((message) => updates(message as ListConversationsRequest))
          as ListConversationsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListConversationsRequest() / ListConversationsRequest.new instead')
  static ListConversationsRequest create() => ListConversationsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListConversationsRequest._();
  @$core.override
  ListConversationsRequest createEmptyInstance() =>
      ListConversationsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListConversationsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListConversationsRequest>(
          ListConversationsRequest.$_createMessage);
  static ListConversationsRequest? _defaultInstance;
}

class ListConversationsResponse extends $pb.GeneratedMessage {
  factory ListConversationsResponse({
    $core.Iterable<Conversation>? conversations,
  }) {
    final result = ListConversationsResponse._();
    if (conversations != null) result.conversations.addAll(conversations);
    return result;
  }

  ListConversationsResponse._();

  factory ListConversationsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListConversationsResponse()..mergeFromBuffer(data, registry);
  factory ListConversationsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListConversationsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListConversationsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: ListConversationsResponse.$_createMessage)
    ..pPM<Conversation>(1, _omitFieldNames ? '' : 'conversations',
        subBuilder: Conversation.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConversationsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConversationsResponse copyWith(
          void Function(ListConversationsResponse) updates) =>
      super.copyWith((message) => updates(message as ListConversationsResponse))
          as ListConversationsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListConversationsResponse() / ListConversationsResponse.new instead')
  static ListConversationsResponse create() => ListConversationsResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      ListConversationsResponse._();
  @$core.override
  ListConversationsResponse createEmptyInstance() =>
      ListConversationsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListConversationsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListConversationsResponse>(
          ListConversationsResponse.$_createMessage);
  static ListConversationsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Conversation> get conversations => $_getList(0);
}

class GetConversationRequest extends $pb.GeneratedMessage {
  factory GetConversationRequest({
    $core.String? conversationId,
  }) {
    final result = GetConversationRequest._();
    if (conversationId != null) result.conversationId = conversationId;
    return result;
  }

  GetConversationRequest._();

  factory GetConversationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetConversationRequest()..mergeFromBuffer(data, registry);
  factory GetConversationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetConversationRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetConversationRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: GetConversationRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConversationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConversationRequest copyWith(
          void Function(GetConversationRequest) updates) =>
      super.copyWith((message) => updates(message as GetConversationRequest))
          as GetConversationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetConversationRequest() / GetConversationRequest.new instead')
  static GetConversationRequest create() => GetConversationRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetConversationRequest._();
  @$core.override
  GetConversationRequest createEmptyInstance() => GetConversationRequest._();
  @$core.pragma('dart2js:noInline')
  static GetConversationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetConversationRequest>(
          GetConversationRequest.$_createMessage);
  static GetConversationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);
}

class GetConversationResponse extends $pb.GeneratedMessage {
  factory GetConversationResponse({
    Conversation? conversation,
  }) {
    final result = GetConversationResponse._();
    if (conversation != null) result.conversation = conversation;
    return result;
  }

  GetConversationResponse._();

  factory GetConversationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetConversationResponse()..mergeFromBuffer(data, registry);
  factory GetConversationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetConversationResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetConversationResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: GetConversationResponse.$_createMessage)
    ..aOM<Conversation>(1, _omitFieldNames ? '' : 'conversation',
        subBuilder: Conversation.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConversationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConversationResponse copyWith(
          void Function(GetConversationResponse) updates) =>
      super.copyWith((message) => updates(message as GetConversationResponse))
          as GetConversationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetConversationResponse() / GetConversationResponse.new instead')
  static GetConversationResponse create() => GetConversationResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetConversationResponse._();
  @$core.override
  GetConversationResponse createEmptyInstance() => GetConversationResponse._();
  @$core.pragma('dart2js:noInline')
  static GetConversationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetConversationResponse>(
          GetConversationResponse.$_createMessage);
  static GetConversationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Conversation get conversation => $_getN(0);
  @$pb.TagNumber(1)
  set conversation(Conversation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConversation() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversation() => $_clearField(1);
  @$pb.TagNumber(1)
  Conversation ensureConversation() => $_ensure(0);
}

class CreateDirectConversationRequest extends $pb.GeneratedMessage {
  factory CreateDirectConversationRequest({
    $core.String? userId,
    $core.String? username,
  }) {
    final result = CreateDirectConversationRequest._();
    if (userId != null) result.userId = userId;
    if (username != null) result.username = username;
    return result;
  }

  CreateDirectConversationRequest._();

  factory CreateDirectConversationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateDirectConversationRequest()..mergeFromBuffer(data, registry);
  factory CreateDirectConversationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateDirectConversationRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateDirectConversationRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: CreateDirectConversationRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateDirectConversationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateDirectConversationRequest copyWith(
          void Function(CreateDirectConversationRequest) updates) =>
      super.copyWith(
              (message) => updates(message as CreateDirectConversationRequest))
          as CreateDirectConversationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreateDirectConversationRequest() / CreateDirectConversationRequest.new instead')
  static CreateDirectConversationRequest create() =>
      CreateDirectConversationRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      CreateDirectConversationRequest._();
  @$core.override
  CreateDirectConversationRequest createEmptyInstance() =>
      CreateDirectConversationRequest._();
  @$core.pragma('dart2js:noInline')
  static CreateDirectConversationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateDirectConversationRequest>(
          CreateDirectConversationRequest.$_createMessage);
  static CreateDirectConversationRequest? _defaultInstance;

  /// Exactly one of user_id / username must be set.
  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);
}

class CreateDirectConversationResponse extends $pb.GeneratedMessage {
  factory CreateDirectConversationResponse({
    Conversation? conversation,
    $core.bool? created,
  }) {
    final result = CreateDirectConversationResponse._();
    if (conversation != null) result.conversation = conversation;
    if (created != null) result.created = created;
    return result;
  }

  CreateDirectConversationResponse._();

  factory CreateDirectConversationResponse.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateDirectConversationResponse()..mergeFromBuffer(data, registry);
  factory CreateDirectConversationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateDirectConversationResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateDirectConversationResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: CreateDirectConversationResponse.$_createMessage)
    ..aOM<Conversation>(1, _omitFieldNames ? '' : 'conversation',
        subBuilder: Conversation.$_createMessage)
    ..aOB(2, _omitFieldNames ? '' : 'created')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateDirectConversationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateDirectConversationResponse copyWith(
          void Function(CreateDirectConversationResponse) updates) =>
      super.copyWith(
              (message) => updates(message as CreateDirectConversationResponse))
          as CreateDirectConversationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreateDirectConversationResponse() / CreateDirectConversationResponse.new instead')
  static CreateDirectConversationResponse create() =>
      CreateDirectConversationResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      CreateDirectConversationResponse._();
  @$core.override
  CreateDirectConversationResponse createEmptyInstance() =>
      CreateDirectConversationResponse._();
  @$core.pragma('dart2js:noInline')
  static CreateDirectConversationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateDirectConversationResponse>(
          CreateDirectConversationResponse.$_createMessage);
  static CreateDirectConversationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Conversation get conversation => $_getN(0);
  @$pb.TagNumber(1)
  set conversation(Conversation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConversation() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversation() => $_clearField(1);
  @$pb.TagNumber(1)
  Conversation ensureConversation() => $_ensure(0);

  /// True when a new conversation was created rather than reused.
  @$pb.TagNumber(2)
  $core.bool get created => $_getBF(1);
  @$pb.TagNumber(2)
  set created($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCreated() => $_has(1);
  @$pb.TagNumber(2)
  void clearCreated() => $_clearField(2);
}

class CreateGroupConversationRequest extends $pb.GeneratedMessage {
  factory CreateGroupConversationRequest({
    $core.String? title,
    $core.Iterable<$core.String>? usernames,
    $core.Iterable<$core.String>? userIds,
  }) {
    final result = CreateGroupConversationRequest._();
    if (title != null) result.title = title;
    if (usernames != null) result.usernames.addAll(usernames);
    if (userIds != null) result.userIds.addAll(userIds);
    return result;
  }

  CreateGroupConversationRequest._();

  factory CreateGroupConversationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateGroupConversationRequest()..mergeFromBuffer(data, registry);
  factory CreateGroupConversationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateGroupConversationRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateGroupConversationRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: CreateGroupConversationRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..pPS(2, _omitFieldNames ? '' : 'usernames')
    ..pPS(3, _omitFieldNames ? '' : 'userIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateGroupConversationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateGroupConversationRequest copyWith(
          void Function(CreateGroupConversationRequest) updates) =>
      super.copyWith(
              (message) => updates(message as CreateGroupConversationRequest))
          as CreateGroupConversationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreateGroupConversationRequest() / CreateGroupConversationRequest.new instead')
  static CreateGroupConversationRequest create() =>
      CreateGroupConversationRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      CreateGroupConversationRequest._();
  @$core.override
  CreateGroupConversationRequest createEmptyInstance() =>
      CreateGroupConversationRequest._();
  @$core.pragma('dart2js:noInline')
  static CreateGroupConversationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateGroupConversationRequest>(
          CreateGroupConversationRequest.$_createMessage);
  static CreateGroupConversationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  /// Handles of the initial members, the caller excluded.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get usernames => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get userIds => $_getList(2);
}

class CreateGroupConversationResponse extends $pb.GeneratedMessage {
  factory CreateGroupConversationResponse({
    Conversation? conversation,
  }) {
    final result = CreateGroupConversationResponse._();
    if (conversation != null) result.conversation = conversation;
    return result;
  }

  CreateGroupConversationResponse._();

  factory CreateGroupConversationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateGroupConversationResponse()..mergeFromBuffer(data, registry);
  factory CreateGroupConversationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateGroupConversationResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateGroupConversationResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: CreateGroupConversationResponse.$_createMessage)
    ..aOM<Conversation>(1, _omitFieldNames ? '' : 'conversation',
        subBuilder: Conversation.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateGroupConversationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateGroupConversationResponse copyWith(
          void Function(CreateGroupConversationResponse) updates) =>
      super.copyWith(
              (message) => updates(message as CreateGroupConversationResponse))
          as CreateGroupConversationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreateGroupConversationResponse() / CreateGroupConversationResponse.new instead')
  static CreateGroupConversationResponse create() =>
      CreateGroupConversationResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      CreateGroupConversationResponse._();
  @$core.override
  CreateGroupConversationResponse createEmptyInstance() =>
      CreateGroupConversationResponse._();
  @$core.pragma('dart2js:noInline')
  static CreateGroupConversationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateGroupConversationResponse>(
          CreateGroupConversationResponse.$_createMessage);
  static CreateGroupConversationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Conversation get conversation => $_getN(0);
  @$pb.TagNumber(1)
  set conversation(Conversation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConversation() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversation() => $_clearField(1);
  @$pb.TagNumber(1)
  Conversation ensureConversation() => $_ensure(0);
}

class UpdateConversationRequest extends $pb.GeneratedMessage {
  factory UpdateConversationRequest({
    $core.String? conversationId,
    $core.String? title,
    $core.String? avatarAttachmentId,
    $core.bool? clearAvatar,
    $core.bool? muted,
    $core.bool? pinned,
  }) {
    final result = UpdateConversationRequest._();
    if (conversationId != null) result.conversationId = conversationId;
    if (title != null) result.title = title;
    if (avatarAttachmentId != null)
      result.avatarAttachmentId = avatarAttachmentId;
    if (clearAvatar != null) result.clearAvatar = clearAvatar;
    if (muted != null) result.muted = muted;
    if (pinned != null) result.pinned = pinned;
    return result;
  }

  UpdateConversationRequest._();

  factory UpdateConversationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateConversationRequest()..mergeFromBuffer(data, registry);
  factory UpdateConversationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateConversationRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateConversationRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: UpdateConversationRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'avatarAttachmentId')
    ..aOB(4, _omitFieldNames ? '' : 'clearAvatar')
    ..aOB(5, _omitFieldNames ? '' : 'muted')
    ..aOB(6, _omitFieldNames ? '' : 'pinned')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateConversationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateConversationRequest copyWith(
          void Function(UpdateConversationRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateConversationRequest))
          as UpdateConversationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UpdateConversationRequest() / UpdateConversationRequest.new instead')
  static UpdateConversationRequest create() => UpdateConversationRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      UpdateConversationRequest._();
  @$core.override
  UpdateConversationRequest createEmptyInstance() =>
      UpdateConversationRequest._();
  @$core.pragma('dart2js:noInline')
  static UpdateConversationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateConversationRequest>(
          UpdateConversationRequest.$_createMessage);
  static UpdateConversationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  /// Empty fields keep their current value.
  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get avatarAttachmentId => $_getSZ(2);
  @$pb.TagNumber(3)
  set avatarAttachmentId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAvatarAttachmentId() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvatarAttachmentId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get clearAvatar => $_getBF(3);
  @$pb.TagNumber(4)
  set clearAvatar($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasClearAvatar() => $_has(3);
  @$pb.TagNumber(4)
  void clearClearAvatar() => $_clearField(4);

  /// Viewer-scoped flags.
  @$pb.TagNumber(5)
  $core.bool get muted => $_getBF(4);
  @$pb.TagNumber(5)
  set muted($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMuted() => $_has(4);
  @$pb.TagNumber(5)
  void clearMuted() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get pinned => $_getBF(5);
  @$pb.TagNumber(6)
  set pinned($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPinned() => $_has(5);
  @$pb.TagNumber(6)
  void clearPinned() => $_clearField(6);
}

class UpdateConversationResponse extends $pb.GeneratedMessage {
  factory UpdateConversationResponse({
    Conversation? conversation,
  }) {
    final result = UpdateConversationResponse._();
    if (conversation != null) result.conversation = conversation;
    return result;
  }

  UpdateConversationResponse._();

  factory UpdateConversationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateConversationResponse()..mergeFromBuffer(data, registry);
  factory UpdateConversationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateConversationResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateConversationResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: UpdateConversationResponse.$_createMessage)
    ..aOM<Conversation>(1, _omitFieldNames ? '' : 'conversation',
        subBuilder: Conversation.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateConversationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateConversationResponse copyWith(
          void Function(UpdateConversationResponse) updates) =>
      super.copyWith(
              (message) => updates(message as UpdateConversationResponse))
          as UpdateConversationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UpdateConversationResponse() / UpdateConversationResponse.new instead')
  static UpdateConversationResponse create() => UpdateConversationResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      UpdateConversationResponse._();
  @$core.override
  UpdateConversationResponse createEmptyInstance() =>
      UpdateConversationResponse._();
  @$core.pragma('dart2js:noInline')
  static UpdateConversationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateConversationResponse>(
          UpdateConversationResponse.$_createMessage);
  static UpdateConversationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Conversation get conversation => $_getN(0);
  @$pb.TagNumber(1)
  set conversation(Conversation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConversation() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversation() => $_clearField(1);
  @$pb.TagNumber(1)
  Conversation ensureConversation() => $_ensure(0);
}

class AddMembersRequest extends $pb.GeneratedMessage {
  factory AddMembersRequest({
    $core.String? conversationId,
    $core.Iterable<$core.String>? usernames,
    $core.Iterable<$core.String>? userIds,
  }) {
    final result = AddMembersRequest._();
    if (conversationId != null) result.conversationId = conversationId;
    if (usernames != null) result.usernames.addAll(usernames);
    if (userIds != null) result.userIds.addAll(userIds);
    return result;
  }

  AddMembersRequest._();

  factory AddMembersRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddMembersRequest()..mergeFromBuffer(data, registry);
  factory AddMembersRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddMembersRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddMembersRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: AddMembersRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..pPS(2, _omitFieldNames ? '' : 'usernames')
    ..pPS(3, _omitFieldNames ? '' : 'userIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddMembersRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddMembersRequest copyWith(void Function(AddMembersRequest) updates) =>
      super.copyWith((message) => updates(message as AddMembersRequest))
          as AddMembersRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AddMembersRequest() / AddMembersRequest.new instead')
  static AddMembersRequest create() => AddMembersRequest._();
  static $pb.GeneratedMessage $_createMessage() => AddMembersRequest._();
  @$core.override
  AddMembersRequest createEmptyInstance() => AddMembersRequest._();
  @$core.pragma('dart2js:noInline')
  static AddMembersRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddMembersRequest>(
          AddMembersRequest.$_createMessage);
  static AddMembersRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get usernames => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get userIds => $_getList(2);
}

class AddMembersResponse extends $pb.GeneratedMessage {
  factory AddMembersResponse({
    Conversation? conversation,
  }) {
    final result = AddMembersResponse._();
    if (conversation != null) result.conversation = conversation;
    return result;
  }

  AddMembersResponse._();

  factory AddMembersResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddMembersResponse()..mergeFromBuffer(data, registry);
  factory AddMembersResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddMembersResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddMembersResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: AddMembersResponse.$_createMessage)
    ..aOM<Conversation>(1, _omitFieldNames ? '' : 'conversation',
        subBuilder: Conversation.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddMembersResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddMembersResponse copyWith(void Function(AddMembersResponse) updates) =>
      super.copyWith((message) => updates(message as AddMembersResponse))
          as AddMembersResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AddMembersResponse() / AddMembersResponse.new instead')
  static AddMembersResponse create() => AddMembersResponse._();
  static $pb.GeneratedMessage $_createMessage() => AddMembersResponse._();
  @$core.override
  AddMembersResponse createEmptyInstance() => AddMembersResponse._();
  @$core.pragma('dart2js:noInline')
  static AddMembersResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddMembersResponse>(
          AddMembersResponse.$_createMessage);
  static AddMembersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Conversation get conversation => $_getN(0);
  @$pb.TagNumber(1)
  set conversation(Conversation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConversation() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversation() => $_clearField(1);
  @$pb.TagNumber(1)
  Conversation ensureConversation() => $_ensure(0);
}

class RemoveMemberRequest extends $pb.GeneratedMessage {
  factory RemoveMemberRequest({
    $core.String? conversationId,
    $core.String? userId,
  }) {
    final result = RemoveMemberRequest._();
    if (conversationId != null) result.conversationId = conversationId;
    if (userId != null) result.userId = userId;
    return result;
  }

  RemoveMemberRequest._();

  factory RemoveMemberRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveMemberRequest()..mergeFromBuffer(data, registry);
  factory RemoveMemberRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveMemberRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveMemberRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: RemoveMemberRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveMemberRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveMemberRequest copyWith(void Function(RemoveMemberRequest) updates) =>
      super.copyWith((message) => updates(message as RemoveMemberRequest))
          as RemoveMemberRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use RemoveMemberRequest() / RemoveMemberRequest.new instead')
  static RemoveMemberRequest create() => RemoveMemberRequest._();
  static $pb.GeneratedMessage $_createMessage() => RemoveMemberRequest._();
  @$core.override
  RemoveMemberRequest createEmptyInstance() => RemoveMemberRequest._();
  @$core.pragma('dart2js:noInline')
  static RemoveMemberRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveMemberRequest>(
          RemoveMemberRequest.$_createMessage);
  static RemoveMemberRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  /// Empty removes the caller (leave).
  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);
}

class RemoveMemberResponse extends $pb.GeneratedMessage {
  factory RemoveMemberResponse({
    Conversation? conversation,
  }) {
    final result = RemoveMemberResponse._();
    if (conversation != null) result.conversation = conversation;
    return result;
  }

  RemoveMemberResponse._();

  factory RemoveMemberResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveMemberResponse()..mergeFromBuffer(data, registry);
  factory RemoveMemberResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveMemberResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveMemberResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: RemoveMemberResponse.$_createMessage)
    ..aOM<Conversation>(1, _omitFieldNames ? '' : 'conversation',
        subBuilder: Conversation.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveMemberResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveMemberResponse copyWith(void Function(RemoveMemberResponse) updates) =>
      super.copyWith((message) => updates(message as RemoveMemberResponse))
          as RemoveMemberResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RemoveMemberResponse() / RemoveMemberResponse.new instead')
  static RemoveMemberResponse create() => RemoveMemberResponse._();
  static $pb.GeneratedMessage $_createMessage() => RemoveMemberResponse._();
  @$core.override
  RemoveMemberResponse createEmptyInstance() => RemoveMemberResponse._();
  @$core.pragma('dart2js:noInline')
  static RemoveMemberResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveMemberResponse>(
          RemoveMemberResponse.$_createMessage);
  static RemoveMemberResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Conversation get conversation => $_getN(0);
  @$pb.TagNumber(1)
  set conversation(Conversation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConversation() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversation() => $_clearField(1);
  @$pb.TagNumber(1)
  Conversation ensureConversation() => $_ensure(0);
}

class ListMessagesRequest extends $pb.GeneratedMessage {
  factory ListMessagesRequest({
    $core.String? conversationId,
    $fixnum.Int64? beforeSeq,
    $fixnum.Int64? afterSeq,
    $core.int? limit,
  }) {
    final result = ListMessagesRequest._();
    if (conversationId != null) result.conversationId = conversationId;
    if (beforeSeq != null) result.beforeSeq = beforeSeq;
    if (afterSeq != null) result.afterSeq = afterSeq;
    if (limit != null) result.limit = limit;
    return result;
  }

  ListMessagesRequest._();

  factory ListMessagesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListMessagesRequest()..mergeFromBuffer(data, registry);
  factory ListMessagesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListMessagesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListMessagesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: ListMessagesRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aInt64(2, _omitFieldNames ? '' : 'beforeSeq')
    ..aInt64(3, _omitFieldNames ? '' : 'afterSeq')
    ..aI(4, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMessagesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMessagesRequest copyWith(void Function(ListMessagesRequest) updates) =>
      super.copyWith((message) => updates(message as ListMessagesRequest))
          as ListMessagesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ListMessagesRequest() / ListMessagesRequest.new instead')
  static ListMessagesRequest create() => ListMessagesRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListMessagesRequest._();
  @$core.override
  ListMessagesRequest createEmptyInstance() => ListMessagesRequest._();
  @$core.pragma('dart2js:noInline')
  static ListMessagesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListMessagesRequest>(
          ListMessagesRequest.$_createMessage);
  static ListMessagesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  /// Return messages with seq < before_seq, newest last. Used for scrolling up.
  @$pb.TagNumber(2)
  $fixnum.Int64 get beforeSeq => $_getI64(1);
  @$pb.TagNumber(2)
  set beforeSeq($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBeforeSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearBeforeSeq() => $_clearField(2);

  /// Return messages with seq > after_seq, oldest first. Used for catch-up.
  @$pb.TagNumber(3)
  $fixnum.Int64 get afterSeq => $_getI64(2);
  @$pb.TagNumber(3)
  set afterSeq($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAfterSeq() => $_has(2);
  @$pb.TagNumber(3)
  void clearAfterSeq() => $_clearField(3);

  /// Defaults to 50, capped at 200.
  @$pb.TagNumber(4)
  $core.int get limit => $_getIZ(3);
  @$pb.TagNumber(4)
  set limit($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearLimit() => $_clearField(4);
}

class ListMessagesResponse extends $pb.GeneratedMessage {
  factory ListMessagesResponse({
    $core.Iterable<Message>? messages,
    $core.bool? hasMore,
  }) {
    final result = ListMessagesResponse._();
    if (messages != null) result.messages.addAll(messages);
    if (hasMore != null) result.hasMore = hasMore;
    return result;
  }

  ListMessagesResponse._();

  factory ListMessagesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListMessagesResponse()..mergeFromBuffer(data, registry);
  factory ListMessagesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListMessagesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListMessagesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: ListMessagesResponse.$_createMessage)
    ..pPM<Message>(1, _omitFieldNames ? '' : 'messages',
        subBuilder: Message.$_createMessage)
    ..aOB(2, _omitFieldNames ? '' : 'hasMore')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMessagesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMessagesResponse copyWith(void Function(ListMessagesResponse) updates) =>
      super.copyWith((message) => updates(message as ListMessagesResponse))
          as ListMessagesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListMessagesResponse() / ListMessagesResponse.new instead')
  static ListMessagesResponse create() => ListMessagesResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListMessagesResponse._();
  @$core.override
  ListMessagesResponse createEmptyInstance() => ListMessagesResponse._();
  @$core.pragma('dart2js:noInline')
  static ListMessagesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListMessagesResponse>(
          ListMessagesResponse.$_createMessage);
  static ListMessagesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Message> get messages => $_getList(0);

  /// True when older messages exist before the first returned message.
  @$pb.TagNumber(2)
  $core.bool get hasMore => $_getBF(1);
  @$pb.TagNumber(2)
  set hasMore($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHasMore() => $_has(1);
  @$pb.TagNumber(2)
  void clearHasMore() => $_clearField(2);
}

class SendMessageRequest extends $pb.GeneratedMessage {
  factory SendMessageRequest({
    $core.String? conversationId,
    $core.String? text,
    $core.Iterable<$core.String>? attachmentIds,
    $core.String? replyToId,
    $core.String? clientMessageId,
    $core.List<$core.int>? ciphertext,
    $core.List<$core.int>? nonce,
    $core.String? senderDeviceKeyId,
    $core.int? keyEpoch,
    $core.String? cryptoVersion,
  }) {
    final result = SendMessageRequest._();
    if (conversationId != null) result.conversationId = conversationId;
    if (text != null) result.text = text;
    if (attachmentIds != null) result.attachmentIds.addAll(attachmentIds);
    if (replyToId != null) result.replyToId = replyToId;
    if (clientMessageId != null) result.clientMessageId = clientMessageId;
    if (ciphertext != null) result.ciphertext = ciphertext;
    if (nonce != null) result.nonce = nonce;
    if (senderDeviceKeyId != null) result.senderDeviceKeyId = senderDeviceKeyId;
    if (keyEpoch != null) result.keyEpoch = keyEpoch;
    if (cryptoVersion != null) result.cryptoVersion = cryptoVersion;
    return result;
  }

  SendMessageRequest._();

  factory SendMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendMessageRequest()..mergeFromBuffer(data, registry);
  factory SendMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendMessageRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendMessageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: SendMessageRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..pPS(3, _omitFieldNames ? '' : 'attachmentIds')
    ..aOS(4, _omitFieldNames ? '' : 'replyToId')
    ..aOS(5, _omitFieldNames ? '' : 'clientMessageId')
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'ciphertext', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        7, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..aOS(8, _omitFieldNames ? '' : 'senderDeviceKeyId')
    ..aI(9, _omitFieldNames ? '' : 'keyEpoch')
    ..aOS(10, _omitFieldNames ? '' : 'cryptoVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendMessageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendMessageRequest copyWith(void Function(SendMessageRequest) updates) =>
      super.copyWith((message) => updates(message as SendMessageRequest))
          as SendMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SendMessageRequest() / SendMessageRequest.new instead')
  static SendMessageRequest create() => SendMessageRequest._();
  static $pb.GeneratedMessage $_createMessage() => SendMessageRequest._();
  @$core.override
  SendMessageRequest createEmptyInstance() => SendMessageRequest._();
  @$core.pragma('dart2js:noInline')
  static SendMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendMessageRequest>(
          SendMessageRequest.$_createMessage);
  static SendMessageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  /// Plain text. Only accepted for unencrypted sends; an encrypted client sends
  /// `ciphertext` instead.
  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get attachmentIds => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get replyToId => $_getSZ(3);
  @$pb.TagNumber(4)
  set replyToId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReplyToId() => $_has(3);
  @$pb.TagNumber(4)
  void clearReplyToId() => $_clearField(4);

  /// Sender-generated id; a repeat of the same id returns the stored message
  /// instead of appending a second one.
  @$pb.TagNumber(5)
  $core.String get clientMessageId => $_getSZ(4);
  @$pb.TagNumber(5)
  set clientMessageId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasClientMessageId() => $_has(4);
  @$pb.TagNumber(5)
  void clearClientMessageId() => $_clearField(5);

  /// The sealed content, plus what a reader needs to find the key.
  @$pb.TagNumber(6)
  $core.List<$core.int> get ciphertext => $_getN(5);
  @$pb.TagNumber(6)
  set ciphertext($core.List<$core.int> value) => $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCiphertext() => $_has(5);
  @$pb.TagNumber(6)
  void clearCiphertext() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.int> get nonce => $_getN(6);
  @$pb.TagNumber(7)
  set nonce($core.List<$core.int> value) => $_setBytes(6, value);
  @$pb.TagNumber(7)
  $core.bool hasNonce() => $_has(6);
  @$pb.TagNumber(7)
  void clearNonce() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get senderDeviceKeyId => $_getSZ(7);
  @$pb.TagNumber(8)
  set senderDeviceKeyId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSenderDeviceKeyId() => $_has(7);
  @$pb.TagNumber(8)
  void clearSenderDeviceKeyId() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get keyEpoch => $_getIZ(8);
  @$pb.TagNumber(9)
  set keyEpoch($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasKeyEpoch() => $_has(8);
  @$pb.TagNumber(9)
  void clearKeyEpoch() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get cryptoVersion => $_getSZ(9);
  @$pb.TagNumber(10)
  set cryptoVersion($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCryptoVersion() => $_has(9);
  @$pb.TagNumber(10)
  void clearCryptoVersion() => $_clearField(10);
}

class SendMessageResponse extends $pb.GeneratedMessage {
  factory SendMessageResponse({
    Message? message,
  }) {
    final result = SendMessageResponse._();
    if (message != null) result.message = message;
    return result;
  }

  SendMessageResponse._();

  factory SendMessageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendMessageResponse()..mergeFromBuffer(data, registry);
  factory SendMessageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendMessageResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendMessageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: SendMessageResponse.$_createMessage)
    ..aOM<Message>(1, _omitFieldNames ? '' : 'message',
        subBuilder: Message.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendMessageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendMessageResponse copyWith(void Function(SendMessageResponse) updates) =>
      super.copyWith((message) => updates(message as SendMessageResponse))
          as SendMessageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SendMessageResponse() / SendMessageResponse.new instead')
  static SendMessageResponse create() => SendMessageResponse._();
  static $pb.GeneratedMessage $_createMessage() => SendMessageResponse._();
  @$core.override
  SendMessageResponse createEmptyInstance() => SendMessageResponse._();
  @$core.pragma('dart2js:noInline')
  static SendMessageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendMessageResponse>(
          SendMessageResponse.$_createMessage);
  static SendMessageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Message get message => $_getN(0);
  @$pb.TagNumber(1)
  set message(Message value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
  @$pb.TagNumber(1)
  Message ensureMessage() => $_ensure(0);
}

class EditMessageRequest extends $pb.GeneratedMessage {
  factory EditMessageRequest({
    $core.String? messageId,
    $core.String? text,
    $core.List<$core.int>? ciphertext,
    $core.List<$core.int>? nonce,
    $core.String? cryptoVersion,
  }) {
    final result = EditMessageRequest._();
    if (messageId != null) result.messageId = messageId;
    if (text != null) result.text = text;
    if (ciphertext != null) result.ciphertext = ciphertext;
    if (nonce != null) result.nonce = nonce;
    if (cryptoVersion != null) result.cryptoVersion = cryptoVersion;
    return result;
  }

  EditMessageRequest._();

  factory EditMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EditMessageRequest()..mergeFromBuffer(data, registry);
  factory EditMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EditMessageRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EditMessageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: EditMessageRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'ciphertext', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..aOS(5, _omitFieldNames ? '' : 'cryptoVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditMessageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditMessageRequest copyWith(void Function(EditMessageRequest) updates) =>
      super.copyWith((message) => updates(message as EditMessageRequest))
          as EditMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EditMessageRequest() / EditMessageRequest.new instead')
  static EditMessageRequest create() => EditMessageRequest._();
  static $pb.GeneratedMessage $_createMessage() => EditMessageRequest._();
  @$core.override
  EditMessageRequest createEmptyInstance() => EditMessageRequest._();
  @$core.pragma('dart2js:noInline')
  static EditMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EditMessageRequest>(
          EditMessageRequest.$_createMessage);
  static EditMessageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  /// Plain text, for unencrypted conversations only.
  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);

  /// The re-sealed content. The server replaces the stored ciphertext, so it
  /// never sees the new text either.
  @$pb.TagNumber(3)
  $core.List<$core.int> get ciphertext => $_getN(2);
  @$pb.TagNumber(3)
  set ciphertext($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCiphertext() => $_has(2);
  @$pb.TagNumber(3)
  void clearCiphertext() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get nonce => $_getN(3);
  @$pb.TagNumber(4)
  set nonce($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNonce() => $_has(3);
  @$pb.TagNumber(4)
  void clearNonce() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get cryptoVersion => $_getSZ(4);
  @$pb.TagNumber(5)
  set cryptoVersion($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCryptoVersion() => $_has(4);
  @$pb.TagNumber(5)
  void clearCryptoVersion() => $_clearField(5);
}

class EditMessageResponse extends $pb.GeneratedMessage {
  factory EditMessageResponse({
    Message? message,
  }) {
    final result = EditMessageResponse._();
    if (message != null) result.message = message;
    return result;
  }

  EditMessageResponse._();

  factory EditMessageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EditMessageResponse()..mergeFromBuffer(data, registry);
  factory EditMessageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EditMessageResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EditMessageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: EditMessageResponse.$_createMessage)
    ..aOM<Message>(1, _omitFieldNames ? '' : 'message',
        subBuilder: Message.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditMessageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditMessageResponse copyWith(void Function(EditMessageResponse) updates) =>
      super.copyWith((message) => updates(message as EditMessageResponse))
          as EditMessageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use EditMessageResponse() / EditMessageResponse.new instead')
  static EditMessageResponse create() => EditMessageResponse._();
  static $pb.GeneratedMessage $_createMessage() => EditMessageResponse._();
  @$core.override
  EditMessageResponse createEmptyInstance() => EditMessageResponse._();
  @$core.pragma('dart2js:noInline')
  static EditMessageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EditMessageResponse>(
          EditMessageResponse.$_createMessage);
  static EditMessageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Message get message => $_getN(0);
  @$pb.TagNumber(1)
  set message(Message value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
  @$pb.TagNumber(1)
  Message ensureMessage() => $_ensure(0);
}

class DeleteMessageRequest extends $pb.GeneratedMessage {
  factory DeleteMessageRequest({
    $core.String? messageId,
  }) {
    final result = DeleteMessageRequest._();
    if (messageId != null) result.messageId = messageId;
    return result;
  }

  DeleteMessageRequest._();

  factory DeleteMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteMessageRequest()..mergeFromBuffer(data, registry);
  factory DeleteMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteMessageRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteMessageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: DeleteMessageRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteMessageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteMessageRequest copyWith(void Function(DeleteMessageRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteMessageRequest))
          as DeleteMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DeleteMessageRequest() / DeleteMessageRequest.new instead')
  static DeleteMessageRequest create() => DeleteMessageRequest._();
  static $pb.GeneratedMessage $_createMessage() => DeleteMessageRequest._();
  @$core.override
  DeleteMessageRequest createEmptyInstance() => DeleteMessageRequest._();
  @$core.pragma('dart2js:noInline')
  static DeleteMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteMessageRequest>(
          DeleteMessageRequest.$_createMessage);
  static DeleteMessageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);
}

class DeleteMessageResponse extends $pb.GeneratedMessage {
  factory DeleteMessageResponse({
    Message? message,
  }) {
    final result = DeleteMessageResponse._();
    if (message != null) result.message = message;
    return result;
  }

  DeleteMessageResponse._();

  factory DeleteMessageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteMessageResponse()..mergeFromBuffer(data, registry);
  factory DeleteMessageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteMessageResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteMessageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: DeleteMessageResponse.$_createMessage)
    ..aOM<Message>(1, _omitFieldNames ? '' : 'message',
        subBuilder: Message.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteMessageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteMessageResponse copyWith(
          void Function(DeleteMessageResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteMessageResponse))
          as DeleteMessageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DeleteMessageResponse() / DeleteMessageResponse.new instead')
  static DeleteMessageResponse create() => DeleteMessageResponse._();
  static $pb.GeneratedMessage $_createMessage() => DeleteMessageResponse._();
  @$core.override
  DeleteMessageResponse createEmptyInstance() => DeleteMessageResponse._();
  @$core.pragma('dart2js:noInline')
  static DeleteMessageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteMessageResponse>(
          DeleteMessageResponse.$_createMessage);
  static DeleteMessageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Message get message => $_getN(0);
  @$pb.TagNumber(1)
  set message(Message value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
  @$pb.TagNumber(1)
  Message ensureMessage() => $_ensure(0);
}

class AddReactionRequest extends $pb.GeneratedMessage {
  factory AddReactionRequest({
    $core.String? messageId,
    $core.String? emoji,
  }) {
    final result = AddReactionRequest._();
    if (messageId != null) result.messageId = messageId;
    if (emoji != null) result.emoji = emoji;
    return result;
  }

  AddReactionRequest._();

  factory AddReactionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddReactionRequest()..mergeFromBuffer(data, registry);
  factory AddReactionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddReactionRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddReactionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: AddReactionRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'emoji')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddReactionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddReactionRequest copyWith(void Function(AddReactionRequest) updates) =>
      super.copyWith((message) => updates(message as AddReactionRequest))
          as AddReactionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AddReactionRequest() / AddReactionRequest.new instead')
  static AddReactionRequest create() => AddReactionRequest._();
  static $pb.GeneratedMessage $_createMessage() => AddReactionRequest._();
  @$core.override
  AddReactionRequest createEmptyInstance() => AddReactionRequest._();
  @$core.pragma('dart2js:noInline')
  static AddReactionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddReactionRequest>(
          AddReactionRequest.$_createMessage);
  static AddReactionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get emoji => $_getSZ(1);
  @$pb.TagNumber(2)
  set emoji($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEmoji() => $_has(1);
  @$pb.TagNumber(2)
  void clearEmoji() => $_clearField(2);
}

class AddReactionResponse extends $pb.GeneratedMessage {
  factory AddReactionResponse({
    Message? message,
  }) {
    final result = AddReactionResponse._();
    if (message != null) result.message = message;
    return result;
  }

  AddReactionResponse._();

  factory AddReactionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddReactionResponse()..mergeFromBuffer(data, registry);
  factory AddReactionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddReactionResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddReactionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: AddReactionResponse.$_createMessage)
    ..aOM<Message>(1, _omitFieldNames ? '' : 'message',
        subBuilder: Message.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddReactionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddReactionResponse copyWith(void Function(AddReactionResponse) updates) =>
      super.copyWith((message) => updates(message as AddReactionResponse))
          as AddReactionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use AddReactionResponse() / AddReactionResponse.new instead')
  static AddReactionResponse create() => AddReactionResponse._();
  static $pb.GeneratedMessage $_createMessage() => AddReactionResponse._();
  @$core.override
  AddReactionResponse createEmptyInstance() => AddReactionResponse._();
  @$core.pragma('dart2js:noInline')
  static AddReactionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddReactionResponse>(
          AddReactionResponse.$_createMessage);
  static AddReactionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Message get message => $_getN(0);
  @$pb.TagNumber(1)
  set message(Message value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
  @$pb.TagNumber(1)
  Message ensureMessage() => $_ensure(0);
}

class RemoveReactionRequest extends $pb.GeneratedMessage {
  factory RemoveReactionRequest({
    $core.String? messageId,
    $core.String? emoji,
  }) {
    final result = RemoveReactionRequest._();
    if (messageId != null) result.messageId = messageId;
    if (emoji != null) result.emoji = emoji;
    return result;
  }

  RemoveReactionRequest._();

  factory RemoveReactionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveReactionRequest()..mergeFromBuffer(data, registry);
  factory RemoveReactionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveReactionRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveReactionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: RemoveReactionRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'emoji')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveReactionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveReactionRequest copyWith(
          void Function(RemoveReactionRequest) updates) =>
      super.copyWith((message) => updates(message as RemoveReactionRequest))
          as RemoveReactionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RemoveReactionRequest() / RemoveReactionRequest.new instead')
  static RemoveReactionRequest create() => RemoveReactionRequest._();
  static $pb.GeneratedMessage $_createMessage() => RemoveReactionRequest._();
  @$core.override
  RemoveReactionRequest createEmptyInstance() => RemoveReactionRequest._();
  @$core.pragma('dart2js:noInline')
  static RemoveReactionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveReactionRequest>(
          RemoveReactionRequest.$_createMessage);
  static RemoveReactionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get emoji => $_getSZ(1);
  @$pb.TagNumber(2)
  set emoji($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEmoji() => $_has(1);
  @$pb.TagNumber(2)
  void clearEmoji() => $_clearField(2);
}

class RemoveReactionResponse extends $pb.GeneratedMessage {
  factory RemoveReactionResponse({
    Message? message,
  }) {
    final result = RemoveReactionResponse._();
    if (message != null) result.message = message;
    return result;
  }

  RemoveReactionResponse._();

  factory RemoveReactionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveReactionResponse()..mergeFromBuffer(data, registry);
  factory RemoveReactionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveReactionResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveReactionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: RemoveReactionResponse.$_createMessage)
    ..aOM<Message>(1, _omitFieldNames ? '' : 'message',
        subBuilder: Message.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveReactionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveReactionResponse copyWith(
          void Function(RemoveReactionResponse) updates) =>
      super.copyWith((message) => updates(message as RemoveReactionResponse))
          as RemoveReactionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RemoveReactionResponse() / RemoveReactionResponse.new instead')
  static RemoveReactionResponse create() => RemoveReactionResponse._();
  static $pb.GeneratedMessage $_createMessage() => RemoveReactionResponse._();
  @$core.override
  RemoveReactionResponse createEmptyInstance() => RemoveReactionResponse._();
  @$core.pragma('dart2js:noInline')
  static RemoveReactionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveReactionResponse>(
          RemoveReactionResponse.$_createMessage);
  static RemoveReactionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Message get message => $_getN(0);
  @$pb.TagNumber(1)
  set message(Message value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
  @$pb.TagNumber(1)
  Message ensureMessage() => $_ensure(0);
}

class MarkReadRequest extends $pb.GeneratedMessage {
  factory MarkReadRequest({
    $core.String? conversationId,
    $fixnum.Int64? upToSeq,
  }) {
    final result = MarkReadRequest._();
    if (conversationId != null) result.conversationId = conversationId;
    if (upToSeq != null) result.upToSeq = upToSeq;
    return result;
  }

  MarkReadRequest._();

  factory MarkReadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkReadRequest()..mergeFromBuffer(data, registry);
  factory MarkReadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkReadRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MarkReadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: MarkReadRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aInt64(2, _omitFieldNames ? '' : 'upToSeq')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkReadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkReadRequest copyWith(void Function(MarkReadRequest) updates) =>
      super.copyWith((message) => updates(message as MarkReadRequest))
          as MarkReadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MarkReadRequest() / MarkReadRequest.new instead')
  static MarkReadRequest create() => MarkReadRequest._();
  static $pb.GeneratedMessage $_createMessage() => MarkReadRequest._();
  @$core.override
  MarkReadRequest createEmptyInstance() => MarkReadRequest._();
  @$core.pragma('dart2js:noInline')
  static MarkReadRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MarkReadRequest>(
          MarkReadRequest.$_createMessage);
  static MarkReadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  /// Read up to this seq; 0 means "everything in the conversation".
  @$pb.TagNumber(2)
  $fixnum.Int64 get upToSeq => $_getI64(1);
  @$pb.TagNumber(2)
  set upToSeq($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUpToSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearUpToSeq() => $_clearField(2);
}

class MarkReadResponse extends $pb.GeneratedMessage {
  factory MarkReadResponse({
    $core.String? conversationId,
    $fixnum.Int64? lastReadSeq,
    $core.int? unreadCount,
  }) {
    final result = MarkReadResponse._();
    if (conversationId != null) result.conversationId = conversationId;
    if (lastReadSeq != null) result.lastReadSeq = lastReadSeq;
    if (unreadCount != null) result.unreadCount = unreadCount;
    return result;
  }

  MarkReadResponse._();

  factory MarkReadResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkReadResponse()..mergeFromBuffer(data, registry);
  factory MarkReadResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkReadResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MarkReadResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: MarkReadResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aInt64(2, _omitFieldNames ? '' : 'lastReadSeq')
    ..aI(3, _omitFieldNames ? '' : 'unreadCount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkReadResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkReadResponse copyWith(void Function(MarkReadResponse) updates) =>
      super.copyWith((message) => updates(message as MarkReadResponse))
          as MarkReadResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MarkReadResponse() / MarkReadResponse.new instead')
  static MarkReadResponse create() => MarkReadResponse._();
  static $pb.GeneratedMessage $_createMessage() => MarkReadResponse._();
  @$core.override
  MarkReadResponse createEmptyInstance() => MarkReadResponse._();
  @$core.pragma('dart2js:noInline')
  static MarkReadResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MarkReadResponse>(
          MarkReadResponse.$_createMessage);
  static MarkReadResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get lastReadSeq => $_getI64(1);
  @$pb.TagNumber(2)
  set lastReadSeq($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLastReadSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastReadSeq() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get unreadCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set unreadCount($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUnreadCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearUnreadCount() => $_clearField(3);
}

class SetTypingRequest extends $pb.GeneratedMessage {
  factory SetTypingRequest({
    $core.String? conversationId,
    $core.bool? typing,
  }) {
    final result = SetTypingRequest._();
    if (conversationId != null) result.conversationId = conversationId;
    if (typing != null) result.typing = typing;
    return result;
  }

  SetTypingRequest._();

  factory SetTypingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetTypingRequest()..mergeFromBuffer(data, registry);
  factory SetTypingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetTypingRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetTypingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: SetTypingRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aOB(2, _omitFieldNames ? '' : 'typing')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetTypingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetTypingRequest copyWith(void Function(SetTypingRequest) updates) =>
      super.copyWith((message) => updates(message as SetTypingRequest))
          as SetTypingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetTypingRequest() / SetTypingRequest.new instead')
  static SetTypingRequest create() => SetTypingRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetTypingRequest._();
  @$core.override
  SetTypingRequest createEmptyInstance() => SetTypingRequest._();
  @$core.pragma('dart2js:noInline')
  static SetTypingRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetTypingRequest>(
          SetTypingRequest.$_createMessage);
  static SetTypingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get typing => $_getBF(1);
  @$pb.TagNumber(2)
  set typing($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTyping() => $_has(1);
  @$pb.TagNumber(2)
  void clearTyping() => $_clearField(2);
}

class SetTypingResponse extends $pb.GeneratedMessage {
  factory SetTypingResponse() => SetTypingResponse._();

  SetTypingResponse._();

  factory SetTypingResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetTypingResponse()..mergeFromBuffer(data, registry);
  factory SetTypingResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetTypingResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetTypingResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: SetTypingResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetTypingResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetTypingResponse copyWith(void Function(SetTypingResponse) updates) =>
      super.copyWith((message) => updates(message as SetTypingResponse))
          as SetTypingResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetTypingResponse() / SetTypingResponse.new instead')
  static SetTypingResponse create() => SetTypingResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetTypingResponse._();
  @$core.override
  SetTypingResponse createEmptyInstance() => SetTypingResponse._();
  @$core.pragma('dart2js:noInline')
  static SetTypingResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetTypingResponse>(
          SetTypingResponse.$_createMessage);
  static SetTypingResponse? _defaultInstance;
}

class SearchMessagesRequest extends $pb.GeneratedMessage {
  factory SearchMessagesRequest({
    $core.String? query,
    $core.String? conversationId,
    $core.int? limit,
  }) {
    final result = SearchMessagesRequest._();
    if (query != null) result.query = query;
    if (conversationId != null) result.conversationId = conversationId;
    if (limit != null) result.limit = limit;
    return result;
  }

  SearchMessagesRequest._();

  factory SearchMessagesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SearchMessagesRequest()..mergeFromBuffer(data, registry);
  factory SearchMessagesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SearchMessagesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchMessagesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: SearchMessagesRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'query')
    ..aOS(2, _omitFieldNames ? '' : 'conversationId')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchMessagesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchMessagesRequest copyWith(
          void Function(SearchMessagesRequest) updates) =>
      super.copyWith((message) => updates(message as SearchMessagesRequest))
          as SearchMessagesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SearchMessagesRequest() / SearchMessagesRequest.new instead')
  static SearchMessagesRequest create() => SearchMessagesRequest._();
  static $pb.GeneratedMessage $_createMessage() => SearchMessagesRequest._();
  @$core.override
  SearchMessagesRequest createEmptyInstance() => SearchMessagesRequest._();
  @$core.pragma('dart2js:noInline')
  static SearchMessagesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchMessagesRequest>(
          SearchMessagesRequest.$_createMessage);
  static SearchMessagesRequest? _defaultInstance;

  /// Empty returns the most recent messages of the visible scope.
  @$pb.TagNumber(1)
  $core.String get query => $_getSZ(0);
  @$pb.TagNumber(1)
  set query($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQuery() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuery() => $_clearField(1);

  /// Empty searches every conversation the caller is in.
  @$pb.TagNumber(2)
  $core.String get conversationId => $_getSZ(1);
  @$pb.TagNumber(2)
  set conversationId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConversationId() => $_has(1);
  @$pb.TagNumber(2)
  void clearConversationId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);
}

/// A search hit: the message plus enough context to render a result row.
class SearchResult extends $pb.GeneratedMessage {
  factory SearchResult({
    Message? message,
    $core.String? conversationId,
    $core.String? conversationTitle,
    $core.String? senderName,
    $core.String? avatarUrl,
  }) {
    final result = SearchResult._();
    if (message != null) result.message = message;
    if (conversationId != null) result.conversationId = conversationId;
    if (conversationTitle != null) result.conversationTitle = conversationTitle;
    if (senderName != null) result.senderName = senderName;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    return result;
  }

  SearchResult._();

  factory SearchResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SearchResult()..mergeFromBuffer(data, registry);
  factory SearchResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SearchResult()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: SearchResult.$_createMessage)
    ..aOM<Message>(1, _omitFieldNames ? '' : 'message',
        subBuilder: Message.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'conversationId')
    ..aOS(3, _omitFieldNames ? '' : 'conversationTitle')
    ..aOS(4, _omitFieldNames ? '' : 'senderName')
    ..aOS(5, _omitFieldNames ? '' : 'avatarUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchResult copyWith(void Function(SearchResult) updates) =>
      super.copyWith((message) => updates(message as SearchResult))
          as SearchResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SearchResult() / SearchResult.new instead')
  static SearchResult create() => SearchResult._();
  static $pb.GeneratedMessage $_createMessage() => SearchResult._();
  @$core.override
  SearchResult createEmptyInstance() => SearchResult._();
  @$core.pragma('dart2js:noInline')
  static SearchResult getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SearchResult>(
          SearchResult.$_createMessage);
  static SearchResult? _defaultInstance;

  @$pb.TagNumber(1)
  Message get message => $_getN(0);
  @$pb.TagNumber(1)
  set message(Message value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
  @$pb.TagNumber(1)
  Message ensureMessage() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get conversationId => $_getSZ(1);
  @$pb.TagNumber(2)
  set conversationId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConversationId() => $_has(1);
  @$pb.TagNumber(2)
  void clearConversationId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get conversationTitle => $_getSZ(2);
  @$pb.TagNumber(3)
  set conversationTitle($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasConversationTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearConversationTitle() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get senderName => $_getSZ(3);
  @$pb.TagNumber(4)
  set senderName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSenderName() => $_has(3);
  @$pb.TagNumber(4)
  void clearSenderName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get avatarUrl => $_getSZ(4);
  @$pb.TagNumber(5)
  set avatarUrl($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAvatarUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearAvatarUrl() => $_clearField(5);
}

class SearchMessagesResponse extends $pb.GeneratedMessage {
  factory SearchMessagesResponse({
    $core.Iterable<SearchResult>? results,
  }) {
    final result = SearchMessagesResponse._();
    if (results != null) result.results.addAll(results);
    return result;
  }

  SearchMessagesResponse._();

  factory SearchMessagesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SearchMessagesResponse()..mergeFromBuffer(data, registry);
  factory SearchMessagesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SearchMessagesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchMessagesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: SearchMessagesResponse.$_createMessage)
    ..pPM<SearchResult>(1, _omitFieldNames ? '' : 'results',
        subBuilder: SearchResult.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchMessagesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchMessagesResponse copyWith(
          void Function(SearchMessagesResponse) updates) =>
      super.copyWith((message) => updates(message as SearchMessagesResponse))
          as SearchMessagesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SearchMessagesResponse() / SearchMessagesResponse.new instead')
  static SearchMessagesResponse create() => SearchMessagesResponse._();
  static $pb.GeneratedMessage $_createMessage() => SearchMessagesResponse._();
  @$core.override
  SearchMessagesResponse createEmptyInstance() => SearchMessagesResponse._();
  @$core.pragma('dart2js:noInline')
  static SearchMessagesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchMessagesResponse>(
          SearchMessagesResponse.$_createMessage);
  static SearchMessagesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SearchResult> get results => $_getList(0);
}

class UploadAttachmentRequest extends $pb.GeneratedMessage {
  factory UploadAttachmentRequest({
    $core.String? filename,
    $core.String? contentType,
    $core.List<$core.int>? data,
    $core.bool? encrypted,
  }) {
    final result = UploadAttachmentRequest._();
    if (filename != null) result.filename = filename;
    if (contentType != null) result.contentType = contentType;
    if (data != null) result.data = data;
    if (encrypted != null) result.encrypted = encrypted;
    return result;
  }

  UploadAttachmentRequest._();

  factory UploadAttachmentRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadAttachmentRequest()..mergeFromBuffer(data, registry);
  factory UploadAttachmentRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadAttachmentRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadAttachmentRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: UploadAttachmentRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'filename')
    ..aOS(2, _omitFieldNames ? '' : 'contentType')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..aOB(4, _omitFieldNames ? '' : 'encrypted')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadAttachmentRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadAttachmentRequest copyWith(
          void Function(UploadAttachmentRequest) updates) =>
      super.copyWith((message) => updates(message as UploadAttachmentRequest))
          as UploadAttachmentRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UploadAttachmentRequest() / UploadAttachmentRequest.new instead')
  static UploadAttachmentRequest create() => UploadAttachmentRequest._();
  static $pb.GeneratedMessage $_createMessage() => UploadAttachmentRequest._();
  @$core.override
  UploadAttachmentRequest createEmptyInstance() => UploadAttachmentRequest._();
  @$core.pragma('dart2js:noInline')
  static UploadAttachmentRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadAttachmentRequest>(
          UploadAttachmentRequest.$_createMessage);
  static UploadAttachmentRequest? _defaultInstance;

  /// Advisory labels. An encrypted client sends the sealed bytes and leaves the
  /// real filename and type inside the message envelope, so the server stores
  /// these as opaque placeholders.
  @$pb.TagNumber(1)
  $core.String get filename => $_getSZ(0);
  @$pb.TagNumber(1)
  set filename($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFilename() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilename() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get contentType => $_getSZ(1);
  @$pb.TagNumber(2)
  set contentType($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContentType() => $_has(1);
  @$pb.TagNumber(2)
  void clearContentType() => $_clearField(2);

  /// The file itself, or its ciphertext when the client is encrypting.
  @$pb.TagNumber(3)
  $core.List<$core.int> get data => $_getN(2);
  @$pb.TagNumber(3)
  set data($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasData() => $_has(2);
  @$pb.TagNumber(3)
  void clearData() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get encrypted => $_getBF(3);
  @$pb.TagNumber(4)
  set encrypted($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEncrypted() => $_has(3);
  @$pb.TagNumber(4)
  void clearEncrypted() => $_clearField(4);
}

class UploadAttachmentResponse extends $pb.GeneratedMessage {
  factory UploadAttachmentResponse({
    $0.Attachment? attachment,
  }) {
    final result = UploadAttachmentResponse._();
    if (attachment != null) result.attachment = attachment;
    return result;
  }

  UploadAttachmentResponse._();

  factory UploadAttachmentResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadAttachmentResponse()..mergeFromBuffer(data, registry);
  factory UploadAttachmentResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadAttachmentResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadAttachmentResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: UploadAttachmentResponse.$_createMessage)
    ..aOM<$0.Attachment>(1, _omitFieldNames ? '' : 'attachment',
        subBuilder: $0.Attachment.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadAttachmentResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadAttachmentResponse copyWith(
          void Function(UploadAttachmentResponse) updates) =>
      super.copyWith((message) => updates(message as UploadAttachmentResponse))
          as UploadAttachmentResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UploadAttachmentResponse() / UploadAttachmentResponse.new instead')
  static UploadAttachmentResponse create() => UploadAttachmentResponse._();
  static $pb.GeneratedMessage $_createMessage() => UploadAttachmentResponse._();
  @$core.override
  UploadAttachmentResponse createEmptyInstance() =>
      UploadAttachmentResponse._();
  @$core.pragma('dart2js:noInline')
  static UploadAttachmentResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadAttachmentResponse>(
          UploadAttachmentResponse.$_createMessage);
  static UploadAttachmentResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Attachment get attachment => $_getN(0);
  @$pb.TagNumber(1)
  set attachment($0.Attachment value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAttachment() => $_has(0);
  @$pb.TagNumber(1)
  void clearAttachment() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Attachment ensureAttachment() => $_ensure(0);
}

class SubscribeRequest extends $pb.GeneratedMessage {
  factory SubscribeRequest({
    $fixnum.Int64? sinceSeq,
  }) {
    final result = SubscribeRequest._();
    if (sinceSeq != null) result.sinceSeq = sinceSeq;
    return result;
  }

  SubscribeRequest._();

  factory SubscribeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SubscribeRequest()..mergeFromBuffer(data, registry);
  factory SubscribeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SubscribeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscribeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: SubscribeRequest.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'sinceSeq')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeRequest copyWith(void Function(SubscribeRequest) updates) =>
      super.copyWith((message) => updates(message as SubscribeRequest))
          as SubscribeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SubscribeRequest() / SubscribeRequest.new instead')
  static SubscribeRequest create() => SubscribeRequest._();
  static $pb.GeneratedMessage $_createMessage() => SubscribeRequest._();
  @$core.override
  SubscribeRequest createEmptyInstance() => SubscribeRequest._();
  @$core.pragma('dart2js:noInline')
  static SubscribeRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SubscribeRequest>(
          SubscribeRequest.$_createMessage);
  static SubscribeRequest? _defaultInstance;

  /// Informational; the stream always starts at "now" and the client
  /// reconciles with ListConversations / ListMessages.
  @$pb.TagNumber(1)
  $fixnum.Int64 get sinceSeq => $_getI64(0);
  @$pb.TagNumber(1)
  set sinceSeq($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSinceSeq() => $_has(0);
  @$pb.TagNumber(1)
  void clearSinceSeq() => $_clearField(1);
}

enum Event_Payload {
  hello,
  message,
  typing,
  read,
  conversation,
  presence,
  contact,
  notSet
}

/// One frame of the realtime stream. `seq` is a server-wide counter, useful
/// for ordering a client-side log; it is not a per-conversation position.
class Event extends $pb.GeneratedMessage {
  factory Event({
    $fixnum.Int64? seq,
    $1.Timestamp? at,
    Hello? hello,
    MessageEvent? message,
    TypingEvent? typing,
    ReadEvent? read,
    ConversationEvent? conversation,
    PresenceEvent? presence,
    ContactEvent? contact,
  }) {
    final result = Event._();
    if (seq != null) result.seq = seq;
    if (at != null) result.at = at;
    if (hello != null) result.hello = hello;
    if (message != null) result.message = message;
    if (typing != null) result.typing = typing;
    if (read != null) result.read = read;
    if (conversation != null) result.conversation = conversation;
    if (presence != null) result.presence = presence;
    if (contact != null) result.contact = contact;
    return result;
  }

  Event._();

  factory Event.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Event()..mergeFromBuffer(data, registry);
  factory Event.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Event()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Event_Payload> _Event_PayloadByTag = {
    10: Event_Payload.hello,
    11: Event_Payload.message,
    12: Event_Payload.typing,
    13: Event_Payload.read,
    14: Event_Payload.conversation,
    15: Event_Payload.presence,
    16: Event_Payload.contact,
    0: Event_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Event',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: Event.$_createMessage)
    ..oo(0, [10, 11, 12, 13, 14, 15, 16])
    ..aInt64(1, _omitFieldNames ? '' : 'seq')
    ..aOM<$1.Timestamp>(2, _omitFieldNames ? '' : 'at',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aOM<Hello>(10, _omitFieldNames ? '' : 'hello',
        subBuilder: Hello.$_createMessage)
    ..aOM<MessageEvent>(11, _omitFieldNames ? '' : 'message',
        subBuilder: MessageEvent.$_createMessage)
    ..aOM<TypingEvent>(12, _omitFieldNames ? '' : 'typing',
        subBuilder: TypingEvent.$_createMessage)
    ..aOM<ReadEvent>(13, _omitFieldNames ? '' : 'read',
        subBuilder: ReadEvent.$_createMessage)
    ..aOM<ConversationEvent>(14, _omitFieldNames ? '' : 'conversation',
        subBuilder: ConversationEvent.$_createMessage)
    ..aOM<PresenceEvent>(15, _omitFieldNames ? '' : 'presence',
        subBuilder: PresenceEvent.$_createMessage)
    ..aOM<ContactEvent>(16, _omitFieldNames ? '' : 'contact',
        subBuilder: ContactEvent.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Event clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Event copyWith(void Function(Event) updates) =>
      super.copyWith((message) => updates(message as Event)) as Event;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Event() / Event.new instead')
  static Event create() => Event._();
  static $pb.GeneratedMessage $_createMessage() => Event._();
  @$core.override
  Event createEmptyInstance() => Event._();
  @$core.pragma('dart2js:noInline')
  static Event getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Event>(Event.$_createMessage);
  static Event? _defaultInstance;

  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  Event_Payload whichPayload() => _Event_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $fixnum.Int64 get seq => $_getI64(0);
  @$pb.TagNumber(1)
  set seq($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSeq() => $_has(0);
  @$pb.TagNumber(1)
  void clearSeq() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.Timestamp get at => $_getN(1);
  @$pb.TagNumber(2)
  set at($1.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearAt() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Timestamp ensureAt() => $_ensure(1);

  @$pb.TagNumber(10)
  Hello get hello => $_getN(2);
  @$pb.TagNumber(10)
  set hello(Hello value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasHello() => $_has(2);
  @$pb.TagNumber(10)
  void clearHello() => $_clearField(10);
  @$pb.TagNumber(10)
  Hello ensureHello() => $_ensure(2);

  @$pb.TagNumber(11)
  MessageEvent get message => $_getN(3);
  @$pb.TagNumber(11)
  set message(MessageEvent value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasMessage() => $_has(3);
  @$pb.TagNumber(11)
  void clearMessage() => $_clearField(11);
  @$pb.TagNumber(11)
  MessageEvent ensureMessage() => $_ensure(3);

  @$pb.TagNumber(12)
  TypingEvent get typing => $_getN(4);
  @$pb.TagNumber(12)
  set typing(TypingEvent value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasTyping() => $_has(4);
  @$pb.TagNumber(12)
  void clearTyping() => $_clearField(12);
  @$pb.TagNumber(12)
  TypingEvent ensureTyping() => $_ensure(4);

  @$pb.TagNumber(13)
  ReadEvent get read => $_getN(5);
  @$pb.TagNumber(13)
  set read(ReadEvent value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasRead() => $_has(5);
  @$pb.TagNumber(13)
  void clearRead() => $_clearField(13);
  @$pb.TagNumber(13)
  ReadEvent ensureRead() => $_ensure(5);

  @$pb.TagNumber(14)
  ConversationEvent get conversation => $_getN(6);
  @$pb.TagNumber(14)
  set conversation(ConversationEvent value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasConversation() => $_has(6);
  @$pb.TagNumber(14)
  void clearConversation() => $_clearField(14);
  @$pb.TagNumber(14)
  ConversationEvent ensureConversation() => $_ensure(6);

  @$pb.TagNumber(15)
  PresenceEvent get presence => $_getN(7);
  @$pb.TagNumber(15)
  set presence(PresenceEvent value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasPresence() => $_has(7);
  @$pb.TagNumber(15)
  void clearPresence() => $_clearField(15);
  @$pb.TagNumber(15)
  PresenceEvent ensurePresence() => $_ensure(7);

  @$pb.TagNumber(16)
  ContactEvent get contact => $_getN(8);
  @$pb.TagNumber(16)
  set contact(ContactEvent value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasContact() => $_has(8);
  @$pb.TagNumber(16)
  void clearContact() => $_clearField(16);
  @$pb.TagNumber(16)
  ContactEvent ensureContact() => $_ensure(8);
}

/// First frame of a Subscribe stream.
class Hello extends $pb.GeneratedMessage {
  factory Hello({
    $0.User? user,
    $1.Timestamp? serverTime,
  }) {
    final result = Hello._();
    if (user != null) result.user = user;
    if (serverTime != null) result.serverTime = serverTime;
    return result;
  }

  Hello._();

  factory Hello.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Hello()..mergeFromBuffer(data, registry);
  factory Hello.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Hello()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Hello',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: Hello.$_createMessage)
    ..aOM<$0.User>(1, _omitFieldNames ? '' : 'user',
        subBuilder: $0.User.$_createMessage)
    ..aOM<$1.Timestamp>(2, _omitFieldNames ? '' : 'serverTime',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Hello clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Hello copyWith(void Function(Hello) updates) =>
      super.copyWith((message) => updates(message as Hello)) as Hello;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Hello() / Hello.new instead')
  static Hello create() => Hello._();
  static $pb.GeneratedMessage $_createMessage() => Hello._();
  @$core.override
  Hello createEmptyInstance() => Hello._();
  @$core.pragma('dart2js:noInline')
  static Hello getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Hello>(Hello.$_createMessage);
  static Hello? _defaultInstance;

  @$pb.TagNumber(1)
  $0.User get user => $_getN(0);
  @$pb.TagNumber(1)
  set user($0.User value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasUser() => $_has(0);
  @$pb.TagNumber(1)
  void clearUser() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.User ensureUser() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.Timestamp get serverTime => $_getN(1);
  @$pb.TagNumber(2)
  set serverTime($1.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasServerTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerTime() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Timestamp ensureServerTime() => $_ensure(1);
}

/// A message was appended or changed (edit, delete, reaction).
class MessageEvent extends $pb.GeneratedMessage {
  factory MessageEvent({
    Message? message,
  }) {
    final result = MessageEvent._();
    if (message != null) result.message = message;
    return result;
  }

  MessageEvent._();

  factory MessageEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageEvent()..mergeFromBuffer(data, registry);
  factory MessageEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: MessageEvent.$_createMessage)
    ..aOM<Message>(1, _omitFieldNames ? '' : 'message',
        subBuilder: Message.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageEvent copyWith(void Function(MessageEvent) updates) =>
      super.copyWith((message) => updates(message as MessageEvent))
          as MessageEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MessageEvent() / MessageEvent.new instead')
  static MessageEvent create() => MessageEvent._();
  static $pb.GeneratedMessage $_createMessage() => MessageEvent._();
  @$core.override
  MessageEvent createEmptyInstance() => MessageEvent._();
  @$core.pragma('dart2js:noInline')
  static MessageEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MessageEvent>(
          MessageEvent.$_createMessage);
  static MessageEvent? _defaultInstance;

  @$pb.TagNumber(1)
  Message get message => $_getN(0);
  @$pb.TagNumber(1)
  set message(Message value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
  @$pb.TagNumber(1)
  Message ensureMessage() => $_ensure(0);
}

class TypingEvent extends $pb.GeneratedMessage {
  factory TypingEvent({
    $core.String? conversationId,
    $core.String? userId,
    $core.String? displayName,
    $core.bool? typing,
  }) {
    final result = TypingEvent._();
    if (conversationId != null) result.conversationId = conversationId;
    if (userId != null) result.userId = userId;
    if (displayName != null) result.displayName = displayName;
    if (typing != null) result.typing = typing;
    return result;
  }

  TypingEvent._();

  factory TypingEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TypingEvent()..mergeFromBuffer(data, registry);
  factory TypingEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TypingEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TypingEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: TypingEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'displayName')
    ..aOB(4, _omitFieldNames ? '' : 'typing')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TypingEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TypingEvent copyWith(void Function(TypingEvent) updates) =>
      super.copyWith((message) => updates(message as TypingEvent))
          as TypingEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TypingEvent() / TypingEvent.new instead')
  static TypingEvent create() => TypingEvent._();
  static $pb.GeneratedMessage $_createMessage() => TypingEvent._();
  @$core.override
  TypingEvent createEmptyInstance() => TypingEvent._();
  @$core.pragma('dart2js:noInline')
  static TypingEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TypingEvent>(
          TypingEvent.$_createMessage);
  static TypingEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get displayName => $_getSZ(2);
  @$pb.TagNumber(3)
  set displayName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDisplayName() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisplayName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get typing => $_getBF(3);
  @$pb.TagNumber(4)
  set typing($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTyping() => $_has(3);
  @$pb.TagNumber(4)
  void clearTyping() => $_clearField(4);
}

class ReadEvent extends $pb.GeneratedMessage {
  factory ReadEvent({
    $core.String? conversationId,
    $core.String? userId,
    $fixnum.Int64? lastReadSeq,
  }) {
    final result = ReadEvent._();
    if (conversationId != null) result.conversationId = conversationId;
    if (userId != null) result.userId = userId;
    if (lastReadSeq != null) result.lastReadSeq = lastReadSeq;
    return result;
  }

  ReadEvent._();

  factory ReadEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReadEvent()..mergeFromBuffer(data, registry);
  factory ReadEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReadEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: ReadEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aInt64(3, _omitFieldNames ? '' : 'lastReadSeq')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadEvent copyWith(void Function(ReadEvent) updates) =>
      super.copyWith((message) => updates(message as ReadEvent)) as ReadEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReadEvent() / ReadEvent.new instead')
  static ReadEvent create() => ReadEvent._();
  static $pb.GeneratedMessage $_createMessage() => ReadEvent._();
  @$core.override
  ReadEvent createEmptyInstance() => ReadEvent._();
  @$core.pragma('dart2js:noInline')
  static ReadEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadEvent>(ReadEvent.$_createMessage);
  static ReadEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get lastReadSeq => $_getI64(2);
  @$pb.TagNumber(3)
  set lastReadSeq($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLastReadSeq() => $_has(2);
  @$pb.TagNumber(3)
  void clearLastReadSeq() => $_clearField(3);
}

class ConversationEvent extends $pb.GeneratedMessage {
  factory ConversationEvent({
    Conversation? conversation,
    $core.bool? created,
    $core.bool? removed,
  }) {
    final result = ConversationEvent._();
    if (conversation != null) result.conversation = conversation;
    if (created != null) result.created = created;
    if (removed != null) result.removed = removed;
    return result;
  }

  ConversationEvent._();

  factory ConversationEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConversationEvent()..mergeFromBuffer(data, registry);
  factory ConversationEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConversationEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConversationEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: ConversationEvent.$_createMessage)
    ..aOM<Conversation>(1, _omitFieldNames ? '' : 'conversation',
        subBuilder: Conversation.$_createMessage)
    ..aOB(2, _omitFieldNames ? '' : 'created')
    ..aOB(3, _omitFieldNames ? '' : 'removed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConversationEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConversationEvent copyWith(void Function(ConversationEvent) updates) =>
      super.copyWith((message) => updates(message as ConversationEvent))
          as ConversationEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConversationEvent() / ConversationEvent.new instead')
  static ConversationEvent create() => ConversationEvent._();
  static $pb.GeneratedMessage $_createMessage() => ConversationEvent._();
  @$core.override
  ConversationEvent createEmptyInstance() => ConversationEvent._();
  @$core.pragma('dart2js:noInline')
  static ConversationEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConversationEvent>(
          ConversationEvent.$_createMessage);
  static ConversationEvent? _defaultInstance;

  @$pb.TagNumber(1)
  Conversation get conversation => $_getN(0);
  @$pb.TagNumber(1)
  set conversation(Conversation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConversation() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversation() => $_clearField(1);
  @$pb.TagNumber(1)
  Conversation ensureConversation() => $_ensure(0);

  /// A new conversation for the viewer, so clients can add it.
  @$pb.TagNumber(2)
  $core.bool get created => $_getBF(1);
  @$pb.TagNumber(2)
  set created($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCreated() => $_has(1);
  @$pb.TagNumber(2)
  void clearCreated() => $_clearField(2);

  /// The viewer was removed; drop it from the list.
  @$pb.TagNumber(3)
  $core.bool get removed => $_getBF(2);
  @$pb.TagNumber(3)
  set removed($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRemoved() => $_has(2);
  @$pb.TagNumber(3)
  void clearRemoved() => $_clearField(3);
}

class PresenceEvent extends $pb.GeneratedMessage {
  factory PresenceEvent({
    $core.String? userId,
    $0.Presence? presence,
    $1.Timestamp? lastSeen,
  }) {
    final result = PresenceEvent._();
    if (userId != null) result.userId = userId;
    if (presence != null) result.presence = presence;
    if (lastSeen != null) result.lastSeen = lastSeen;
    return result;
  }

  PresenceEvent._();

  factory PresenceEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PresenceEvent()..mergeFromBuffer(data, registry);
  factory PresenceEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PresenceEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PresenceEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: PresenceEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aE<$0.Presence>(2, _omitFieldNames ? '' : 'presence',
        enumValues: $0.Presence.values)
    ..aOM<$1.Timestamp>(3, _omitFieldNames ? '' : 'lastSeen',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PresenceEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PresenceEvent copyWith(void Function(PresenceEvent) updates) =>
      super.copyWith((message) => updates(message as PresenceEvent))
          as PresenceEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PresenceEvent() / PresenceEvent.new instead')
  static PresenceEvent create() => PresenceEvent._();
  static $pb.GeneratedMessage $_createMessage() => PresenceEvent._();
  @$core.override
  PresenceEvent createEmptyInstance() => PresenceEvent._();
  @$core.pragma('dart2js:noInline')
  static PresenceEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PresenceEvent>(
          PresenceEvent.$_createMessage);
  static PresenceEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Presence get presence => $_getN(1);
  @$pb.TagNumber(2)
  set presence($0.Presence value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPresence() => $_has(1);
  @$pb.TagNumber(2)
  void clearPresence() => $_clearField(2);

  @$pb.TagNumber(3)
  $1.Timestamp get lastSeen => $_getN(2);
  @$pb.TagNumber(3)
  set lastSeen($1.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasLastSeen() => $_has(2);
  @$pb.TagNumber(3)
  void clearLastSeen() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.Timestamp ensureLastSeen() => $_ensure(2);
}

/// Contacts changed, e.g. someone redeemed your invite.
class ContactEvent extends $pb.GeneratedMessage {
  factory ContactEvent({
    $core.String? kind,
    $0.User? user,
    $core.String? conversationId,
  }) {
    final result = ContactEvent._();
    if (kind != null) result.kind = kind;
    if (user != null) result.user = user;
    if (conversationId != null) result.conversationId = conversationId;
    return result;
  }

  ContactEvent._();

  factory ContactEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContactEvent()..mergeFromBuffer(data, registry);
  factory ContactEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContactEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContactEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: ContactEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'kind')
    ..aOM<$0.User>(2, _omitFieldNames ? '' : 'user',
        subBuilder: $0.User.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'conversationId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContactEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContactEvent copyWith(void Function(ContactEvent) updates) =>
      super.copyWith((message) => updates(message as ContactEvent))
          as ContactEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ContactEvent() / ContactEvent.new instead')
  static ContactEvent create() => ContactEvent._();
  static $pb.GeneratedMessage $_createMessage() => ContactEvent._();
  @$core.override
  ContactEvent createEmptyInstance() => ContactEvent._();
  @$core.pragma('dart2js:noInline')
  static ContactEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ContactEvent>(
          ContactEvent.$_createMessage);
  static ContactEvent? _defaultInstance;

  /// "added" or "removed".
  @$pb.TagNumber(1)
  $core.String get kind => $_getSZ(0);
  @$pb.TagNumber(1)
  set kind($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.User get user => $_getN(1);
  @$pb.TagNumber(2)
  set user($0.User value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUser() => $_has(1);
  @$pb.TagNumber(2)
  void clearUser() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.User ensureUser() => $_ensure(1);

  /// Set when the change also created a direct conversation.
  @$pb.TagNumber(3)
  $core.String get conversationId => $_getSZ(2);
  @$pb.TagNumber(3)
  set conversationId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasConversationId() => $_has(2);
  @$pb.TagNumber(3)
  void clearConversationId() => $_clearField(3);
}

/// Conversations, messages and the realtime stream.
///
/// Ordering: every conversation owns a strictly increasing `seq`, assigned by
/// the server on append. Clients paginate and resume by seq, never by time, so
/// a reconnect cannot miss or duplicate a message.
class ChatServiceApi {
  final $pb.RpcClient _client;

  ChatServiceApi(this._client);

  /// Conversations the caller is a member of, most recently active first.
  $async.Future<ListConversationsResponse> listConversations(
          $pb.ClientContext? ctx, ListConversationsRequest request) =>
      _client.invoke<ListConversationsResponse>(ctx, 'ChatService',
          'ListConversations', request, ListConversationsResponse());

  /// A single conversation, refreshed for the caller.
  $async.Future<GetConversationResponse> getConversation(
          $pb.ClientContext? ctx, GetConversationRequest request) =>
      _client.invoke<GetConversationResponse>(ctx, 'ChatService',
          'GetConversation', request, GetConversationResponse());

  /// Reuse or create the 1:1 conversation with another user.
  $async.Future<CreateDirectConversationResponse> createDirectConversation(
          $pb.ClientContext? ctx, CreateDirectConversationRequest request) =>
      _client.invoke<CreateDirectConversationResponse>(
          ctx,
          'ChatService',
          'CreateDirectConversation',
          request,
          CreateDirectConversationResponse());

  /// Create a group conversation owned by the caller.
  $async.Future<CreateGroupConversationResponse> createGroupConversation(
          $pb.ClientContext? ctx, CreateGroupConversationRequest request) =>
      _client.invoke<CreateGroupConversationResponse>(
          ctx,
          'ChatService',
          'CreateGroupConversation',
          request,
          CreateGroupConversationResponse());

  /// Rename, re-picture, mute or pin a conversation.
  $async.Future<UpdateConversationResponse> updateConversation(
          $pb.ClientContext? ctx, UpdateConversationRequest request) =>
      _client.invoke<UpdateConversationResponse>(ctx, 'ChatService',
          'UpdateConversation', request, UpdateConversationResponse());

  /// Add users to a group; they see the history from their join point.
  $async.Future<AddMembersResponse> addMembers(
          $pb.ClientContext? ctx, AddMembersRequest request) =>
      _client.invoke<AddMembersResponse>(
          ctx, 'ChatService', 'AddMembers', request, AddMembersResponse());

  /// Remove a member from a group (owner, or leaving yourself).
  $async.Future<RemoveMemberResponse> removeMember(
          $pb.ClientContext? ctx, RemoveMemberRequest request) =>
      _client.invoke<RemoveMemberResponse>(
          ctx, 'ChatService', 'RemoveMember', request, RemoveMemberResponse());

  /// Messages, oldest first, paged by seq in either direction.
  $async.Future<ListMessagesResponse> listMessages(
          $pb.ClientContext? ctx, ListMessagesRequest request) =>
      _client.invoke<ListMessagesResponse>(
          ctx, 'ChatService', 'ListMessages', request, ListMessagesResponse());

  /// Append a message. `client_message_id` makes retries idempotent.
  $async.Future<SendMessageResponse> sendMessage(
          $pb.ClientContext? ctx, SendMessageRequest request) =>
      _client.invoke<SendMessageResponse>(
          ctx, 'ChatService', 'SendMessage', request, SendMessageResponse());

  /// Rewrite the text of your own message.
  $async.Future<EditMessageResponse> editMessage(
          $pb.ClientContext? ctx, EditMessageRequest request) =>
      _client.invoke<EditMessageResponse>(
          ctx, 'ChatService', 'EditMessage', request, EditMessageResponse());

  /// Tombstone your own message; attachments are dropped from the store view.
  $async.Future<DeleteMessageResponse> deleteMessage(
          $pb.ClientContext? ctx, DeleteMessageRequest request) =>
      _client.invoke<DeleteMessageResponse>(ctx, 'ChatService', 'DeleteMessage',
          request, DeleteMessageResponse());

  /// Toggle one emoji reaction from the caller.
  $async.Future<AddReactionResponse> addReaction(
          $pb.ClientContext? ctx, AddReactionRequest request) =>
      _client.invoke<AddReactionResponse>(
          ctx, 'ChatService', 'AddReaction', request, AddReactionResponse());
  $async.Future<RemoveReactionResponse> removeReaction(
          $pb.ClientContext? ctx, RemoveReactionRequest request) =>
      _client.invoke<RemoveReactionResponse>(ctx, 'ChatService',
          'RemoveReaction', request, RemoveReactionResponse());

  /// Advance the caller's read cursor, clearing their unread badge.
  $async.Future<MarkReadResponse> markRead(
          $pb.ClientContext? ctx, MarkReadRequest request) =>
      _client.invoke<MarkReadResponse>(
          ctx, 'ChatService', 'MarkRead', request, MarkReadResponse());

  /// Broadcast a typing indicator for a few seconds. Nothing is persisted.
  $async.Future<SetTypingResponse> setTyping(
          $pb.ClientContext? ctx, SetTypingRequest request) =>
      _client.invoke<SetTypingResponse>(
          ctx, 'ChatService', 'SetTyping', request, SetTypingResponse());

  /// Substring search over the caller's conversations. It can only match
  /// plaintext: end-to-end encrypted message bodies are opaque to the server, so
  /// an encrypted conversation returns nothing here and the client searches
  /// locally instead (docs/E2EE.md).
  $async.Future<SearchMessagesResponse> searchMessages(
          $pb.ClientContext? ctx, SearchMessagesRequest request) =>
      _client.invoke<SearchMessagesResponse>(ctx, 'ChatService',
          'SearchMessages', request, SearchMessagesResponse());

  /// Upload one file (attachment or profile picture) and get its id back.
  $async.Future<UploadAttachmentResponse> uploadAttachment(
          $pb.ClientContext? ctx, UploadAttachmentRequest request) =>
      _client.invoke<UploadAttachmentResponse>(ctx, 'ChatService',
          'UploadAttachment', request, UploadAttachmentResponse());

  /// Server stream of everything that happens to the caller: new and edited
  /// messages, typing, read cursors, presence, conversation and contact changes.
  $async.Future<Event> subscribe(
          $pb.ClientContext? ctx, SubscribeRequest request) =>
      _client.invoke<Event>(ctx, 'ChatService', 'Subscribe', request, Event());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
