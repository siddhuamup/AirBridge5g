import 'dart:io' show Platform;
import 'package:flutter/services.dart';

/// Platform channel wrapper for controlling iOS NetworkExtension VPN service.
class IosVpnService {
  static const MethodChannel _channel = MethodChannel('com.airbridge/ios_vpn');

  /// Requests VPN configuration and starts the iOS NEPacketTunnelProvider.
  static Future<bool> startVpn(String proxyHost, int proxyPort) async {
    if (!Platform.isIOS) return false;
    try {
      final bool success = await _channel.invokeMethod('startVpn', {
        'proxy_host': proxyHost,
        'proxy_port': proxyPort,
      });
      return success;
    } on PlatformException catch (e) {
      print('[IosVpnService] Error starting iOS VPN tunnel: ${e.message}');
      return false;
    }
  }

  /// Stops the active iOS VPN tunnel.
  static Future<bool> stopVpn() async {
    if (!Platform.isIOS) return false;
    try {
      final bool success = await _channel.invokeMethod('stopVpn');
      return success;
    } on PlatformException catch (e) {
      print('[IosVpnService] Error stopping iOS VPN tunnel: ${e.message}');
      return false;
    }
  }

  /// Queries whether the iOS VPN service is active.
  static Future<bool> isVpnActive() async {
    if (!Platform.isIOS) return false;
    try {
      final bool active = await _channel.invokeMethod('isVpnActive');
      return active;
    } on PlatformException catch (e) {
      print('[IosVpnService] Error querying iOS VPN status: ${e.message}');
      return false;
    }
  }
}
