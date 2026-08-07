import 'dart:io' show Platform;
import 'package:flutter/services.dart';

/// Platform channel wrapper for controlling Windows system proxy settings via WinINet API.
class WindowsProxyService {
  static const MethodChannel _channel = MethodChannel('com.airbridge/windows_proxy');
  static const MethodChannel _altChannel = MethodChannel('com.airbridge/proxy');

  /// Configures the Windows system-wide SOCKS5 proxy server.
  /// Example [proxyAddress]: "127.0.0.1:1080"
  static Future<bool> setSystemProxy(String proxyAddress) async {
    if (!Platform.isWindows) return false;
    try {
      final bool success = await _channel.invokeMethod('setProxy', {
        'proxyAddress': proxyAddress,
        'proxy_address': proxyAddress,
      });
      return success;
    } on PlatformException catch (_) {
      try {
        final bool success = await _altChannel.invokeMethod('setProxy', {
          'proxyAddress': proxyAddress,
          'proxy_address': proxyAddress,
        });
        return success;
      } on PlatformException catch (e2) {
        print('[WindowsProxyService] Error enabling system proxy: ${e2.message}');
        return false;
      }
    }
  }

  /// Disables the Windows system-wide proxy server and restores direct connectivity.
  static Future<bool> disableSystemProxy() async {
    if (!Platform.isWindows) return false;
    try {
      final bool success = await _channel.invokeMethod('disableProxy');
      return success;
    } on PlatformException catch (_) {
      try {
        final bool success = await _altChannel.invokeMethod('disableProxy');
        return success;
      } on PlatformException catch (e2) {
        print('[WindowsProxyService] Error disabling system proxy: ${e2.message}');
        return false;
      }
    }
  }

  /// Alias for disableSystemProxy to match requirement naming
  static Future<bool> clearSystemProxy() => disableSystemProxy();

  /// Queries whether the Windows system proxy is currently active.
  static Future<bool> isProxyActive() async {
    if (!Platform.isWindows) return false;
    try {
      final bool active = await _channel.invokeMethod('isProxyActive');
      return active;
    } on PlatformException catch (_) {
      try {
        final bool active = await _altChannel.invokeMethod('isProxyActive');
        return active;
      } on PlatformException catch (e2) {
        print('[WindowsProxyService] Error querying system proxy status: ${e2.message}');
        return false;
      }
    }
  }
}
