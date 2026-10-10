// This is a generated file - do not edit.
//
// Generated from ratatosk/v1/social.proto.

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
    as $1;

import 'chat.pb.dart' as $2;
import 'common.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// A contact plus the direct conversation shared with them.
class Contact extends $pb.GeneratedMessage {
  factory Contact({
    $0.User? user,
    $1.Timestamp? since,
    $core.String? conversationId,
    $core.bool? blocked,
  }) {
    final result = Contact._();
    if (user != null) result.user = user;
    if (since != null) result.since = since;
    if (conversationId != null) result.conversationId = conversationId;
    if (blocked != null) result.blocked = blocked;
    return result;
  }

  Contact._();

  factory Contact.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Contact()..mergeFromBuffer(data, registry);
  factory Contact.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Contact()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Contact',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: Contact.$_createMessage)
    ..aOM<$0.User>(1, _omitFieldNames ? '' : 'user',
        subBuilder: $0.User.$_createMessage)
    ..aOM<$1.Timestamp>(2, _omitFieldNames ? '' : 'since',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'conversationId')
    ..aOB(4, _omitFieldNames ? '' : 'blocked')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Contact clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Contact copyWith(void Function(Contact) updates) =>
      super.copyWith((message) => updates(message as Contact)) as Contact;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Contact() / Contact.new instead')
  static Contact create() => Contact._();
  static $pb.GeneratedMessage $_createMessage() => Contact._();
  @$core.override
  Contact createEmptyInstance() => Contact._();
  @$core.pragma('dart2js:noInline')
  static Contact getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Contact>(Contact.$_createMessage);
  static Contact? _defaultInstance;

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
  $1.Timestamp get since => $_getN(1);
  @$pb.TagNumber(2)
  set since($1.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSince() => $_has(1);
  @$pb.TagNumber(2)
  void clearSince() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Timestamp ensureSince() => $_ensure(1);

  /// Direct conversation id, empty when it was never created.
  @$pb.TagNumber(3)
  $core.String get conversationId => $_getSZ(2);
  @$pb.TagNumber(3)
  set conversationId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasConversationId() => $_has(2);
  @$pb.TagNumber(3)
  void clearConversationId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get blocked => $_getBF(3);
  @$pb.TagNumber(4)
  set blocked($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBlocked() => $_has(3);
  @$pb.TagNumber(4)
  void clearBlocked() => $_clearField(4);
}

/// A shareable invitation. The link is `<public_url>/join/<code>`, which is
/// both a web landing page and a deep link the app understands.
class Invite extends $pb.GeneratedMessage {
  factory Invite({
    $core.String? code,
    $core.String? url,
    $1.Timestamp? createdAt,
    $1.Timestamp? expiresAt,
    $core.int? maxUses,
    $core.int? uses,
    $core.bool? revoked,
    $core.Iterable<$core.String>? redeemedBy,
    $core.bool? valid,
  }) {
    final result = Invite._();
    if (code != null) result.code = code;
    if (url != null) result.url = url;
    if (createdAt != null) result.createdAt = createdAt;
    if (expiresAt != null) result.expiresAt = expiresAt;
    if (maxUses != null) result.maxUses = maxUses;
    if (uses != null) result.uses = uses;
    if (revoked != null) result.revoked = revoked;
    if (redeemedBy != null) result.redeemedBy.addAll(redeemedBy);
    if (valid != null) result.valid = valid;
    return result;
  }

  Invite._();

  factory Invite.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Invite()..mergeFromBuffer(data, registry);
  factory Invite.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Invite()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Invite',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: Invite.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aOS(2, _omitFieldNames ? '' : 'url')
    ..aOM<$1.Timestamp>(3, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aOM<$1.Timestamp>(4, _omitFieldNames ? '' : 'expiresAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aI(5, _omitFieldNames ? '' : 'maxUses')
    ..aI(6, _omitFieldNames ? '' : 'uses')
    ..aOB(7, _omitFieldNames ? '' : 'revoked')
    ..pPS(8, _omitFieldNames ? '' : 'redeemedBy')
    ..aOB(9, _omitFieldNames ? '' : 'valid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Invite clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Invite copyWith(void Function(Invite) updates) =>
      super.copyWith((message) => updates(message as Invite)) as Invite;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Invite() / Invite.new instead')
  static Invite create() => Invite._();
  static $pb.GeneratedMessage $_createMessage() => Invite._();
  @$core.override
  Invite createEmptyInstance() => Invite._();
  @$core.pragma('dart2js:noInline')
  static Invite getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Invite>(Invite.$_createMessage);
  static Invite? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get url => $_getSZ(1);
  @$pb.TagNumber(2)
  set url($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearUrl() => $_clearField(2);

  @$pb.TagNumber(3)
  $1.Timestamp get createdAt => $_getN(2);
  @$pb.TagNumber(3)
  set createdAt($1.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCreatedAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreatedAt() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.Timestamp ensureCreatedAt() => $_ensure(2);

  /// Zero means the invite never expires.
  @$pb.TagNumber(4)
  $1.Timestamp get expiresAt => $_getN(3);
  @$pb.TagNumber(4)
  set expiresAt($1.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasExpiresAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearExpiresAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.Timestamp ensureExpiresAt() => $_ensure(3);

  /// Zero means unlimited.
  @$pb.TagNumber(5)
  $core.int get maxUses => $_getIZ(4);
  @$pb.TagNumber(5)
  set maxUses($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMaxUses() => $_has(4);
  @$pb.TagNumber(5)
  void clearMaxUses() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get uses => $_getIZ(5);
  @$pb.TagNumber(6)
  set uses($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUses() => $_has(5);
  @$pb.TagNumber(6)
  void clearUses() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get revoked => $_getBF(6);
  @$pb.TagNumber(7)
  set revoked($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasRevoked() => $_has(6);
  @$pb.TagNumber(7)
  void clearRevoked() => $_clearField(7);

  /// Display names of the people who already joined, newest first.
  @$pb.TagNumber(8)
  $pb.PbList<$core.String> get redeemedBy => $_getList(7);

  @$pb.TagNumber(9)
  $core.bool get valid => $_getBF(8);
  @$pb.TagNumber(9)
  set valid($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasValid() => $_has(8);
  @$pb.TagNumber(9)
  void clearValid() => $_clearField(9);
}

class ListContactsRequest extends $pb.GeneratedMessage {
  factory ListContactsRequest() => ListContactsRequest._();

  ListContactsRequest._();

  factory ListContactsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListContactsRequest()..mergeFromBuffer(data, registry);
  factory ListContactsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListContactsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListContactsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: ListContactsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListContactsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListContactsRequest copyWith(void Function(ListContactsRequest) updates) =>
      super.copyWith((message) => updates(message as ListContactsRequest))
          as ListContactsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ListContactsRequest() / ListContactsRequest.new instead')
  static ListContactsRequest create() => ListContactsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListContactsRequest._();
  @$core.override
  ListContactsRequest createEmptyInstance() => ListContactsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListContactsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListContactsRequest>(
          ListContactsRequest.$_createMessage);
  static ListContactsRequest? _defaultInstance;
}

class ListContactsResponse extends $pb.GeneratedMessage {
  factory ListContactsResponse({
    $core.Iterable<Contact>? contacts,
  }) {
    final result = ListContactsResponse._();
    if (contacts != null) result.contacts.addAll(contacts);
    return result;
  }

  ListContactsResponse._();

  factory ListContactsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListContactsResponse()..mergeFromBuffer(data, registry);
  factory ListContactsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListContactsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListContactsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: ListContactsResponse.$_createMessage)
    ..pPM<Contact>(1, _omitFieldNames ? '' : 'contacts',
        subBuilder: Contact.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListContactsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListContactsResponse copyWith(void Function(ListContactsResponse) updates) =>
      super.copyWith((message) => updates(message as ListContactsResponse))
          as ListContactsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListContactsResponse() / ListContactsResponse.new instead')
  static ListContactsResponse create() => ListContactsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListContactsResponse._();
  @$core.override
  ListContactsResponse createEmptyInstance() => ListContactsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListContactsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListContactsResponse>(
          ListContactsResponse.$_createMessage);
  static ListContactsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Contact> get contacts => $_getList(0);
}

class AddContactRequest extends $pb.GeneratedMessage {
  factory AddContactRequest({
    $core.String? username,
  }) {
    final result = AddContactRequest._();
    if (username != null) result.username = username;
    return result;
  }

  AddContactRequest._();

  factory AddContactRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddContactRequest()..mergeFromBuffer(data, registry);
  factory AddContactRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddContactRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddContactRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: AddContactRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddContactRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddContactRequest copyWith(void Function(AddContactRequest) updates) =>
      super.copyWith((message) => updates(message as AddContactRequest))
          as AddContactRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AddContactRequest() / AddContactRequest.new instead')
  static AddContactRequest create() => AddContactRequest._();
  static $pb.GeneratedMessage $_createMessage() => AddContactRequest._();
  @$core.override
  AddContactRequest createEmptyInstance() => AddContactRequest._();
  @$core.pragma('dart2js:noInline')
  static AddContactRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddContactRequest>(
          AddContactRequest.$_createMessage);
  static AddContactRequest? _defaultInstance;

  /// Handle or display name; must match exactly one account.
  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);
}

class AddContactResponse extends $pb.GeneratedMessage {
  factory AddContactResponse({
    Contact? contact,
    $2.Conversation? conversation,
  }) {
    final result = AddContactResponse._();
    if (contact != null) result.contact = contact;
    if (conversation != null) result.conversation = conversation;
    return result;
  }

  AddContactResponse._();

  factory AddContactResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddContactResponse()..mergeFromBuffer(data, registry);
  factory AddContactResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddContactResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddContactResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: AddContactResponse.$_createMessage)
    ..aOM<Contact>(1, _omitFieldNames ? '' : 'contact',
        subBuilder: Contact.$_createMessage)
    ..aOM<$2.Conversation>(2, _omitFieldNames ? '' : 'conversation',
        subBuilder: $2.Conversation.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddContactResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddContactResponse copyWith(void Function(AddContactResponse) updates) =>
      super.copyWith((message) => updates(message as AddContactResponse))
          as AddContactResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AddContactResponse() / AddContactResponse.new instead')
  static AddContactResponse create() => AddContactResponse._();
  static $pb.GeneratedMessage $_createMessage() => AddContactResponse._();
  @$core.override
  AddContactResponse createEmptyInstance() => AddContactResponse._();
  @$core.pragma('dart2js:noInline')
  static AddContactResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddContactResponse>(
          AddContactResponse.$_createMessage);
  static AddContactResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Contact get contact => $_getN(0);
  @$pb.TagNumber(1)
  set contact(Contact value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasContact() => $_has(0);
  @$pb.TagNumber(1)
  void clearContact() => $_clearField(1);
  @$pb.TagNumber(1)
  Contact ensureContact() => $_ensure(0);

  @$pb.TagNumber(2)
  $2.Conversation get conversation => $_getN(1);
  @$pb.TagNumber(2)
  set conversation($2.Conversation value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasConversation() => $_has(1);
  @$pb.TagNumber(2)
  void clearConversation() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.Conversation ensureConversation() => $_ensure(1);
}

class RemoveContactRequest extends $pb.GeneratedMessage {
  factory RemoveContactRequest({
    $core.String? userId,
  }) {
    final result = RemoveContactRequest._();
    if (userId != null) result.userId = userId;
    return result;
  }

  RemoveContactRequest._();

  factory RemoveContactRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveContactRequest()..mergeFromBuffer(data, registry);
  factory RemoveContactRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveContactRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveContactRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: RemoveContactRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveContactRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveContactRequest copyWith(void Function(RemoveContactRequest) updates) =>
      super.copyWith((message) => updates(message as RemoveContactRequest))
          as RemoveContactRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RemoveContactRequest() / RemoveContactRequest.new instead')
  static RemoveContactRequest create() => RemoveContactRequest._();
  static $pb.GeneratedMessage $_createMessage() => RemoveContactRequest._();
  @$core.override
  RemoveContactRequest createEmptyInstance() => RemoveContactRequest._();
  @$core.pragma('dart2js:noInline')
  static RemoveContactRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveContactRequest>(
          RemoveContactRequest.$_createMessage);
  static RemoveContactRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);
}

class RemoveContactResponse extends $pb.GeneratedMessage {
  factory RemoveContactResponse() => RemoveContactResponse._();

  RemoveContactResponse._();

  factory RemoveContactResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveContactResponse()..mergeFromBuffer(data, registry);
  factory RemoveContactResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveContactResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveContactResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: RemoveContactResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveContactResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveContactResponse copyWith(
          void Function(RemoveContactResponse) updates) =>
      super.copyWith((message) => updates(message as RemoveContactResponse))
          as RemoveContactResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RemoveContactResponse() / RemoveContactResponse.new instead')
  static RemoveContactResponse create() => RemoveContactResponse._();
  static $pb.GeneratedMessage $_createMessage() => RemoveContactResponse._();
  @$core.override
  RemoveContactResponse createEmptyInstance() => RemoveContactResponse._();
  @$core.pragma('dart2js:noInline')
  static RemoveContactResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveContactResponse>(
          RemoveContactResponse.$_createMessage);
  static RemoveContactResponse? _defaultInstance;
}

class SearchUsersRequest extends $pb.GeneratedMessage {
  factory SearchUsersRequest({
    $core.String? query,
    $core.int? limit,
  }) {
    final result = SearchUsersRequest._();
    if (query != null) result.query = query;
    if (limit != null) result.limit = limit;
    return result;
  }

  SearchUsersRequest._();

  factory SearchUsersRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SearchUsersRequest()..mergeFromBuffer(data, registry);
  factory SearchUsersRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SearchUsersRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchUsersRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: SearchUsersRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'query')
    ..aI(2, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchUsersRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchUsersRequest copyWith(void Function(SearchUsersRequest) updates) =>
      super.copyWith((message) => updates(message as SearchUsersRequest))
          as SearchUsersRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SearchUsersRequest() / SearchUsersRequest.new instead')
  static SearchUsersRequest create() => SearchUsersRequest._();
  static $pb.GeneratedMessage $_createMessage() => SearchUsersRequest._();
  @$core.override
  SearchUsersRequest createEmptyInstance() => SearchUsersRequest._();
  @$core.pragma('dart2js:noInline')
  static SearchUsersRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchUsersRequest>(
          SearchUsersRequest.$_createMessage);
  static SearchUsersRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get query => $_getSZ(0);
  @$pb.TagNumber(1)
  set query($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQuery() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuery() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);
}

class SearchUsersResponse extends $pb.GeneratedMessage {
  factory SearchUsersResponse({
    $core.Iterable<$0.User>? users,
  }) {
    final result = SearchUsersResponse._();
    if (users != null) result.users.addAll(users);
    return result;
  }

  SearchUsersResponse._();

  factory SearchUsersResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SearchUsersResponse()..mergeFromBuffer(data, registry);
  factory SearchUsersResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SearchUsersResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchUsersResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: SearchUsersResponse.$_createMessage)
    ..pPM<$0.User>(1, _omitFieldNames ? '' : 'users',
        subBuilder: $0.User.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchUsersResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchUsersResponse copyWith(void Function(SearchUsersResponse) updates) =>
      super.copyWith((message) => updates(message as SearchUsersResponse))
          as SearchUsersResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SearchUsersResponse() / SearchUsersResponse.new instead')
  static SearchUsersResponse create() => SearchUsersResponse._();
  static $pb.GeneratedMessage $_createMessage() => SearchUsersResponse._();
  @$core.override
  SearchUsersResponse createEmptyInstance() => SearchUsersResponse._();
  @$core.pragma('dart2js:noInline')
  static SearchUsersResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchUsersResponse>(
          SearchUsersResponse.$_createMessage);
  static SearchUsersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.User> get users => $_getList(0);
}

class CreateInviteRequest extends $pb.GeneratedMessage {
  factory CreateInviteRequest({
    $core.int? expiresInHours,
    $core.int? maxUses,
  }) {
    final result = CreateInviteRequest._();
    if (expiresInHours != null) result.expiresInHours = expiresInHours;
    if (maxUses != null) result.maxUses = maxUses;
    return result;
  }

  CreateInviteRequest._();

  factory CreateInviteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateInviteRequest()..mergeFromBuffer(data, registry);
  factory CreateInviteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateInviteRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateInviteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: CreateInviteRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'expiresInHours')
    ..aI(2, _omitFieldNames ? '' : 'maxUses')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateInviteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateInviteRequest copyWith(void Function(CreateInviteRequest) updates) =>
      super.copyWith((message) => updates(message as CreateInviteRequest))
          as CreateInviteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use CreateInviteRequest() / CreateInviteRequest.new instead')
  static CreateInviteRequest create() => CreateInviteRequest._();
  static $pb.GeneratedMessage $_createMessage() => CreateInviteRequest._();
  @$core.override
  CreateInviteRequest createEmptyInstance() => CreateInviteRequest._();
  @$core.pragma('dart2js:noInline')
  static CreateInviteRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateInviteRequest>(
          CreateInviteRequest.$_createMessage);
  static CreateInviteRequest? _defaultInstance;

  /// Hours until the link expires; 0 uses the server default, negative means
  /// never.
  @$pb.TagNumber(1)
  $core.int get expiresInHours => $_getIZ(0);
  @$pb.TagNumber(1)
  set expiresInHours($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExpiresInHours() => $_has(0);
  @$pb.TagNumber(1)
  void clearExpiresInHours() => $_clearField(1);

  /// 0 uses the server default; negative means unlimited.
  @$pb.TagNumber(2)
  $core.int get maxUses => $_getIZ(1);
  @$pb.TagNumber(2)
  set maxUses($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMaxUses() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaxUses() => $_clearField(2);
}

class CreateInviteResponse extends $pb.GeneratedMessage {
  factory CreateInviteResponse({
    Invite? invite,
  }) {
    final result = CreateInviteResponse._();
    if (invite != null) result.invite = invite;
    return result;
  }

  CreateInviteResponse._();

  factory CreateInviteResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateInviteResponse()..mergeFromBuffer(data, registry);
  factory CreateInviteResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateInviteResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateInviteResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: CreateInviteResponse.$_createMessage)
    ..aOM<Invite>(1, _omitFieldNames ? '' : 'invite',
        subBuilder: Invite.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateInviteResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateInviteResponse copyWith(void Function(CreateInviteResponse) updates) =>
      super.copyWith((message) => updates(message as CreateInviteResponse))
          as CreateInviteResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreateInviteResponse() / CreateInviteResponse.new instead')
  static CreateInviteResponse create() => CreateInviteResponse._();
  static $pb.GeneratedMessage $_createMessage() => CreateInviteResponse._();
  @$core.override
  CreateInviteResponse createEmptyInstance() => CreateInviteResponse._();
  @$core.pragma('dart2js:noInline')
  static CreateInviteResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateInviteResponse>(
          CreateInviteResponse.$_createMessage);
  static CreateInviteResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Invite get invite => $_getN(0);
  @$pb.TagNumber(1)
  set invite(Invite value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasInvite() => $_has(0);
  @$pb.TagNumber(1)
  void clearInvite() => $_clearField(1);
  @$pb.TagNumber(1)
  Invite ensureInvite() => $_ensure(0);
}

class ListInvitesRequest extends $pb.GeneratedMessage {
  factory ListInvitesRequest() => ListInvitesRequest._();

  ListInvitesRequest._();

  factory ListInvitesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListInvitesRequest()..mergeFromBuffer(data, registry);
  factory ListInvitesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListInvitesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListInvitesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: ListInvitesRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListInvitesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListInvitesRequest copyWith(void Function(ListInvitesRequest) updates) =>
      super.copyWith((message) => updates(message as ListInvitesRequest))
          as ListInvitesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListInvitesRequest() / ListInvitesRequest.new instead')
  static ListInvitesRequest create() => ListInvitesRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListInvitesRequest._();
  @$core.override
  ListInvitesRequest createEmptyInstance() => ListInvitesRequest._();
  @$core.pragma('dart2js:noInline')
  static ListInvitesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListInvitesRequest>(
          ListInvitesRequest.$_createMessage);
  static ListInvitesRequest? _defaultInstance;
}

class ListInvitesResponse extends $pb.GeneratedMessage {
  factory ListInvitesResponse({
    $core.Iterable<Invite>? invites,
  }) {
    final result = ListInvitesResponse._();
    if (invites != null) result.invites.addAll(invites);
    return result;
  }

  ListInvitesResponse._();

  factory ListInvitesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListInvitesResponse()..mergeFromBuffer(data, registry);
  factory ListInvitesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListInvitesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListInvitesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: ListInvitesResponse.$_createMessage)
    ..pPM<Invite>(1, _omitFieldNames ? '' : 'invites',
        subBuilder: Invite.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListInvitesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListInvitesResponse copyWith(void Function(ListInvitesResponse) updates) =>
      super.copyWith((message) => updates(message as ListInvitesResponse))
          as ListInvitesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ListInvitesResponse() / ListInvitesResponse.new instead')
  static ListInvitesResponse create() => ListInvitesResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListInvitesResponse._();
  @$core.override
  ListInvitesResponse createEmptyInstance() => ListInvitesResponse._();
  @$core.pragma('dart2js:noInline')
  static ListInvitesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListInvitesResponse>(
          ListInvitesResponse.$_createMessage);
  static ListInvitesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Invite> get invites => $_getList(0);
}

class RevokeInviteRequest extends $pb.GeneratedMessage {
  factory RevokeInviteRequest({
    $core.String? code,
  }) {
    final result = RevokeInviteRequest._();
    if (code != null) result.code = code;
    return result;
  }

  RevokeInviteRequest._();

  factory RevokeInviteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeInviteRequest()..mergeFromBuffer(data, registry);
  factory RevokeInviteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeInviteRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeInviteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: RevokeInviteRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeInviteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeInviteRequest copyWith(void Function(RevokeInviteRequest) updates) =>
      super.copyWith((message) => updates(message as RevokeInviteRequest))
          as RevokeInviteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use RevokeInviteRequest() / RevokeInviteRequest.new instead')
  static RevokeInviteRequest create() => RevokeInviteRequest._();
  static $pb.GeneratedMessage $_createMessage() => RevokeInviteRequest._();
  @$core.override
  RevokeInviteRequest createEmptyInstance() => RevokeInviteRequest._();
  @$core.pragma('dart2js:noInline')
  static RevokeInviteRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RevokeInviteRequest>(
          RevokeInviteRequest.$_createMessage);
  static RevokeInviteRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);
}

class RevokeInviteResponse extends $pb.GeneratedMessage {
  factory RevokeInviteResponse() => RevokeInviteResponse._();

  RevokeInviteResponse._();

  factory RevokeInviteResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeInviteResponse()..mergeFromBuffer(data, registry);
  factory RevokeInviteResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeInviteResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeInviteResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: RevokeInviteResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeInviteResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeInviteResponse copyWith(void Function(RevokeInviteResponse) updates) =>
      super.copyWith((message) => updates(message as RevokeInviteResponse))
          as RevokeInviteResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RevokeInviteResponse() / RevokeInviteResponse.new instead')
  static RevokeInviteResponse create() => RevokeInviteResponse._();
  static $pb.GeneratedMessage $_createMessage() => RevokeInviteResponse._();
  @$core.override
  RevokeInviteResponse createEmptyInstance() => RevokeInviteResponse._();
  @$core.pragma('dart2js:noInline')
  static RevokeInviteResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RevokeInviteResponse>(
          RevokeInviteResponse.$_createMessage);
  static RevokeInviteResponse? _defaultInstance;
}

class PreviewInviteRequest extends $pb.GeneratedMessage {
  factory PreviewInviteRequest({
    $core.String? code,
  }) {
    final result = PreviewInviteRequest._();
    if (code != null) result.code = code;
    return result;
  }

  PreviewInviteRequest._();

  factory PreviewInviteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewInviteRequest()..mergeFromBuffer(data, registry);
  factory PreviewInviteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewInviteRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewInviteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: PreviewInviteRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewInviteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewInviteRequest copyWith(void Function(PreviewInviteRequest) updates) =>
      super.copyWith((message) => updates(message as PreviewInviteRequest))
          as PreviewInviteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PreviewInviteRequest() / PreviewInviteRequest.new instead')
  static PreviewInviteRequest create() => PreviewInviteRequest._();
  static $pb.GeneratedMessage $_createMessage() => PreviewInviteRequest._();
  @$core.override
  PreviewInviteRequest createEmptyInstance() => PreviewInviteRequest._();
  @$core.pragma('dart2js:noInline')
  static PreviewInviteRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreviewInviteRequest>(
          PreviewInviteRequest.$_createMessage);
  static PreviewInviteRequest? _defaultInstance;

  /// Code or a full invite link.
  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);
}

class PreviewInviteResponse extends $pb.GeneratedMessage {
  factory PreviewInviteResponse({
    $core.bool? valid,
    $0.User? inviter,
    $core.String? reason,
    $1.Timestamp? expiresAt,
    $core.int? remainingUses,
    $core.bool? alreadyContacts,
  }) {
    final result = PreviewInviteResponse._();
    if (valid != null) result.valid = valid;
    if (inviter != null) result.inviter = inviter;
    if (reason != null) result.reason = reason;
    if (expiresAt != null) result.expiresAt = expiresAt;
    if (remainingUses != null) result.remainingUses = remainingUses;
    if (alreadyContacts != null) result.alreadyContacts = alreadyContacts;
    return result;
  }

  PreviewInviteResponse._();

  factory PreviewInviteResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewInviteResponse()..mergeFromBuffer(data, registry);
  factory PreviewInviteResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewInviteResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewInviteResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: PreviewInviteResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'valid')
    ..aOM<$0.User>(2, _omitFieldNames ? '' : 'inviter',
        subBuilder: $0.User.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'reason')
    ..aOM<$1.Timestamp>(4, _omitFieldNames ? '' : 'expiresAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aI(5, _omitFieldNames ? '' : 'remainingUses')
    ..aOB(6, _omitFieldNames ? '' : 'alreadyContacts')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewInviteResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewInviteResponse copyWith(
          void Function(PreviewInviteResponse) updates) =>
      super.copyWith((message) => updates(message as PreviewInviteResponse))
          as PreviewInviteResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PreviewInviteResponse() / PreviewInviteResponse.new instead')
  static PreviewInviteResponse create() => PreviewInviteResponse._();
  static $pb.GeneratedMessage $_createMessage() => PreviewInviteResponse._();
  @$core.override
  PreviewInviteResponse createEmptyInstance() => PreviewInviteResponse._();
  @$core.pragma('dart2js:noInline')
  static PreviewInviteResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreviewInviteResponse>(
          PreviewInviteResponse.$_createMessage);
  static PreviewInviteResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get valid => $_getBF(0);
  @$pb.TagNumber(1)
  set valid($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValid() => $_has(0);
  @$pb.TagNumber(1)
  void clearValid() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.User get inviter => $_getN(1);
  @$pb.TagNumber(2)
  set inviter($0.User value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasInviter() => $_has(1);
  @$pb.TagNumber(2)
  void clearInviter() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.User ensureInviter() => $_ensure(1);

  /// Why it is invalid: "unknown", "revoked", "expired", "exhausted".
  @$pb.TagNumber(3)
  $core.String get reason => $_getSZ(2);
  @$pb.TagNumber(3)
  set reason($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReason() => $_has(2);
  @$pb.TagNumber(3)
  void clearReason() => $_clearField(3);

  @$pb.TagNumber(4)
  $1.Timestamp get expiresAt => $_getN(3);
  @$pb.TagNumber(4)
  set expiresAt($1.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasExpiresAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearExpiresAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.Timestamp ensureExpiresAt() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.int get remainingUses => $_getIZ(4);
  @$pb.TagNumber(5)
  set remainingUses($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRemainingUses() => $_has(4);
  @$pb.TagNumber(5)
  void clearRemainingUses() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get alreadyContacts => $_getBF(5);
  @$pb.TagNumber(6)
  set alreadyContacts($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAlreadyContacts() => $_has(5);
  @$pb.TagNumber(6)
  void clearAlreadyContacts() => $_clearField(6);
}

class RedeemInviteRequest extends $pb.GeneratedMessage {
  factory RedeemInviteRequest({
    $core.String? code,
  }) {
    final result = RedeemInviteRequest._();
    if (code != null) result.code = code;
    return result;
  }

  RedeemInviteRequest._();

  factory RedeemInviteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RedeemInviteRequest()..mergeFromBuffer(data, registry);
  factory RedeemInviteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RedeemInviteRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RedeemInviteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: RedeemInviteRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RedeemInviteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RedeemInviteRequest copyWith(void Function(RedeemInviteRequest) updates) =>
      super.copyWith((message) => updates(message as RedeemInviteRequest))
          as RedeemInviteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use RedeemInviteRequest() / RedeemInviteRequest.new instead')
  static RedeemInviteRequest create() => RedeemInviteRequest._();
  static $pb.GeneratedMessage $_createMessage() => RedeemInviteRequest._();
  @$core.override
  RedeemInviteRequest createEmptyInstance() => RedeemInviteRequest._();
  @$core.pragma('dart2js:noInline')
  static RedeemInviteRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RedeemInviteRequest>(
          RedeemInviteRequest.$_createMessage);
  static RedeemInviteRequest? _defaultInstance;

  /// Code or a full invite link.
  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);
}

class RedeemInviteResponse extends $pb.GeneratedMessage {
  factory RedeemInviteResponse({
    $0.User? inviter,
    $2.Conversation? conversation,
  }) {
    final result = RedeemInviteResponse._();
    if (inviter != null) result.inviter = inviter;
    if (conversation != null) result.conversation = conversation;
    return result;
  }

  RedeemInviteResponse._();

  factory RedeemInviteResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RedeemInviteResponse()..mergeFromBuffer(data, registry);
  factory RedeemInviteResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RedeemInviteResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RedeemInviteResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: RedeemInviteResponse.$_createMessage)
    ..aOM<$0.User>(1, _omitFieldNames ? '' : 'inviter',
        subBuilder: $0.User.$_createMessage)
    ..aOM<$2.Conversation>(2, _omitFieldNames ? '' : 'conversation',
        subBuilder: $2.Conversation.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RedeemInviteResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RedeemInviteResponse copyWith(void Function(RedeemInviteResponse) updates) =>
      super.copyWith((message) => updates(message as RedeemInviteResponse))
          as RedeemInviteResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RedeemInviteResponse() / RedeemInviteResponse.new instead')
  static RedeemInviteResponse create() => RedeemInviteResponse._();
  static $pb.GeneratedMessage $_createMessage() => RedeemInviteResponse._();
  @$core.override
  RedeemInviteResponse createEmptyInstance() => RedeemInviteResponse._();
  @$core.pragma('dart2js:noInline')
  static RedeemInviteResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RedeemInviteResponse>(
          RedeemInviteResponse.$_createMessage);
  static RedeemInviteResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $0.User get inviter => $_getN(0);
  @$pb.TagNumber(1)
  set inviter($0.User value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasInviter() => $_has(0);
  @$pb.TagNumber(1)
  void clearInviter() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.User ensureInviter() => $_ensure(0);

  @$pb.TagNumber(2)
  $2.Conversation get conversation => $_getN(1);
  @$pb.TagNumber(2)
  set conversation($2.Conversation value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasConversation() => $_has(1);
  @$pb.TagNumber(2)
  void clearConversation() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.Conversation ensureConversation() => $_ensure(1);
}

/// Contacts, discovery and invitation links.
class SocialServiceApi {
  final $pb.RpcClient _client;

  SocialServiceApi(this._client);

  /// The caller's contacts, newest first.
  $async.Future<ListContactsResponse> listContacts(
          $pb.ClientContext? ctx, ListContactsRequest request) =>
      _client.invoke<ListContactsResponse>(ctx, 'SocialService', 'ListContacts',
          request, ListContactsResponse());

  /// Become contacts with a user by handle, creating the direct conversation.
  $async.Future<AddContactResponse> addContact(
          $pb.ClientContext? ctx, AddContactRequest request) =>
      _client.invoke<AddContactResponse>(
          ctx, 'SocialService', 'AddContact', request, AddContactResponse());

  /// Drop a contact (history and conversations are kept).
  $async.Future<RemoveContactResponse> removeContact(
          $pb.ClientContext? ctx, RemoveContactRequest request) =>
      _client.invoke<RemoveContactResponse>(ctx, 'SocialService',
          'RemoveContact', request, RemoveContactResponse());

  /// Find people by handle or display name; empty query lists recent users.
  $async.Future<SearchUsersResponse> searchUsers(
          $pb.ClientContext? ctx, SearchUsersRequest request) =>
      _client.invoke<SearchUsersResponse>(
          ctx, 'SocialService', 'SearchUsers', request, SearchUsersResponse());

  /// Mint an invite link that makes two users contacts when redeemed.
  $async.Future<CreateInviteResponse> createInvite(
          $pb.ClientContext? ctx, CreateInviteRequest request) =>
      _client.invoke<CreateInviteResponse>(ctx, 'SocialService', 'CreateInvite',
          request, CreateInviteResponse());

  /// Invites the caller created, newest first.
  $async.Future<ListInvitesResponse> listInvites(
          $pb.ClientContext? ctx, ListInvitesRequest request) =>
      _client.invoke<ListInvitesResponse>(
          ctx, 'SocialService', 'ListInvites', request, ListInvitesResponse());

  /// Invalidate an invite link.
  $async.Future<RevokeInviteResponse> revokeInvite(
          $pb.ClientContext? ctx, RevokeInviteRequest request) =>
      _client.invoke<RevokeInviteResponse>(ctx, 'SocialService', 'RevokeInvite',
          request, RevokeInviteResponse());

  /// Look at an invite without redeeming it. No token required, so the invite
  /// landing page can show who invited you.
  $async.Future<PreviewInviteResponse> previewInvite(
          $pb.ClientContext? ctx, PreviewInviteRequest request) =>
      _client.invoke<PreviewInviteResponse>(ctx, 'SocialService',
          'PreviewInvite', request, PreviewInviteResponse());

  /// Redeem an invite: both sides become contacts.
  $async.Future<RedeemInviteResponse> redeemInvite(
          $pb.ClientContext? ctx, RedeemInviteRequest request) =>
      _client.invoke<RedeemInviteResponse>(ctx, 'SocialService', 'RedeemInvite',
          request, RedeemInviteResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
