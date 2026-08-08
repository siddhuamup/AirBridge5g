
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
  static PeerConnectionStats getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$defaultFor<PeerConnectionStats>(create);
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
  static Peer getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$defaultFor<Peer>(create);
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
  static ListPeersRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$defaultFor<ListPeersRequest>(create);
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
  static ListPeersResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$defaultFor<ListPeersResponse>(create);
  static ListPeersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Peer> get peers => $_getList(0);
}
