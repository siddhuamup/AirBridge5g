import 'dart:io' show Platform;
import 'package:flutter/services.dart';

/// Platform channel wrapper for controlling Windows system proxy settings via WinINet API.
class WindowsProxyService {
  static const MethodChannel _channel = MethodChannel('com.airbridge/windows_proxy');

  /// Configures the Windows system-wide SOCKS5 proxy server.
  /// Example [proxyAddress]: "127.0.0.1:1080"
  static Future<bool> setSystemProxy(String proxyAddress) async {
    if (!Platform.isWindows) return false;
    try {
      final bool success = await _channel.invokeMethod('setProxy', {
        'proxyAddress': proxyAddress,
      });
      return success;
    } on PlatformException catch (e) {
      print('[WindowsProxyService] Error enabling system proxy: ${e.message}');
      return false;
    }
  }

  /// Disables the Windows system-wide proxy server and restores direct connectivity.
  static Future<bool> disableSystemProxy() async {
    if (!Platform.isWindows) return false;
    try {
      final bool success = await _channel.invokeMethod('disableProxy');
      return success;
    } on PlatformException catch (e) {
      print('[WindowsProxyService] Error disabling system proxy: ${e.message}');
      return false;
    }
  }
}
