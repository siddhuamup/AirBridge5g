import 'dart:async';
import 'dart:convert';
import 'package:grpc/grpc.dart';
import 'daemon_client.dart';
import '../providers/role_provider.dart' as app;
import '../utils/crypto_utils.dart';
import '../generated/control.pb.dart' as pb;
import '../generated/control.pbgrpc.dart' as pbgrpc;
import '../generated/control.pbenum.dart' as pbenum;

/// Real gRPC daemon client connecting to the local AirBridge 5G Go daemon.
///
/// Connects to `127.0.0.1:50051` by default with insecure credentials.
/// Includes retry logic with exponential backoff for transient failures.
class GrpcDaemonClient implements AirBridgeDaemonClient {
  late final ClientChannel _channel;
  late final pbgrpc.ControlPlaneClient _client;

  /// Maximum number of retries for transient gRPC failures.
  static const int _maxRetries = 3;

  /// Base delay for exponential backoff (500ms → 1s → 2s).
  static const Duration _baseDelay = Duration(milliseconds: 500);

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
    _client = pbgrpc.ControlPlaneClient(_channel);
  }

  @override
  Future<bool> startTunnel(app.NodeRole role) async {
    return _retryCall('startTunnel', () async {
      final pbRole = _mapRoleToPb(role);
      final response = await _client.startTunnel(
        pb.StartTunnelRequest(role: pbRole),
      );
      return response.state == pbenum.TunnelState.TUNNEL_STATE_RUNNING;
    });
  }

  @override
  Future<bool> stopTunnel() async {
    return _retryCall('stopTunnel', () async {
      final response = await _client.stopTunnel(pb.StopTunnelRequest());
      return response.state == pbenum.TunnelState.TUNNEL_STATE_STOPPED;
    });
  }

  @override
  Future<QRCredentials> generateQRCredentials() async {
    return _retryCall('generateQRCredentials', () async {
      final response =
          await _client.generateQRCredentials(pb.GenerateQRRequest());
      return QRCredentials(
        nodeId: response.nodeId,
        proxyHost: response.proxyHost,
        proxyPort: response.proxyPort,
        quicPort: response.quicPort,
        encryptionKey: response.encryptionKey,
        expiresAt: response.expiresAtUnixMs.toInt(),
        authToken: response.authToken,
      );
    });
  }

  @override
  Future<bool> connectWithQR(String qrPayload) async {
    return _retryCall('connectWithQR', () async {
      final response = await _client.importQRCredentials(
        pb.ImportQRRequest(qrPayload: qrPayload),
      );
      return response.success;
    });
  }

  @override
  Stream<Map<String, dynamic>> streamTrafficStats() {
    final responseStream = _client.streamTrafficStats(
      pb.StreamTrafficStatsRequest(intervalMs: 500),
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
    }).handleError((error) {
      // Convert gRPC errors to user-friendly messages
      if (error is GrpcError) {
        throw Exception(_friendlyGrpcError(error));
      }
      throw error;
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getConnectedPeers() async {
    return _retryCall('getConnectedPeers', () async {
      final response = await _client.getStatus(pb.GetStatusRequest());
      if (response.platform.isNotEmpty && response.platform.startsWith('[')) {
        try {
          final List<dynamic> decoded = jsonDecode(response.platform);
          return decoded.map((e) => e as Map<String, dynamic>).toList();
        } catch (_) {
          return [];
        }
      }
      return [];
    });
  }

  @override
  Future<DaemonStatus> getStatus() async {
    return _retryCall('getStatus', () async {
      final response = await _client.getStatus(pb.GetStatusRequest());
      return DaemonStatus(
        startedAtUnixMs: response.startedAtUnixMs.toInt(),
        tunnelState: response.state.name,
      );
    });
  }

  @override
  Future<bool> setPrivacyConfig({
    bool? dohEnabled,
    bool? killSwitchEnabled,
    bool? ttlEnabled,
    bool? fragmenterEnabled,
    bool? uaHarmonizeEnabled,
  }) async {
    return _retryCall('setPrivacyConfig', () async {
      final req = pb.SetPrivacyConfigRequest();
      if (ttlEnabled != null) req.ttlEnabled = ttlEnabled;
      if (fragmenterEnabled != null) req.fragmenterEnabled = fragmenterEnabled;
      if (uaHarmonizeEnabled != null) req.uaHarmonizeEnabled = uaHarmonizeEnabled;
      final response = await _client.setPrivacyConfig(req);
      return response.success;
    });
  }

  /// Shuts down the gRPC channel.
  Future<void> dispose() async {
    await _channel.shutdown();
  }

  // === Private Helpers ===

  /// Retries a gRPC call up to [_maxRetries] times with exponential backoff.
  Future<T> _retryCall<T>(String methodName, Future<T> Function() call) async {
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        return await call();
      } on GrpcError catch (e) {
        // Don't retry non-transient errors
        if (!_isRetryable(e.code)) {
          throw Exception(_friendlyGrpcError(e));
        }
        // Last attempt — propagate the error
        if (attempt == _maxRetries) {
          throw Exception(_friendlyGrpcError(e));
        }
        // Exponential backoff: 500ms, 1s, 2s
        final delay = _baseDelay * (1 << attempt);
        await Future.delayed(delay);
      }
    }
    // Unreachable, but satisfies the type system
    throw Exception('Unexpected retry exhaustion in $methodName');
  }

  /// Returns true for gRPC status codes that indicate transient failures.
  bool _isRetryable(int? code) {
    return code == StatusCode.unavailable ||
        code == StatusCode.deadlineExceeded ||
        code == StatusCode.aborted ||
        code == StatusCode.resourceExhausted;
  }

  /// Maps gRPC error codes to user-friendly messages.
  String _friendlyGrpcError(GrpcError error) {
    switch (error.code) {
      case StatusCode.unavailable:
        return 'Daemon offline. Start the backend service and try again.';
      case StatusCode.deadlineExceeded:
        return 'Request timed out. The daemon may be under heavy load.';
      case StatusCode.unimplemented:
        return 'This feature is not yet available on the daemon.';
      case StatusCode.permissionDenied:
        return 'Permission denied. Check your authentication credentials.';
      case StatusCode.invalidArgument:
        return 'Invalid request parameters: ${error.message}';
      case StatusCode.internal:
        return 'Daemon internal error: ${error.message}';
      default:
        return 'Connection error (${error.codeName}): ${error.message}';
    }
  }

  /// Maps the app's NodeRole enum to the protobuf NodeRole enum.
  pbenum.NodeRole _mapRoleToPb(app.NodeRole role) {
    switch (role) {
      case app.NodeRole.master:
        return pbenum.NodeRole.NODE_ROLE_MASTER;
      case app.NodeRole.client:
        return pbenum.NodeRole.NODE_ROLE_CLIENT;
      default:
        return pbenum.NodeRole.NODE_ROLE_UNSPECIFIED;
    }
  }
}
