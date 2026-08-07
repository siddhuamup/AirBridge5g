import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/crypto_utils.dart';

/// Service for storing pairing credentials securely in OS Keychain/Keystore.
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _keyCreds = 'airbridge_active_creds';
  static const String _keyToken = 'airbridge_session_token';

  /// Securely saves active QR credentials.
  static Future<void> saveCredentials(QRCredentials creds) async {
    await _storage.write(key: _keyCreds, value: creds.encode());
  }

  /// Retrieves active QR credentials if present and valid.
  static Future<QRCredentials?> getCredentials() async {
    final raw = await _storage.read(key: _keyCreds);
    if (raw == null || raw.isEmpty) return null;
    try {
      final creds = QRCredentials.decode(raw);
      if (creds.isExpired) {
        await clearCredentials();
        return null;
      }
      return creds;
    } catch (_) {
      return null;
    }
  }

  /// Securely saves the session authentication token.
  static Future<void> saveSessionToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  /// Retrieves the session authentication token.
  static Future<String?> getSessionToken() async {
    return await _storage.read(key: _keyToken);
  }

  /// Clears stored pairing credentials.
  static Future<void> clearCredentials() async {
    await _storage.delete(key: _keyCreds);
    await _storage.delete(key: _keyToken);
  }
}
