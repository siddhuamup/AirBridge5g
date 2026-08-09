import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Provider for the OTA Update Service
final otaUpdateServiceProvider = Provider((ref) => OTAUpdateService());

class OTAUpdateService {
  final String _mockUpdateUrl = "https://api.github.com/repos/example/securemesh/releases/latest";

  Future<UpdateInfo?> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // In a real application, we would use Dio/http to fetch from _mockUpdateUrl.
      // Here we simulate the network request and return a mocked newer version.
      await Future.delayed(const Duration(seconds: 2));

      const latestVersion = "1.1.0"; // Mocked newer version
      const releaseNotes = "• Added STUN/TURN integration\n• Added full i18n support\n• Improved Mesh stability";

      if (_isNewerVersion(currentVersion, latestVersion)) {
        return UpdateInfo(
          version: latestVersion,
          releaseNotes: releaseNotes,
          downloadUrl: "https://example.com/download/airbridge_5g_v1.1.0.apk",
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return null;
    }
  }

  bool _isNewerVersion(String current, String latest) {
    List<int> currentParts = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    List<int> latestParts = latest.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      int c = i < currentParts.length ? currentParts[i] : 0;
      int l = i < latestParts.length ? latestParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
}

class UpdateInfo {
  final String version;
  final String releaseNotes;
  final String downloadUrl;

  UpdateInfo({
    required this.version,
    required this.releaseNotes,
    required this.downloadUrl,
  });
}
