//
//  Generated code. Do not modify.
//  source: proto/control/v1/control.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use nodeRoleDescriptor instead')
const NodeRole$json = {
  '1': 'NodeRole',
  '2': [
    {'1': 'NODE_ROLE_UNSPECIFIED', '2': 0},
    {'1': 'NODE_ROLE_MASTER', '2': 1},
    {'1': 'NODE_ROLE_CLIENT', '2': 2},
  ],
};

/// Descriptor for `NodeRole`. Decode as `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List nodeRoleDescriptor = $convert.base64Decode(
    'CghOb2RlUm9sZRIZChVOT0RFX1JPTEVfVU5TUEVDSUZJRUQQABIUChBOT0RFX1JPTEVfTUFTVE'
    'VSEAESFAoQTk9ERV9ST0xFX0NMSUVOVBAC');

@$core.Deprecated('Use tunnelStateDescriptor instead')
const TunnelState$json = {
  '1': 'TunnelState',
  '2': [
    {'1': 'TUNNEL_STATE_UNSPECIFIED', '2': 0},
    {'1': 'TUNNEL_STATE_STOPPED', '2': 1},
    {'1': 'TUNNEL_STATE_STARTING', '2': 2},
    {'1': 'TUNNEL_STATE_RUNNING', '2': 3},
    {'1': 'TUNNEL_STATE_DEGRADED', '2': 4},
  ],
};

/// Descriptor for `TunnelState`. Decode as `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List tunnelStateDescriptor = $convert.base64Decode(
    'CgtUdW5uZWxTdGF0ZRIcChhUVU5ORUxfU1RBVEVfVU5TUEVDSUZJRURBABIYChRUVU5ORUxfU1'
    'RBVEVfU1RPUFBFRBABEhkKVVRVTk5FTF9TVEFURV9TVEFSVElORxACEhgKFFRVTk5FTF9TVEFU'
    'RV9SVU5OSU5HEAMSGQoVVFVOTkVMX1NUQVRFX0RFR1JBREVEEAQ=');
