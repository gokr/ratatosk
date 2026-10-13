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

import 'keys.pb.dart' as $1;
import 'keys.pbjson.dart';

export 'keys.pb.dart';

abstract class KeyServiceBase extends $pb.GeneratedService {
  $async.Future<$1.PublishDeviceKeyResponse> publishDeviceKey(
      $pb.ServerContext ctx, $1.PublishDeviceKeyRequest request);
  $async.Future<$1.ListDeviceKeysResponse> listDeviceKeys(
      $pb.ServerContext ctx, $1.ListDeviceKeysRequest request);
  $async.Future<$1.RevokeDeviceKeyResponse> revokeDeviceKey(
      $pb.ServerContext ctx, $1.RevokeDeviceKeyRequest request);
  $async.Future<$1.PutKeyEnvelopeResponse> putKeyEnvelope(
      $pb.ServerContext ctx, $1.PutKeyEnvelopeRequest request);
  $async.Future<$1.ListKeyEnvelopesResponse> listKeyEnvelopes(
      $pb.ServerContext ctx, $1.ListKeyEnvelopesRequest request);
  $async.Future<$1.PutKeyBackupResponse> putKeyBackup(
      $pb.ServerContext ctx, $1.PutKeyBackupRequest request);
  $async.Future<$1.GetKeyBackupResponse> getKeyBackup(
      $pb.ServerContext ctx, $1.GetKeyBackupRequest request);
  $async.Future<$1.DeleteKeyBackupResponse> deleteKeyBackup(
      $pb.ServerContext ctx, $1.DeleteKeyBackupRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'PublishDeviceKey':
        return $1.PublishDeviceKeyRequest();
      case 'ListDeviceKeys':
        return $1.ListDeviceKeysRequest();
      case 'RevokeDeviceKey':
        return $1.RevokeDeviceKeyRequest();
      case 'PutKeyEnvelope':
        return $1.PutKeyEnvelopeRequest();
      case 'ListKeyEnvelopes':
        return $1.ListKeyEnvelopesRequest();
      case 'PutKeyBackup':
        return $1.PutKeyBackupRequest();
      case 'GetKeyBackup':
        return $1.GetKeyBackupRequest();
      case 'DeleteKeyBackup':
        return $1.DeleteKeyBackupRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'PublishDeviceKey':
        return publishDeviceKey(ctx, request as $1.PublishDeviceKeyRequest);
      case 'ListDeviceKeys':
        return listDeviceKeys(ctx, request as $1.ListDeviceKeysRequest);
      case 'RevokeDeviceKey':
        return revokeDeviceKey(ctx, request as $1.RevokeDeviceKeyRequest);
      case 'PutKeyEnvelope':
        return putKeyEnvelope(ctx, request as $1.PutKeyEnvelopeRequest);
      case 'ListKeyEnvelopes':
        return listKeyEnvelopes(ctx, request as $1.ListKeyEnvelopesRequest);
      case 'PutKeyBackup':
        return putKeyBackup(ctx, request as $1.PutKeyBackupRequest);
      case 'GetKeyBackup':
        return getKeyBackup(ctx, request as $1.GetKeyBackupRequest);
      case 'DeleteKeyBackup':
        return deleteKeyBackup(ctx, request as $1.DeleteKeyBackupRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => KeyServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => KeyServiceBase$messageJson;
}
