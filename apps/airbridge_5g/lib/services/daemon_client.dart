import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/role_provider.dart';
import '../utils/crypto_utils.dart';
export 'grpc_daemon_client.dart';

class DaemonStatus {
  final int startedAtUnixMs;
  final String tunnelState;

  const DaemonStatus({
    this.startedAtUnixMs = 0,
    this.tunnelState = 'TUNNEL_STATE_STOPPED',
  });
}

class TrafficSnapshotData {
  final int bytesIn;
  final int bytesOut;
  final double activeConnections;

  const TrafficSnapshotData({
    this.bytesIn = 0,
    this.bytesOut = 0,
    this.activeConnections = 0,
  });
}

/// Client interface for communicating with the AirBridge 5G Go Daemon.
abstract class AirBridgeDaemonClient {
  Future<bool> startTunnel(NodeRole role);
  Future<bool> stopTunnel();
  Future<QRCredentials> generateQRCredentials();
  Future<bool> connectWithQR(String qrPayload);
  Stream<Map<String, dynamic>> streamTrafficStats();
  Future<TrafficSnapshotData> getTrafficSnapshot();
  Future<List<Map<String, dynamic>>> getConnectedPeers();
  Future<DaemonStatus> getStatus();
  Future<bool> setPrivacyConfig({
    bool? dohEnabled,
    bool? killSwitchEnabled,
    bool? ttlEnabled,
    bool? fragmenterEnabled,
    bool? uaHarmonizeEnabled,
  });
}

/// Simulated Daemon Client for local UI development and testing.
class LocalDaemonClient implements AirBridgeDaemonClient {
  bool _isRunning = false;
  NodeRole _currentRole = NodeRole.unspecified;

  @override
  Future<bool> startTunnel(NodeRole role) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _isRunning = true;
    _currentRole = role;
    return true;
  }

  @override
  Future<bool> stopTunnel() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _isRunning = false;
    _currentRole = NodeRole.unspecified;
    return true;
  }

  @override
  Future<QRCredentials> generateQRCredentials() async {
    return QRCredentials(
      nodeId: 'airbridge-master-local',
      proxyHost: '192.168.1.100',
      proxyPort: 1080,
      quicPort: 4433,
      encryptionKey: AirBridgeCrypto.generateSessionToken(32),
      expiresAt: DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch,
      authToken: AirBridgeCrypto.generateSessionToken(16),
    );
  }

  @override
  Future<bool> connectWithQR(String qrPayload) async {
    final creds = QRCredentials.decode(qrPayload);
    if (creds.isExpired) {
      throw Exception('QR credentials have expired');
    }
    await Future.delayed(const Duration(milliseconds: 500));
    _isRunning = true;
    _currentRole = NodeRole.client;
    return true;
  }

  @override
  Future<TrafficSnapshotData> getTrafficSnapshot() async {
    return TrafficSnapshotData(
      bytesIn: _isRunning ? 1024 * 1024 * 15 : 0,
      bytesOut: _isRunning ? 1024 * 1024 * 5 : 0,
      activeConnections: _isRunning ? 3.0 : 0.0,
    );
  }

  @override
  Stream<Map<String, dynamic>> streamTrafficStats() {
    return Stream.periodic(const Duration(milliseconds: 500), (count) {
      return {
        'bytes_in': count * 1024 * 50,
        'bytes_out': count * 1024 * 20,
        'active_connections': _isRunning ? 3 : 0,
        'packets_processed': count * 120,
      };
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getConnectedPeers() async {
    if (!_isRunning) return [];
    return [
      {'id': 'peer-1', 'endpoint': '192.168.1.101', 'platform': 'android', 'latency_ms': 12.5},
      {'id': 'peer-2', 'endpoint': '192.168.1.102', 'platform': 'ios', 'latency_ms': 18.2},
    ];
  }

  @override
  Future<DaemonStatus> getStatus() async {
    return DaemonStatus(
      startedAtUnixMs: _isRunning
          ? DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch
          : 0,
      tunnelState: _isRunning ? 'TUNNEL_STATE_RUNNING' : 'TUNNEL_STATE_STOPPED',
    );
  }

  @override
  Future<bool> setPrivacyConfig({
    bool? dohEnabled,
    bool? killSwitchEnabled,
    bool? ttlEnabled,
    bool? fragmenterEnabled,
    bool? uaHarmonizeEnabled,
  }) async {
    return true;
  }
}




