import 'package:flutter_test/flutter_test.dart';
import 'package:airbridge_5g/utils/crypto_utils.dart';

void main() {
  group('QRCredentials', () {
    test('encode and decode produces identical object', () {
      final creds = QRCredentials(
        nodeId: 'test_node_id',
        proxyHost: '192.168.1.100',
        proxyPort: 1080,
        quicPort: 4433,
        encryptionKey: 'secret_key',
        expiresAt: DateTime.now().millisecondsSinceEpoch + 86400000,
        authToken: 'auth_token',
      );

      final encoded = creds.encode();
      expect(encoded.isNotEmpty, true);

      final decoded = QRCredentials.decode(encoded);
      expect(decoded.nodeId, creds.nodeId);
      expect(decoded.proxyHost, creds.proxyHost);
      expect(decoded.proxyPort, creds.proxyPort);
      expect(decoded.quicPort, creds.quicPort);
      expect(decoded.encryptionKey, creds.encryptionKey);
      expect(decoded.expiresAt, creds.expiresAt);
      expect(decoded.authToken, creds.authToken);
    });

    test('isExpired returns correctly', () {
      final expiredCreds = QRCredentials(
        nodeId: 'test_node_id',
        proxyHost: '192.168.1.100',
        proxyPort: 1080,
        quicPort: 4433,
        encryptionKey: 'secret_key',
        expiresAt: DateTime.now().millisecondsSinceEpoch - 1000,
        authToken: 'auth_token',
      );
      expect(expiredCreds.isExpired, true);

      final validCreds = QRCredentials(
        nodeId: 'test_node_id',
        proxyHost: '192.168.1.100',
        proxyPort: 1080,
        quicPort: 4433,
        encryptionKey: 'secret_key',
        expiresAt: DateTime.now().millisecondsSinceEpoch + 10000,
        authToken: 'auth_token',
      );
      expect(validCreds.isExpired, false);
    });
  });

  group('AirBridgeCrypto', () {
    test('generateSessionToken generates token of correct length', () {
      final token1 = AirBridgeCrypto.generateSessionToken(16);
      expect(token1.length, 32); // Hex string length is double the byte length

      final token2 = AirBridgeCrypto.generateSessionToken(32);
      expect(token2.length, 64);
    });

    test('sanitizeEndpoint handles valid and invalid inputs', () {
      expect(AirBridgeCrypto.sanitizeEndpoint('192.168.1.1:8080'), '192.168.1.1:8080');
      expect(AirBridgeCrypto.sanitizeEndpoint('10.0.0.1'), '10.0.0.1:1080');
      expect(AirBridgeCrypto.sanitizeEndpoint('   [::1]:9090  '), '[::1]:9090');
    });
  });
}
