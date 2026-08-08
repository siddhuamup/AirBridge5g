import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// OTA Update Manager — checks for new versions and prompts the user to update.
class OtaUpdateManager {
  static const String _updateUrl = 'https://api.github.com/repos/siddhuamup/AirBridge5g/releases/latest';
  static const String _fallbackUrl = 'https://github.com/siddhuamup/AirBridge5g/releases';

  /// Checks if a new version is available.
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final dio = Dio();
      final response = await dio.get(
        _updateUrl,
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3+json'},
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final latestVersion = (data['tag_name'] as String).replaceAll('v', '');
        final releaseNotes = data['body'] as String? ?? 'Bug fixes and improvements.';
        final downloadUrl = _getDownloadUrl(data['assets'] as List? ?? []);

        if (_isNewerVersion(currentVersion, latestVersion)) {
          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            releaseNotes: releaseNotes,
            downloadUrl: downloadUrl.isNotEmpty ? downloadUrl : _fallbackUrl,
          );
        }
      }
    } catch (e) {
      debugPrint('[OTA] Update check failed: $e');
    }
    return null;
  }

  /// Compares semantic versions (e.g., "1.0.0" vs "1.1.0").
  static bool _isNewerVersion(String current, String latest) {
    try {
      final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final l = i < latestParts.length ? latestParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (_) {}
    return false;
  }

  /// Finds the appropriate asset download URL for the current platform.
  static String _getDownloadUrl(List assets) {
    final platformKey = Platform.isWindows
        ? 'windows'
        : Platform.isMacOS
            ? 'macos'
            : Platform.isLinux
                ? 'linux'
                : Platform.isAndroid
                    ? 'apk'
                    : 'ipa';

    for (final asset in assets) {
      if (asset is Map) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.contains(platformKey)) {
          return asset['browser_download_url'] as String? ?? '';
        }
      }
    }
    return '';
  }

  /// Opens the target URL in system default browser.
  static Future<void> _launchDownloadUrl(String url) async {
    final targetUrl = url.isNotEmpty ? url : _fallbackUrl;
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', targetUrl]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [targetUrl]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [targetUrl]);
      } else {
        debugPrint('[OTA] Opening download URL: $targetUrl');
      }
    } catch (e) {
      debugPrint('[OTA] Error launching download URL: $e');
    }
  }

  /// Shows an update dialog to the user.
  static void showUpdateDialog(BuildContext context, UpdateInfo info) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current: v${info.currentVersion}'),
            Text('Latest: v${info.latestVersion}'),
            const SizedBox(height: 12),
            const Text('Release Notes:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(info.releaseNotes, style: const TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _launchDownloadUrl(info.downloadUrl);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}

/// Holds information about an available update.
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
  });
}
