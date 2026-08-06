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
  static GetStatusRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$defaultFor<GetStatusRequest>(create);
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
  static GetStatusResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$defaultFor<GetStatusResponse>(create);
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
  static StartTunnelRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$defaultFor<StartTunnelRequest>(create);
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
  static StartTunnelResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$defaultFor<StartTunnelResponse>(create);
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StopTunnelRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create);
  static StopTunnelRequest create() => StopTunnelRequest._();
  GetStatusRequest createEmptyInstance() => create();
}

class StopTunnelResponse extends $pb.GeneratedMessage {
  factory StopTunnelResponse({TunnelState? state}) {
    final $result = create();
    if (state != null) $result.state = state;
    return $result;
  }
  StopTunnelResponse._() : super();
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StopTunnelResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..e<TunnelState>(1, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE, defaultOrMaker: TunnelState.TUNNEL_STATE_UNSPECIFIED, valueOf: TunnelState.valueOf, enumValues: TunnelState.values);
  static StopTunnelResponse create() => StopTunnelResponse._();
  TunnelState get state => $_getN(0);
  set state(TunnelState v) { setField(1, v); }
}

class GenerateQRRequest extends $pb.GeneratedMessage {
  factory GenerateQRRequest() => create();
  GenerateQRRequest._() : super();
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GenerateQRRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create);
  static GenerateQRRequest create() => GenerateQRRequest._();
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GenerateQRResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'qrPayload')
    ..aOS(2, _omitFieldNames ? '' : 'proxyHost')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'proxyPort', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'quicPort', $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(5, _omitFieldNames ? '' : 'encryptionKey', $pb.PbFieldType.OY)
    ..aInt64(6, _omitFieldNames ? '' : 'expiresAtUnixMs');

  static GenerateQRResponse create() => GenerateQRResponse._();

  $core.String get qrPayload => $_getSZ(0);
  set qrPayload($core.String v) { $_setString(0, v); }

  $core.String get proxyHost => $_getSZ(1);
  set proxyHost($core.String v) { $_setString(1, v); }

  $core.int get proxyPort => $_getIZ(2);
  set proxyPort($core.int v) { $_setUnsignedInt32(2, v); }

  $core.int get quicPort => $_getIZ(3);
  set quicPort($core.int v) { $_setUnsignedInt32(3, v); }

  $core.List<$core.int> get encryptionKey => $_getN(4);
  set encryptionKey($core.List<$core.int> v) { setField(5, v); }

  $fixnum.Int64 get expiresAtUnixMs => $_getI64(5);
  set expiresAtUnixMs($fixnum.Int64 v) { $_setInt64(5, v); }
}

class ImportQRRequest extends $pb.GeneratedMessage {
  factory ImportQRRequest({$core.String? qrPayload}) {
    final $result = create();
    if (qrPayload != null) $result.qrPayload = qrPayload;
    return $result;
  }
  ImportQRRequest._() : super();
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ImportQRRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'qrPayload');
  static ImportQRRequest create() => ImportQRRequest._();
  $core.String get qrPayload => $_getSZ(0);
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ImportQRResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'peerId')
    ..aOS(3, _omitFieldNames ? '' : 'proxyAddress')
    ..aOS(4, _omitFieldNames ? '' : 'errorMessage');

  static ImportQRResponse create() => ImportQRResponse._();

  $core.bool get success => $_getBF(0);
  set success($core.bool v) { $_setBool(0, v); }

  $core.String get peerId => $_getSZ(1);
  set peerId($core.String v) { $_setString(1, v); }

  $core.String get proxyAddress => $_getSZ(2);
  set proxyAddress($core.String v) { $_setString(2, v); }

  $core.String get errorMessage => $_getSZ(3);
  set errorMessage($core.String v) { $_setString(3, v); }
}

class StreamTrafficStatsRequest extends $pb.GeneratedMessage {
  factory StreamTrafficStatsRequest({$core.int? intervalMs}) {
    final $result = create();
    if (intervalMs != null) $result.intervalMs = intervalMs;
    return $result;
  }
  StreamTrafficStatsRequest._() : super();
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StreamTrafficStatsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'intervalMs', $pb.PbFieldType.OU3);
  static StreamTrafficStatsRequest create() => StreamTrafficStatsRequest._();
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TrafficStatsUpdate', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..aOM<TrafficSnapshot>(1, _omitFieldNames ? '' : 'snapshot', subBuilder: TrafficSnapshot.create)
    ..aInt64(2, _omitFieldNames ? '' : 'timestampUnixMs');
  static TrafficStatsUpdate create() => TrafficStatsUpdate._();
  TrafficSnapshot get snapshot => $_getN(0);
  set snapshot(TrafficSnapshot v) { setField(1, v); }
  $fixnum.Int64 get timestampUnixMs => $_getI64(1);
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TrafficSnapshot', package: const $pb.PackageName(_omitMessageNames ? '' : 'airbridge.control.v1'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'bytesIn')
    ..aInt64(2, _omitFieldNames ? '' : 'bytesOut')
    ..a<$core.double>(3, _omitFieldNames ? '' : 'throughputInBps', $pb.PbFieldType.OD)
    ..a<$core.double>(4, _omitFieldNames ? '' : 'throughputOutBps', $pb.PbFieldType.OD)
    ..aInt64(5, _omitFieldNames ? '' : 'activeConnections')
    ..aInt64(6, _omitFieldNames ? '' : 'totalConnections')
    ..aInt64(7, _omitFieldNames ? '' : 'packetsProcessed');

  static TrafficSnapshot create() => TrafficSnapshot._();

  $fixnum.Int64 get bytesIn => $_getI64(0);
  set bytesIn($fixnum.Int64 v) { $_setInt64(0, v); }

  $fixnum.Int64 get bytesOut => $_getI64(1);
  set bytesOut($fixnum.Int64 v) { $_setInt64(1, v); }

  $core.double get throughputInBps => $_getN(2);
  set throughputInBps($core.double v) { $_setDouble(2, v); }

  $core.double get throughputOutBps => $_getN(3);
  set throughputOutBps($core.double v) { $_setDouble(3, v); }

  $fixnum.Int64 get activeConnections => $_getI64(4);
  set activeConnections($fixnum.Int64 v) { $_setInt64(4, v); }

  $fixnum.Int64 get totalConnections => $_getI64(5);
  set totalConnections($fixnum.Int64 v) { $_setInt64(5, v); }

  $fixnum.Int64 get packetsProcessed => $_getI64(6);
  set packetsProcessed($fixnum.Int64 v) { $_setInt64(6, v); }
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
