import 'dart:io' show Platform;
import 'package:flutter/services.dart';

/// Platform channel wrapper for controlling Android VpnService and iOS NetworkExtension.
class MobileVpnService {
  static const MethodChannel _channel = MethodChannel('com.airbridge/vpn');

  /// Requests VPN permission and starts the native VPN service tunnel.
  /// Routes traffic through SOCKS5 proxy at [proxyHost]:[proxyPort].
  static Future<bool> startVpn(String proxyHost, int proxyPort) async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      final bool success = await _channel.invokeMethod('startVpn', {
        'proxy_host': proxyHost,
        'proxy_port': proxyPort,
      });
      return success;
    } on PlatformException catch (e) {
      print('[MobileVpnService] Error starting VPN tunnel: ${e.message}');
      return false;
    }
  }

  /// Stops the native VPN service tunnel and restores standard routing.
  static Future<bool> stopVpn() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      final bool success = await _channel.invokeMethod('stopVpn');
      return success;
    } on PlatformException catch (e) {
      print('[MobileVpnService] Error stopping VPN tunnel: ${e.message}');
      return false;
    }
  }

  /// Checks whether the VPN service is currently active.
  static Future<bool> isVpnActive() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      final bool active = await _channel.invokeMethod('isVpnActive');
      return active;
    } on PlatformException catch (e) {
      print('[MobileVpnService] Error querying VPN status: ${e.message}');
      return false;
    }
  }
}
