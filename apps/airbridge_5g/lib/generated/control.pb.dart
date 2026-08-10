//
//  Generated code. Do not modify.
//  source: proto/control/v1/control.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'control.pbenum.dart';

export 'control.pbenum.dart';

class GetStatusRequest extends $pb.GeneratedMessage {
  factory GetStatusRequest() => create();
  GetStatusRequest._() : super();
  factory GetStatusRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetStatusRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetStatusRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. Use [GeneratedMessageGenericExtensions.deepCopy] instead. Will be removed in 3.0.0')
  GetStatusRequest clone() => GetStatusRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. Use [GeneratedMessageGenericExtensions.rebuild] instead. Will be removed in 3.0.0')
  GetStatusRequest copyWith(void Function(GetStatusRequest) updates) => super.copyWith((message) => updates(message as GetStatusRequest)) as GetStatusRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetStatusRequest create() => GetStatusRequest._();
  GetStatusRequest createEmptyInstance() => create();
  static $pb.PbList<GetStatusRequest> createRepeated() => $pb.PbList<GetStatusRequest>();
  @$core.pragma('dart2js:noInline')
  static GetStatusRequest getDefault() => _defaultInstance ??= create();
  static GetStatusRequest? _defaultInstance;
}

class GetStatusResponse extends $pb.GeneratedMessage {
  factory GetStatusResponse({
    $core.String? nodeId,
    TunnelState? tunnelState,
    NodeRole? role,
    $core.int? connectedPeers,
    $fixnum.Int64? startedAtUnixMs,
    $fixnum.Int64? uptimeSeconds,
    $core.String? version,
    $core.String? platform,
  }) {
    final $result = create();
    if (nodeId != null) $result.nodeId = nodeId;
    if (tunnelState != null) $result.tunnelState = tunnelState;
    if (role != null) $result.role = role;
    if (connectedPeers != null) $result.connectedPeers = connectedPeers;
    if (startedAtUnixMs != null) $result.startedAtUnixMs = startedAtUnixMs;
    if (uptimeSeconds != null) $result.uptimeSeconds = uptimeSeconds;
    if (version != null) $result.version = version;
    if (platform != null) $result.platform = platform;
    return $result;
  }
  GetStatusResponse._() : super();
  factory GetStatusResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetStatusResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetStatusResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nodeId')
    ..e<TunnelState>(2, _omitFieldNames ? '' : 'tunnelState', $pb.PbFieldType.OE, defaultOrMaker: TunnelState.TUNNEL_STATE_UNSPECIFIED, valueOf: TunnelState.valueOf, enumValues: TunnelState.values)
    ..e<NodeRole>(3, _omitFieldNames ? '' : 'role', $pb.PbFieldType.OE, defaultOrMaker: NodeRole.NODE_ROLE_UNSPECIFIED, valueOf: NodeRole.valueOf, enumValues: NodeRole.values)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'connectedPeers', $pb.PbFieldType.OU3)
    ..aInt64(5, _omitFieldNames ? '' : 'startedAtUnixMs')
    ..aInt64(6, _omitFieldNames ? '' : 'uptimeSeconds')
    ..aOS(7, _omitFieldNames ? '' : 'version')
    ..aOS(8, _omitFieldNames ? '' : 'platform')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. Use [GeneratedMessageGenericExtensions.deepCopy] instead. Will be removed in 3.0.0')
  GetStatusResponse clone() => GetStatusResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. Use [GeneratedMessageGenericExtensions.rebuild] instead. Will be removed in 3.0.0')
  GetStatusResponse copyWith(void Function(GetStatusResponse) updates) => super.copyWith((message) => updates(message as GetStatusResponse)) as GetStatusResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetStatusResponse create() => GetStatusResponse._();
  GetStatusResponse createEmptyInstance() => create();
  static $pb.PbList<GetStatusResponse> createRepeated() => $pb.PbList<GetStatusResponse>();
  @$core.pragma('dart2js:noInline')
  static GetStatusResponse getDefault() => _defaultInstance ??= create();
  static GetStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set nodeId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeId() => clearField(1);

  @$pb.TagNumber(2)
  TunnelState get tunnelState => $_getN(1);
  @$pb.TagNumber(2)
  set tunnelState(TunnelState v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTunnelState() => $_has(1);
  @$pb.TagNumber(2)
  void clearTunnelState() => clearField(2);

  @$pb.TagNumber(3)
  NodeRole get role => $_getN(2);
  @$pb.TagNumber(3)
  set role(NodeRole v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasRole() => $_has(2);
  @$pb.TagNumber(3)
  void clearRole() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get connectedPeers => $_getIZ(3);
  @$pb.TagNumber(4)
  set connectedPeers($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasConnectedPeers() => $_has(3);
  @$pb.TagNumber(4)
  void clearConnectedPeers() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get startedAtUnixMs => $_getI64(4);
  @$pb.TagNumber(5)
  set startedAtUnixMs($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasStartedAtUnixMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearStartedAtUnixMs() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get uptimeSeconds => $_getI64(5);
  @$pb.TagNumber(6)
  set uptimeSeconds($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasUptimeSeconds() => $_has(5);
  @$pb.TagNumber(6)
  void clearUptimeSeconds() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get version => $_getSZ(6);
  @$pb.TagNumber(7)
  set version($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasVersion() => $_has(6);
  @$pb.TagNumber(7)
  void clearVersion() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get platform => $_getSZ(7);
  @$pb.TagNumber(8)
  set platform($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasPlatform() => $_has(7);
  @$pb.TagNumber(8)
  void clearPlatform() => clearField(8);
}

class StartTunnelRequest extends $pb.GeneratedMessage {
  factory StartTunnelRequest({
    NodeRole? role,
  }) {
    final $result = create();
    if (role != null) $result.role = role;
    return $result;
  }
  StartTunnelRequest._() : super();
  factory StartTunnelRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StartTunnelRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StartTunnelRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..e<NodeRole>(1, _omitFieldNames ? '' : 'role', $pb.PbFieldType.OE, defaultOrMaker: NodeRole.NODE_ROLE_UNSPECIFIED, valueOf: NodeRole.valueOf, enumValues: NodeRole.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. Use [GeneratedMessageGenericExtensions.deepCopy] instead. Will be removed in 3.0.0')
  StartTunnelRequest clone() => StartTunnelRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. Use [GeneratedMessageGenericExtensions.rebuild] instead. Will be removed in 3.0.0')
  StartTunnelRequest copyWith(void Function(StartTunnelRequest) updates) => super.copyWith((message) => updates(message as StartTunnelRequest)) as StartTunnelRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartTunnelRequest create() => StartTunnelRequest._();
  StartTunnelRequest createEmptyInstance() => create();
  static $pb.PbList<StartTunnelRequest> createRepeated() => $pb.PbList<StartTunnelRequest>();
  @$core.pragma('dart2js:noInline')
  static StartTunnelRequest getDefault() => _defaultInstance ??= create();
  static StartTunnelRequest? _defaultInstance;

  @$pb.TagNumber(1)
  NodeRole get role => $_getN(0);
  @$pb.TagNumber(1)
  set role(NodeRole v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasRole() => $_has(0);
  @$pb.TagNumber(1)
  void clearRole() => clearField(1);
}

class StartTunnelResponse extends $pb.GeneratedMessage {
  factory StartTunnelResponse({
    TunnelState? state,
    $core.String? proxyAddress,
    $core.int? quicPort,
  }) {
    final $result = create();
    if (state != null) $result.state = state;
    if (proxyAddress != null) $result.proxyAddress = proxyAddress;
    if (quicPort != null) $result.quicPort = quicPort;
    return $result;
  }
  StartTunnelResponse._() : super();
  factory StartTunnelResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StartTunnelResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StartTunnelResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..e<TunnelState>(1, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE, defaultOrMaker: TunnelState.TUNNEL_STATE_UNSPECIFIED, valueOf: TunnelState.valueOf, enumValues: TunnelState.values)
    ..aOS(2, _omitFieldNames ? '' : 'proxyAddress')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'quicPort', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. Use [GeneratedMessageGenericExtensions.deepCopy] instead. Will be removed in 3.0.0')
  StartTunnelResponse clone() => StartTunnelResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. Use [GeneratedMessageGenericExtensions.rebuild] instead. Will be removed in 3.0.0')
  StartTunnelResponse copyWith(void Function(StartTunnelResponse) updates) => super.copyWith((message) => updates(message as StartTunnelResponse)) as StartTunnelResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartTunnelResponse create() => StartTunnelResponse._();
  StartTunnelResponse createEmptyInstance() => create();
  static $pb.PbList<StartTunnelResponse> createRepeated() => $pb.PbList<StartTunnelResponse>();
  @$core.pragma('dart2js:noInline')
  static StartTunnelResponse getDefault() => _defaultInstance ??= create();
  static StartTunnelResponse? _defaultInstance;

  @$pb.TagNumber(1)
  TunnelState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(TunnelState v) { setField(1, v); }

  @$pb.TagNumber(2)
  $core.String get proxyAddress => $_getSZ(1);
  @$pb.TagNumber(2)
  set proxyAddress($core.String v) { $_setString(1, v); }

  @$pb.TagNumber(3)
  $core.int get quicPort => $_getIZ(2);
  @$pb.TagNumber(3)
  set quicPort($core.int v) { $_setUnsignedInt32(2, v); }
}

class StopTunnelRequest extends $pb.GeneratedMessage {
  factory StopTunnelRequest() => create();
  StopTunnelRequest._() : super();
  factory StopTunnelRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StopTunnelRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StopTunnelRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..hasRequiredFields = false;

  StopTunnelRequest clone() => StopTunnelRequest()..mergeFromMessage(this);
  StopTunnelRequest copyWith(void Function(StopTunnelRequest) updates) => super.copyWith((message) => updates(message as StopTunnelRequest)) as StopTunnelRequest;
  $pb.BuilderInfo get info_ => _i;
  static StopTunnelRequest create() => StopTunnelRequest._();
  StopTunnelRequest createEmptyInstance() => create();
  static $pb.PbList<StopTunnelRequest> createRepeated() => $pb.PbList<StopTunnelRequest>();
  static StopTunnelRequest getDefault() => _defaultInstance ??= create();
  static StopTunnelRequest? _defaultInstance;
}

class StopTunnelResponse extends $pb.GeneratedMessage {
  factory StopTunnelResponse({TunnelState? state}) {
    final $result = create();
    if (state != null) $result.state = state;
    return $result;
  }
  StopTunnelResponse._() : super();
  factory StopTunnelResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StopTunnelResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StopTunnelResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..e<TunnelState>(1, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE, defaultOrMaker: TunnelState.TUNNEL_STATE_UNSPECIFIED, valueOf: TunnelState.valueOf, enumValues: TunnelState.values)
    ..hasRequiredFields = false;

  StopTunnelResponse clone() => StopTunnelResponse()..mergeFromMessage(this);
  StopTunnelResponse copyWith(void Function(StopTunnelResponse) updates) => super.copyWith((message) => updates(message as StopTunnelResponse)) as StopTunnelResponse;
  $pb.BuilderInfo get info_ => _i;
  static StopTunnelResponse create() => StopTunnelResponse._();
  StopTunnelResponse createEmptyInstance() => create();
  static $pb.PbList<StopTunnelResponse> createRepeated() => $pb.PbList<StopTunnelResponse>();
  static StopTunnelResponse getDefault() => _defaultInstance ??= create();
  static StopTunnelResponse? _defaultInstance;

  @$pb.TagNumber(1)
  TunnelState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(TunnelState v) { setField(1, v); }
}

class GenerateQRRequest extends $pb.GeneratedMessage {
  factory GenerateQRRequest() => create();
  GenerateQRRequest._() : super();
  factory GenerateQRRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GenerateQRRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GenerateQRRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..hasRequiredFields = false;

  GenerateQRRequest clone() => GenerateQRRequest()..mergeFromMessage(this);
  GenerateQRRequest copyWith(void Function(GenerateQRRequest) updates) => super.copyWith((message) => updates(message as GenerateQRRequest)) as GenerateQRRequest;
  $pb.BuilderInfo get info_ => _i;
  static GenerateQRRequest create() => GenerateQRRequest._();
  GenerateQRRequest createEmptyInstance() => create();
  static $pb.PbList<GenerateQRRequest> createRepeated() => $pb.PbList<GenerateQRRequest>();
  static GenerateQRRequest getDefault() => _defaultInstance ??= create();
  static GenerateQRRequest? _defaultInstance;
}

class GenerateQRResponse extends $pb.GeneratedMessage {
  factory GenerateQRResponse({
    $core.String? qrPayload,
    $core.String? proxyHost,
    $core.int? proxyPort,
    $core.int? quicPort,
    $core.List<$core.int>? encryptionKey,
    $fixnum.Int64? expiresAtUnixMs,
  }) {
    final $result = create();
    if (qrPayload != null) $result.qrPayload = qrPayload;
    if (proxyHost != null) $result.proxyHost = proxyHost;
    if (proxyPort != null) $result.proxyPort = proxyPort;
    if (quicPort != null) $result.quicPort = quicPort;
    if (encryptionKey != null) $result.encryptionKey = encryptionKey;
    if (expiresAtUnixMs != null) $result.expiresAtUnixMs = expiresAtUnixMs;
    return $result;
  }
  GenerateQRResponse._() : super();
  factory GenerateQRResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GenerateQRResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GenerateQRResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'qrPayload')
    ..aOS(2, _omitFieldNames ? '' : 'proxyHost')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'proxyPort', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'quicPort', $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(5, _omitFieldNames ? '' : 'encryptionKey', $pb.PbFieldType.OY)
    ..aInt64(6, _omitFieldNames ? '' : 'expiresAtUnixMs')
    ..hasRequiredFields = false;

  GenerateQRResponse clone() => GenerateQRResponse()..mergeFromMessage(this);
  GenerateQRResponse copyWith(void Function(GenerateQRResponse) updates) => super.copyWith((message) => updates(message as GenerateQRResponse)) as GenerateQRResponse;
  $pb.BuilderInfo get info_ => _i;
  static GenerateQRResponse create() => GenerateQRResponse._();
  GenerateQRResponse createEmptyInstance() => create();
  static $pb.PbList<GenerateQRResponse> createRepeated() => $pb.PbList<GenerateQRResponse>();
  static GenerateQRResponse getDefault() => _defaultInstance ??= create();
  static GenerateQRResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get qrPayload => $_getSZ(0);
  @$pb.TagNumber(1)
  set qrPayload($core.String v) { $_setString(0, v); }

  @$pb.TagNumber(2)
  $core.String get proxyHost => $_getSZ(1);
  @$pb.TagNumber(2)
  set proxyHost($core.String v) { $_setString(1, v); }

  @$pb.TagNumber(3)
  $core.int get proxyPort => $_getIZ(2);
  @$pb.TagNumber(3)
  set proxyPort($core.int v) { $_setUnsignedInt32(2, v); }

  @$pb.TagNumber(4)
  $core.int get quicPort => $_getIZ(3);
  @$pb.TagNumber(4)
  set quicPort($core.int v) { $_setUnsignedInt32(3, v); }

  @$pb.TagNumber(5)
  $core.List<$core.int> get encryptionKey => $_getN(4);
  @$pb.TagNumber(5)
  set encryptionKey($core.List<$core.int> v) { setField(5, v); }

  @$pb.TagNumber(6)
  $fixnum.Int64 get expiresAtUnixMs => $_getI64(5);
  @$pb.TagNumber(6)
  set expiresAtUnixMs($fixnum.Int64 v) { $_setInt64(5, v); }
}

class ImportQRRequest extends $pb.GeneratedMessage {
  factory ImportQRRequest({$core.String? qrPayload}) {
    final $result = create();
    if (qrPayload != null) $result.qrPayload = qrPayload;
    return $result;
  }
  ImportQRRequest._() : super();
  factory ImportQRRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ImportQRRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ImportQRRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'qrPayload')
    ..hasRequiredFields = false;

  ImportQRRequest clone() => ImportQRRequest()..mergeFromMessage(this);
  ImportQRRequest copyWith(void Function(ImportQRRequest) updates) => super.copyWith((message) => updates(message as ImportQRRequest)) as ImportQRRequest;
  $pb.BuilderInfo get info_ => _i;
  static ImportQRRequest create() => ImportQRRequest._();
  ImportQRRequest createEmptyInstance() => create();
  static $pb.PbList<ImportQRRequest> createRepeated() => $pb.PbList<ImportQRRequest>();
  static ImportQRRequest getDefault() => _defaultInstance ??= create();
  static ImportQRRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get qrPayload => $_getSZ(0);
  @$pb.TagNumber(1)
  set qrPayload($core.String v) { $_setString(0, v); }
}

class ImportQRResponse extends $pb.GeneratedMessage {
  factory ImportQRResponse({
    $core.bool? success,
    $core.String? peerId,
    $core.String? proxyAddress,
    $core.String? errorMessage,
  }) {
    final $result = create();
    if (success != null) $result.success = success;
    if (peerId != null) $result.peerId = peerId;
    if (proxyAddress != null) $result.proxyAddress = proxyAddress;
    if (errorMessage != null) $result.errorMessage = errorMessage;
    return $result;
  }
  ImportQRResponse._() : super();
  factory ImportQRResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ImportQRResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ImportQRResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'peerId')
    ..aOS(3, _omitFieldNames ? '' : 'proxyAddress')
    ..aOS(4, _omitFieldNames ? '' : 'errorMessage')
    ..hasRequiredFields = false;

  ImportQRResponse clone() => ImportQRResponse()..mergeFromMessage(this);
  ImportQRResponse copyWith(void Function(ImportQRResponse) updates) => super.copyWith((message) => updates(message as ImportQRResponse)) as ImportQRResponse;
  $pb.BuilderInfo get info_ => _i;
  static ImportQRResponse create() => ImportQRResponse._();
  ImportQRResponse createEmptyInstance() => create();
  static $pb.PbList<ImportQRResponse> createRepeated() => $pb.PbList<ImportQRResponse>();
  static ImportQRResponse getDefault() => _defaultInstance ??= create();
  static ImportQRResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool v) { $_setBool(0, v); }

  @$pb.TagNumber(2)
  $core.String get peerId => $_getSZ(1);
  @$pb.TagNumber(2)
  set peerId($core.String v) { $_setString(1, v); }

  @$pb.TagNumber(3)
  $core.String get proxyAddress => $_getSZ(2);
  @$pb.TagNumber(3)
  set proxyAddress($core.String v) { $_setString(2, v); }

  @$pb.TagNumber(4)
  $core.String get errorMessage => $_getSZ(3);
  @$pb.TagNumber(4)
  set errorMessage($core.String v) { $_setString(3, v); }
}

class StreamTrafficStatsRequest extends $pb.GeneratedMessage {
  factory StreamTrafficStatsRequest({$core.int? intervalMs}) {
    final $result = create();
    if (intervalMs != null) $result.intervalMs = intervalMs;
    return $result;
  }
  StreamTrafficStatsRequest._() : super();
  factory StreamTrafficStatsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StreamTrafficStatsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StreamTrafficStatsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'intervalMs', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  StreamTrafficStatsRequest clone() => StreamTrafficStatsRequest()..mergeFromMessage(this);
  StreamTrafficStatsRequest copyWith(void Function(StreamTrafficStatsRequest) updates) => super.copyWith((message) => updates(message as StreamTrafficStatsRequest)) as StreamTrafficStatsRequest;
  $pb.BuilderInfo get info_ => _i;
  static StreamTrafficStatsRequest create() => StreamTrafficStatsRequest._();
  StreamTrafficStatsRequest createEmptyInstance() => create();
  static $pb.PbList<StreamTrafficStatsRequest> createRepeated() => $pb.PbList<StreamTrafficStatsRequest>();
  static StreamTrafficStatsRequest getDefault() => _defaultInstance ??= create();
  static StreamTrafficStatsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get intervalMs => $_getIZ(0);
  @$pb.TagNumber(1)
  set intervalMs($core.int v) { $_setUnsignedInt32(0, v); }
}

class TrafficStatsUpdate extends $pb.GeneratedMessage {
  factory TrafficStatsUpdate({
    TrafficSnapshot? snapshot,
    $fixnum.Int64? timestampUnixMs,
  }) {
    final $result = create();
    if (snapshot != null) $result.snapshot = snapshot;
    if (timestampUnixMs != null) $result.timestampUnixMs = timestampUnixMs;
    return $result;
  }
  TrafficStatsUpdate._() : super();
  factory TrafficStatsUpdate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TrafficStatsUpdate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TrafficStatsUpdate', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..aOM<TrafficSnapshot>(1, _omitFieldNames ? '' : 'snapshot', subBuilder: TrafficSnapshot.create)
    ..aInt64(2, _omitFieldNames ? '' : 'timestampUnixMs')
    ..hasRequiredFields = false;

  TrafficStatsUpdate clone() => TrafficStatsUpdate()..mergeFromMessage(this);
  TrafficStatsUpdate copyWith(void Function(TrafficStatsUpdate) updates) => super.copyWith((message) => updates(message as TrafficStatsUpdate)) as TrafficStatsUpdate;
  $pb.BuilderInfo get info_ => _i;
  static TrafficStatsUpdate create() => TrafficStatsUpdate._();
  TrafficStatsUpdate createEmptyInstance() => create();
  static $pb.PbList<TrafficStatsUpdate> createRepeated() => $pb.PbList<TrafficStatsUpdate>();
  static TrafficStatsUpdate getDefault() => _defaultInstance ??= create();
  static TrafficStatsUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  TrafficSnapshot get snapshot => $_getN(0);
  @$pb.TagNumber(1)
  set snapshot(TrafficSnapshot v) { setField(1, v); }
  @$pb.TagNumber(2)
  $fixnum.Int64 get timestampUnixMs => $_getI64(1);
  @$pb.TagNumber(2)
  set timestampUnixMs($fixnum.Int64 v) { $_setInt64(1, v); }
}

class TrafficSnapshot extends $pb.GeneratedMessage {
  factory TrafficSnapshot({
    $fixnum.Int64? bytesIn,
    $fixnum.Int64? bytesOut,
    $core.double? throughputInBps,
    $core.double? throughputOutBps,
    $fixnum.Int64? activeConnections,
    $fixnum.Int64? totalConnections,
    $fixnum.Int64? packetsProcessed,
  }) {
    final $result = create();
    if (bytesIn != null) $result.bytesIn = bytesIn;
    if (bytesOut != null) $result.bytesOut = bytesOut;
    if (throughputInBps != null) $result.throughputInBps = throughputInBps;
    if (throughputOutBps != null) $result.throughputOutBps = throughputOutBps;
    if (activeConnections != null) $result.activeConnections = activeConnections;
    if (totalConnections != null) $result.totalConnections = totalConnections;
    if (packetsProcessed != null) $result.packetsProcessed = packetsProcessed;
    return $result;
  }
  TrafficSnapshot._() : super();
  factory TrafficSnapshot.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TrafficSnapshot.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TrafficSnapshot', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'bytesIn')
    ..aInt64(2, _omitFieldNames ? '' : 'bytesOut')
    ..a<$core.double>(3, _omitFieldNames ? '' : 'throughputInBps', $pb.PbFieldType.OD)
    ..a<$core.double>(4, _omitFieldNames ? '' : 'throughputOutBps', $pb.PbFieldType.OD)
    ..aInt64(5, _omitFieldNames ? '' : 'activeConnections')
    ..aInt64(6, _omitFieldNames ? '' : 'totalConnections')
    ..aInt64(7, _omitFieldNames ? '' : 'packetsProcessed')
    ..hasRequiredFields = false;

  TrafficSnapshot clone() => TrafficSnapshot()..mergeFromMessage(this);
  TrafficSnapshot copyWith(void Function(TrafficSnapshot) updates) => super.copyWith((message) => updates(message as TrafficSnapshot)) as TrafficSnapshot;
  $pb.BuilderInfo get info_ => _i;
  static TrafficSnapshot create() => TrafficSnapshot._();
  TrafficSnapshot createEmptyInstance() => create();
  static $pb.PbList<TrafficSnapshot> createRepeated() => $pb.PbList<TrafficSnapshot>();
  static TrafficSnapshot getDefault() => _defaultInstance ??= create();
  static TrafficSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get bytesIn => $_getI64(0);
  @$pb.TagNumber(1)
  set bytesIn($fixnum.Int64 v) { $_setInt64(0, v); }

  @$pb.TagNumber(2)
  $fixnum.Int64 get bytesOut => $_getI64(1);
  @$pb.TagNumber(2)
  set bytesOut($fixnum.Int64 v) { $_setInt64(1, v); }

  @$pb.TagNumber(3)
  $core.double get throughputInBps => $_getN(2);
  @$pb.TagNumber(3)
  set throughputInBps($core.double v) { $_setDouble(2, v); }

  @$pb.TagNumber(4)
  $core.double get throughputOutBps => $_getN(3);
  @$pb.TagNumber(4)
  set throughputOutBps($core.double v) { $_setDouble(3, v); }

  @$pb.TagNumber(5)
  $fixnum.Int64 get activeConnections => $_getI64(4);
  @$pb.TagNumber(5)
  set activeConnections($fixnum.Int64 v) { $_setInt64(4, v); }

  @$pb.TagNumber(6)
  $fixnum.Int64 get totalConnections => $_getI64(5);
  @$pb.TagNumber(6)
  set totalConnections($fixnum.Int64 v) { $_setInt64(5, v); }

  @$pb.TagNumber(7)
  $fixnum.Int64 get packetsProcessed => $_getI64(6);
  @$pb.TagNumber(7)
  set packetsProcessed($fixnum.Int64 v) { $_setInt64(6, v); }
}

class SetPrivacyConfigRequest extends $pb.GeneratedMessage {
  factory SetPrivacyConfigRequest({
    $core.bool? ttlNormalization,
    $core.bool? packetFragmentation,
    $core.bool? userAgentHarmonization,
    $fixnum.Int64? bandwidthLimitKbps,
  }) {
    final $result = create();
    if (ttlNormalization != null) $result.ttlNormalization = ttlNormalization;
    if (packetFragmentation != null) $result.packetFragmentation = packetFragmentation;
    if (userAgentHarmonization != null) $result.userAgentHarmonization = userAgentHarmonization;
    if (bandwidthLimitKbps != null) $result.bandwidthLimitKbps = bandwidthLimitKbps;
    return $result;
  }
  SetPrivacyConfigRequest._() : super();
  factory SetPrivacyConfigRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetPrivacyConfigRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetPrivacyConfigRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'ttlNormalization')
    ..aOB(2, _omitFieldNames ? '' : 'packetFragmentation')
    ..aOB(3, _omitFieldNames ? '' : 'userAgentHarmonization')
    ..aInt64(4, _omitFieldNames ? '' : 'bandwidthLimitKbps')
    ..hasRequiredFields = false;

  SetPrivacyConfigRequest clone() => SetPrivacyConfigRequest()..mergeFromMessage(this);
  SetPrivacyConfigRequest copyWith(void Function(SetPrivacyConfigRequest) updates) => super.copyWith((message) => updates(message as SetPrivacyConfigRequest)) as SetPrivacyConfigRequest;
  $pb.BuilderInfo get info_ => _i;
  static SetPrivacyConfigRequest create() => SetPrivacyConfigRequest._();
  SetPrivacyConfigRequest createEmptyInstance() => create();
  static $pb.PbList<SetPrivacyConfigRequest> createRepeated() => $pb.PbList<SetPrivacyConfigRequest>();
  static SetPrivacyConfigRequest getDefault() => _defaultInstance ??= create();
  static SetPrivacyConfigRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ttlNormalization => $_getBF(0);
  @$pb.TagNumber(1)
  set ttlNormalization($core.bool v) { $_setBool(0, v); }

  @$pb.TagNumber(2)
  $core.bool get packetFragmentation => $_getBF(1);
  @$pb.TagNumber(2)
  set packetFragmentation($core.bool v) { $_setBool(1, v); }

  @$pb.TagNumber(3)
  $core.bool get userAgentHarmonization => $_getBF(2);
  @$pb.TagNumber(3)
  set userAgentHarmonization($core.bool v) { $_setBool(2, v); }

  @$pb.TagNumber(4)
  $fixnum.Int64 get bandwidthLimitKbps => $_getI64(3);
  @$pb.TagNumber(4)
  set bandwidthLimitKbps($fixnum.Int64 v) { $_setInt64(3, v); }
}

class SetPrivacyConfigResponse extends $pb.GeneratedMessage {
  factory SetPrivacyConfigResponse({$core.bool? success}) {
    final $result = create();
    if (success != null) $result.success = success;
    return $result;
  }
  SetPrivacyConfigResponse._() : super();
  factory SetPrivacyConfigResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetPrivacyConfigResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetPrivacyConfigResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..hasRequiredFields = false;

  SetPrivacyConfigResponse clone() => SetPrivacyConfigResponse()..mergeFromMessage(this);
  SetPrivacyConfigResponse copyWith(void Function(SetPrivacyConfigResponse) updates) => super.copyWith((message) => updates(message as SetPrivacyConfigResponse)) as SetPrivacyConfigResponse;
  $pb.BuilderInfo get info_ => _i;
  static SetPrivacyConfigResponse create() => SetPrivacyConfigResponse._();
  SetPrivacyConfigResponse createEmptyInstance() => create();
  static $pb.PbList<SetPrivacyConfigResponse> createRepeated() => $pb.PbList<SetPrivacyConfigResponse>();
  static SetPrivacyConfigResponse getDefault() => _defaultInstance ??= create();
  static SetPrivacyConfigResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool v) { $_setBool(0, v); }
}


class PeerConnectionStats extends $pb.GeneratedMessage {
  factory PeerConnectionStats({
    $fixnum.Int64? bytesSent,
    $fixnum.Int64? bytesReceived,
    $fixnum.Int64? connectedAtUnixMs,
    $core.double? latencyMs,
  }) {
    final $result = create();
    if (bytesSent != null) $result.bytesSent = bytesSent;
    if (bytesReceived != null) $result.bytesReceived = bytesReceived;
    if (connectedAtUnixMs != null) $result.connectedAtUnixMs = connectedAtUnixMs;
    if (latencyMs != null) $result.latencyMs = latencyMs;
    return $result;
  }
  PeerConnectionStats._() : super();
  factory PeerConnectionStats.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PeerConnectionStats.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PeerConnectionStats', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'bytesSent')
    ..aInt64(2, _omitFieldNames ? '' : 'bytesReceived')
    ..aInt64(3, _omitFieldNames ? '' : 'connectedAtUnixMs')
    ..a<$core.double>(4, _omitFieldNames ? '' : 'latencyMs', $pb.PbFieldType.OD)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. Use [GeneratedMessageGenericExtensions.deepCopy] instead. Will be removed in 3.0.0')
  PeerConnectionStats clone() => PeerConnectionStats()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. Use [GeneratedMessageGenericExtensions.rebuild] instead. Will be removed in 3.0.0')
  PeerConnectionStats copyWith(void Function(PeerConnectionStats) updates) => super.copyWith((message) => updates(message as PeerConnectionStats)) as PeerConnectionStats;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PeerConnectionStats create() => PeerConnectionStats._();
  PeerConnectionStats createEmptyInstance() => create();
  static $pb.PbList<PeerConnectionStats> createRepeated() => $pb.PbList<PeerConnectionStats>();
  @$core.pragma('dart2js:noInline')
  static PeerConnectionStats getDefault() => _defaultInstance ??= create();
  static PeerConnectionStats? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get bytesSent => $_getI64(0);
  @$pb.TagNumber(1)
  set bytesSent($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBytesSent() => $_has(0);
  @$pb.TagNumber(1)
  void clearBytesSent() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get bytesReceived => $_getI64(1);
  @$pb.TagNumber(2)
  set bytesReceived($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBytesReceived() => $_has(1);
  @$pb.TagNumber(2)
  void clearBytesReceived() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get connectedAtUnixMs => $_getI64(2);
  @$pb.TagNumber(3)
  set connectedAtUnixMs($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasConnectedAtUnixMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearConnectedAtUnixMs() => clearField(3);

  @$pb.TagNumber(4)
  $core.double get latencyMs => $_getN(3);
  @$pb.TagNumber(4)
  set latencyMs($core.double v) { $_setDouble(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasLatencyMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearLatencyMs() => clearField(4);
}

class Peer extends $pb.GeneratedMessage {
  factory Peer({
    $core.String? id,
    $core.List<$core.int>? publicKey,
    $core.String? endpoint,
    $fixnum.Int64? lastSeenUnixMs,
    NodeRole? role,
    $core.String? platform,
    PeerConnectionStats? stats,
  }) {
    final $result = create();
    if (id != null) $result.id = id;
    if (publicKey != null) $result.publicKey = publicKey;
    if (endpoint != null) $result.endpoint = endpoint;
    if (lastSeenUnixMs != null) $result.lastSeenUnixMs = lastSeenUnixMs;
    if (role != null) $result.role = role;
    if (platform != null) $result.platform = platform;
    if (stats != null) $result.stats = stats;
    return $result;
  }
  Peer._() : super();
  factory Peer.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Peer.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Peer', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'publicKey', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'endpoint')
    ..aInt64(4, _omitFieldNames ? '' : 'lastSeenUnixMs')
    ..e<NodeRole>(5, _omitFieldNames ? '' : 'role', $pb.PbFieldType.OE, defaultOrMaker: NodeRole.NODE_ROLE_UNSPECIFIED, valueOf: NodeRole.valueOf, enumValues: NodeRole.values)
    ..aOS(6, _omitFieldNames ? '' : 'platform')
    ..aOM<PeerConnectionStats>(7, _omitFieldNames ? '' : 'stats', subBuilder: PeerConnectionStats.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. Use [GeneratedMessageGenericExtensions.deepCopy] instead. Will be removed in 3.0.0')
  Peer clone() => Peer()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. Use [GeneratedMessageGenericExtensions.rebuild] instead. Will be removed in 3.0.0')
  Peer copyWith(void Function(Peer) updates) => super.copyWith((message) => updates(message as Peer)) as Peer;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Peer create() => Peer._();
  Peer createEmptyInstance() => create();
  static $pb.PbList<Peer> createRepeated() => $pb.PbList<Peer>();
  @$core.pragma('dart2js:noInline')
  static Peer getDefault() => _defaultInstance ??= create();
  static Peer? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get publicKey => $_getN(1);
  @$pb.TagNumber(2)
  set publicKey($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPublicKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearPublicKey() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get endpoint => $_getSZ(2);
  @$pb.TagNumber(3)
  set endpoint($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasEndpoint() => $_has(2);
  @$pb.TagNumber(3)
  void clearEndpoint() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get lastSeenUnixMs => $_getI64(3);
  @$pb.TagNumber(4)
  set lastSeenUnixMs($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasLastSeenUnixMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastSeenUnixMs() => clearField(4);

  @$pb.TagNumber(5)
  NodeRole get role => $_getN(4);
  @$pb.TagNumber(5)
  set role(NodeRole v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasRole() => $_has(4);
  @$pb.TagNumber(5)
  void clearRole() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get platform => $_getSZ(5);
  @$pb.TagNumber(6)
  set platform($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasPlatform() => $_has(5);
  @$pb.TagNumber(6)
  void clearPlatform() => clearField(6);

  @$pb.TagNumber(7)
  PeerConnectionStats get stats => $_getN(6);
  @$pb.TagNumber(7)
  set stats(PeerConnectionStats v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasStats() => $_has(6);
  @$pb.TagNumber(7)
  void clearStats() => clearField(7);
  @$pb.TagNumber(7)
  PeerConnectionStats ensureStats() => $_ensure(6);
}

class ListPeersRequest extends $pb.GeneratedMessage {
  factory ListPeersRequest() => create();
  ListPeersRequest._() : super();
  factory ListPeersRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ListPeersRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ListPeersRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. Use [GeneratedMessageGenericExtensions.deepCopy] instead. Will be removed in 3.0.0')
  ListPeersRequest clone() => ListPeersRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. Use [GeneratedMessageGenericExtensions.rebuild] instead. Will be removed in 3.0.0')
  ListPeersRequest copyWith(void Function(ListPeersRequest) updates) => super.copyWith((message) => updates(message as ListPeersRequest)) as ListPeersRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListPeersRequest create() => ListPeersRequest._();
  ListPeersRequest createEmptyInstance() => create();
  static $pb.PbList<ListPeersRequest> createRepeated() => $pb.PbList<ListPeersRequest>();
  @$core.pragma('dart2js:noInline')
  static ListPeersRequest getDefault() => _defaultInstance ??= create();
  static ListPeersRequest? _defaultInstance;
}

class ListPeersResponse extends $pb.GeneratedMessage {
  factory ListPeersResponse({
    $core.Iterable<Peer>? peers,
  }) {
    final $result = create();
    if (peers != null) $result.peers.addAll(peers);
    return $result;
  }
  ListPeersResponse._() : super();
  factory ListPeersResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ListPeersResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ListPeersResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..pc<Peer>(1, _omitFieldNames ? '' : 'peers', $pb.PbFieldType.PM, subBuilder: Peer.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. Use [GeneratedMessageGenericExtensions.deepCopy] instead. Will be removed in 3.0.0')
  ListPeersResponse clone() => ListPeersResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. Use [GeneratedMessageGenericExtensions.rebuild] instead. Will be removed in 3.0.0')
  ListPeersResponse copyWith(void Function(ListPeersResponse) updates) => super.copyWith((message) => updates(message as ListPeersResponse)) as ListPeersResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListPeersResponse create() => ListPeersResponse._();
  ListPeersResponse createEmptyInstance() => create();
  static $pb.PbList<ListPeersResponse> createRepeated() => $pb.PbList<ListPeersResponse>();
  @$core.pragma('dart2js:noInline')
  static ListPeersResponse getDefault() => _defaultInstance ??= create();
  static ListPeersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Peer> get peers => $_getList(0);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');

