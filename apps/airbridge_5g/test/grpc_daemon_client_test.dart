import 'package:flutter_test/flutter_test.dart';
import 'package:airbridge_5g/services/daemon_client.dart';
import 'package:airbridge_5g/providers/role_provider.dart';

void main() {
  group('LocalDaemonClient Tests', () {
    late LocalDaemonClient client;

    setUp(() {
      client = LocalDaemonClient();
    });

    test('startTunnel sets master role and returns true', () async {
      final success = await client.startTunnel(NodeRole.master);
      expect(success, isTrue);
    });

    test('stopTunnel returns true', () async {
      final success = await client.stopTunnel();
      expect(success, isTrue);
    });

    test('generateQRCredentials returns valid non-expired credentials', () async {
      final creds = await client.generateQRCredentials();
      expect(creds.proxyHost, equals('192.168.1.100'));
      expect(creds.proxyPort, equals(1080));
      expect(creds.isExpired, isFalse);
    });

    test('connectWithQR validates QR payload and succeeds', () async {
      final creds = await client.generateQRCredentials();
      final payload = creds.encode();
      final success = await client.connectWithQR(payload);
      expect(success, isTrue);
    });

    test('streamTrafficStats emits periodic snapshot updates', () async {
      await client.startTunnel(NodeRole.master);
      final stream = client.streamTrafficStats();

      final firstUpdate = await stream.first;
      expect(firstUpdate, contains('bytes_in'));
      expect(firstUpdate, contains('active_connections'));
      expect(firstUpdate['active_connections'], equals(3));
    });
  });
}
