//
//  Generated code. Do not modify.
//  source: proto/control/v1/control.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'control.pb.dart' as $0;

export 'control.pb.dart';

@$pb.GrpcServiceName('airbridge.control.v1.ControlPlane')
class ControlPlaneClient extends $grpc.Client {
  static final _$getStatus = $grpc.ClientMethod<$0.GetStatusRequest, $0.GetStatusResponse>(
      '/airbridge.control.v1.ControlPlane/GetStatus',
      ($0.GetStatusRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.GetStatusResponse.fromBuffer(value));
  static final _$startTunnel = $grpc.ClientMethod<$0.StartTunnelRequest, $0.StartTunnelResponse>(
      '/airbridge.control.v1.ControlPlane/StartTunnel',
      ($0.StartTunnelRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.StartTunnelResponse.fromBuffer(value));
  static final _$stopTunnel = $grpc.ClientMethod<$0.StopTunnelRequest, $0.StopTunnelResponse>(
      '/airbridge.control.v1.ControlPlane/StopTunnel',
      ($0.StopTunnelRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.StopTunnelResponse.fromBuffer(value));
  static final _$generateQRCredentials = $grpc.ClientMethod<$0.GenerateQRRequest, $0.GenerateQRResponse>(
      '/airbridge.control.v1.ControlPlane/GenerateQRCredentials',
      ($0.GenerateQRRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.GenerateQRResponse.fromBuffer(value));
  static final _$importQRCredentials = $grpc.ClientMethod<$0.ImportQRRequest, $0.ImportQRResponse>(
      '/airbridge.control.v1.ControlPlane/ImportQRCredentials',
      ($0.ImportQRRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ImportQRResponse.fromBuffer(value));
  static final _$streamTrafficStats = $grpc.ClientMethod<$0.StreamTrafficStatsRequest, $0.TrafficStatsUpdate>(
      '/airbridge.control.v1.ControlPlane/StreamTrafficStats',
      ($0.StreamTrafficStatsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.TrafficStatsUpdate.fromBuffer(value));
  static final _$listPeers = $grpc.ClientMethod<$0.ListPeersRequest, $0.ListPeersResponse>(
      '/airbridge.control.v1.ControlPlane/ListPeers',
      ($0.ListPeersRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ListPeersResponse.fromBuffer(value));
  static final _$setPrivacyConfig = $grpc.ClientMethod<$0.SetPrivacyConfigRequest, $0.SetPrivacyConfigResponse>(
      '/airbridge.control.v1.ControlPlane/SetPrivacyConfig',
      ($0.SetPrivacyConfigRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.SetPrivacyConfigResponse.fromBuffer(value));

  ControlPlaneClient($grpc.ClientChannel channel, {$grpc.CallOptions? options, $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.GetStatusResponse> getStatus($0.GetStatusRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getStatus, request, options: options);
  }

  $grpc.ResponseFuture<$0.StartTunnelResponse> startTunnel($0.StartTunnelRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$startTunnel, request, options: options);
  }

  $grpc.ResponseFuture<$0.StopTunnelResponse> stopTunnel($0.StopTunnelRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$stopTunnel, request, options: options);
  }

  $grpc.ResponseFuture<$0.GenerateQRResponse> generateQRCredentials($0.GenerateQRRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$generateQRCredentials, request, options: options);
  }

  $grpc.ResponseFuture<$0.ImportQRResponse> importQRCredentials($0.ImportQRRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$importQRCredentials, request, options: options);
  }

  $grpc.ResponseStream<$0.TrafficStatsUpdate> streamTrafficStats($0.StreamTrafficStatsRequest request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$streamTrafficStats, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseFuture<$0.ListPeersResponse> listPeers($0.ListPeersRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$listPeers, request, options: options);
  }

  $grpc.ResponseFuture<$0.SetPrivacyConfigResponse> setPrivacyConfig($0.SetPrivacyConfigRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$setPrivacyConfig, request, options: options);
  }
}
