import 'dart:async';
import 'package:grpc/grpc.dart';
import 'daemon_client.dart';
import '../providers/role_provider.dart';
import '../utils/crypto_utils.dart';
import '../generated/control.pbgrpc.dart';
import '../generated/control.pbenum.dart';


/// Real gRPC daemon client connecting to the local AirBridge 5G Go daemon at 127.0.0.1:50051.
class GrpcDaemonClient implements AirBridgeDaemonClient {
  late final ClientChannel _channel;
  late final ControlPlaneClient _client;

  GrpcDaemonClient({
    String host = '127.0.0.1',
    int port = 50051,
  }) {
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
        idleTimeout: Duration(minutes: 5),
      ),
    );
    _client = ControlPlaneClient(_channel);
  }

  @override
  Future<bool> startTunnel(NodeRole role) async {
    final pbRole = _mapRoleToPb(role);
    final response = await _client.startTunnel(
      StartTunnelRequest(role: pbRole),
    );
    return response.state == TunnelState.TUNNEL_STATE_RUNNING;
  }

  @override
  Future<bool> stopTunnel() async {
    final response = await _client.stopTunnel(StopTunnelRequest());
    return response.state == TunnelState.TUNNEL_STATE_STOPPED;
  }

  @override
  Future<QRCredentials> generateQRCredentials() async {
    final response = await _client.generateQRCredentials(GenerateQRRequest());
    return QRCredentials(
      nodeId: response.proxyHost.isEmpty ? 'airbridge-master' : 'master-node',
      proxyHost: response.proxyHost,
      proxyPort: response.proxyPort,
      quicPort: response.quicPort,
      encryptionKey: String.fromCharCodes(response.encryptionKey),
      expiresAt: response.expiresAtUnixMs.toInt(),
      authToken: response.qrPayload,
    );
  }

  @override
  Future<bool> connectWithQR(String qrPayload) async {
    final response = await _client.importQRCredentials(
      ImportQRRequest(qrPayload: qrPayload),
    );
    return response.success;
  }

  @override
  Stream<Map<String, dynamic>> streamTrafficStats() {
    final responseStream = _client.streamTrafficStats(
      StreamTrafficStatsRequest(intervalMs: 500),
    );

    return responseStream.map((update) {
      final snap = update.snapshot;
      return {
        'bytes_in': snap.bytesIn.toInt(),
        'bytes_out': snap.bytesOut.toInt(),
        'throughput_in_bps': snap.throughputInBps,
        'throughput_out_bps': snap.throughputOutBps,
        'active_connections': snap.activeConnections.toInt(),
        'total_connections': snap.totalConnections.toInt(),
        'packets_processed': snap.packetsProcessed.toInt(),
        'timestamp': update.timestampUnixMs.toInt(),
      };
    });
  }

  Future<void> dispose() async {
    await _channel.shutdown();
  }

  NodeRole _mapRoleToPb(NodeRole role) {
    switch (role) {
      case NodeRole.master:
        return NodeRole.NODE_ROLE_MASTER;
      case NodeRole.client:
        return NodeRole.NODE_ROLE_CLIENT;
      default:
        return NodeRole.NODE_ROLE_UNSPECIFIED;
    }
  }
}
