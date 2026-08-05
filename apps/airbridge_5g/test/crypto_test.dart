import 'package:flutter_test/flutter_test.dart';
import 'package:airbridge_5g/utils/crypto_utils.dart';

void main() {
  group('QRCredentials', () {
    test('Round-trip serialization and deserialization', () {
      final original = QRCredentials(
        nodeId: 'master-node-01',
        proxyHost: '192.168.1.150',
        proxyPort: 1080,
        quicPort: 4433,
        encryptionKey: 'test_key_123',
        expiresAt: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
        authToken: 'auth_token_456',
      );

      final encoded = original.encode();
      expect(encoded.isNotEmpty, isTrue);

      final decoded = QRCredentials.decode(encoded);
      expect(decoded.nodeId, equals('master-node-01'));
      expect(decoded.proxyHost, equals('192.168.1.150'));
      expect(decoded.proxyPort, equals(1080));
      expect(decoded.quicPort, equals(4433));
      expect(decoded.encryptionKey, equals('test_key_123'));
      expect(decoded.authToken, equals('auth_token_456'));
      expect(decoded.isExpired, isFalse);
    });

    test('Expiration check', () {
      final expired = QRCredentials(
        nodeId: 'master-expired',
        proxyHost: '10.0.0.1',
        proxyPort: 1080,
        quicPort: 4433,
        encryptionKey: 'key',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch,
        authToken: 'token',
      );

      expect(expired.isExpired, isTrue);
    });
  });

  group('AirBridgeCrypto', () {
    test('Session token generation', () {
      final token1 = AirBridgeCrypto.generateSessionToken(16);
      final token2 = AirBridgeCrypto.generateSessionToken(16);

      expect(token1.length, equals(32)); // 16 bytes = 32 hex chars
      expect(token2.length, equals(32));
      expect(token1, isNot(equals(token2)));
    });

    test('Endpoint sanitization', () {
      expect(AirBridgeCrypto.sanitizeEndpoint(' 192.168.1.1:8080 '), equals('192.168.1.1:8080'));
      expect(AirBridgeCrypto.sanitizeEndpoint('10.0.0.1'), equals('10.0.0.1:1080'));
      expect(AirBridgeCrypto.sanitizeEndpoint('invalid:port'), equals('invalid:1080'));
    });
  });
}
