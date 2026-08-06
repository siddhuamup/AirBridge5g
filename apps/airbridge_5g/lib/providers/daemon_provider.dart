import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/daemon_client.dart';
import '../services/grpc_daemon_client.dart';

/// Flag to toggle between real gRPC connection and local mock client.
const bool useGrpcClient = true;

/// Provider that supplies the active AirBridgeDaemonClient instance.
final daemonProvider = Provider<AirBridgeDaemonClient>((ref) {
  if (useGrpcClient) {
    final client = GrpcDaemonClient();
    ref.onDispose(() {
      client.dispose();
    });
    return client;
  }
  return LocalDaemonClient();
});
