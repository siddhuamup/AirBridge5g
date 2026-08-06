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

import 'package:protobuf/protobuf.dart' as $pb;

class NodeRole extends $pb.ProtobufEnum {
  static const NodeRole NODE_ROLE_UNSPECIFIED = NodeRole._(0, _omitEnumNames ? '' : 'NODE_ROLE_UNSPECIFIED');
  static const NodeRole NODE_ROLE_MASTER = NodeRole._(1, _omitEnumNames ? '' : 'NODE_ROLE_MASTER');
  static const NodeRole NODE_ROLE_CLIENT = NodeRole._(2, _omitEnumNames ? '' : 'NODE_ROLE_CLIENT');

  static const $core.List<NodeRole> values = <NodeRole> [
    NODE_ROLE_UNSPECIFIED,
    NODE_ROLE_MASTER,
    NODE_ROLE_CLIENT,
  ];

  static final $core.Map<$core.int, NodeRole> _byValue = $pb.ProtobufEnum.initByValue(values);
  static NodeRole? valueOf($core.int value) => _byValue[value];

  const NodeRole._($core.int v, $core.String n) : super(v, n);
}

class TunnelState extends $pb.ProtobufEnum {
  static const TunnelState TUNNEL_STATE_UNSPECIFIED = TunnelState._(0, _omitEnumNames ? '' : 'TUNNEL_STATE_UNSPECIFIED');
  static const TunnelState TUNNEL_STATE_STOPPED = TunnelState._(1, _omitEnumNames ? '' : 'TUNNEL_STATE_STOPPED');
  static const TunnelState TUNNEL_STATE_STARTING = TunnelState._(2, _omitEnumNames ? '' : 'TUNNEL_STATE_STARTING');
  static const TunnelState TUNNEL_STATE_RUNNING = TunnelState._(3, _omitEnumNames ? '' : 'TUNNEL_STATE_RUNNING');
  static const TunnelState TUNNEL_STATE_DEGRADED = TunnelState._(4, _omitEnumNames ? '' : 'TUNNEL_STATE_DEGRADED');

  static const $core.List<TunnelState> values = <TunnelState> [
    TUNNEL_STATE_UNSPECIFIED,
    TUNNEL_STATE_STOPPED,
    TUNNEL_STATE_STARTING,
    TUNNEL_STATE_RUNNING,
    TUNNEL_STATE_DEGRADED,
  ];

  static final $core.Map<$core.int, TunnelState> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TunnelState? valueOf($core.int value) => _byValue[value];

  const TunnelState._($core.int v, $core.String n) : super(v, n);
}

const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
