import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'windows_proxy.dart';
import 'macos_proxy.dart';
import 'linux_proxy.dart';
import 'android_vpn.dart';
import 'ios_vpn.dart';

/// Unified cross-platform network resilience manager.
/// Automatically selects WinINet proxy on Windows, gsettings on Linux,
/// networksetup on macOS, VpnService on Android, and NetworkExtension on iOS.
class PlatformNetworkManager {
  /// Enables OS-level network tunnel/proxy routing.
  static Future<bool> enableNetworkTunnel({
    required String proxyHost,
    required int proxyPort,
  }) async {
    if (kIsWeb) return false;
    final proxyAddr = '$proxyHost:$proxyPort';
    if (Platform.isWindows) {
      return await WindowsProxyService.setSystemProxy(proxyAddr);
    } else if (Platform.isMacOS) {
      return await MacOSProxyService.setSystemProxy(proxyHost, proxyPort);
    } else if (Platform.isLinux) {
      return await LinuxProxyService.setSystemProxy(proxyHost, proxyPort);
    } else if (Platform.isAndroid) {
      return await MobileVpnService.startVpn(proxyHost, proxyPort);
    } else if (Platform.isIOS) {
      return await IosVpnService.startVpn(proxyHost, proxyPort);
    }
    return false;
  }

  /// Disables OS-level network tunnel/proxy routing and restores default internet access.
  static Future<bool> disableNetworkTunnel() async {
    if (kIsWeb) return false;
    if (Platform.isWindows) {
      return await WindowsProxyService.disableSystemProxy();
    } else if (Platform.isMacOS) {
      return await MacOSProxyService.disableSystemProxy();
    } else if (Platform.isLinux) {
      return await LinuxProxyService.disableSystemProxy();
    } else if (Platform.isAndroid) {
      return await MobileVpnService.stopVpn();
    } else if (Platform.isIOS) {
      return await IosVpnService.stopVpn();
    }
    return false;
  }

  /// Queries whether the OS-level proxy/VPN is currently active.
  static Future<bool> isNetworkTunnelActive() async {
    if (kIsWeb) return false;
    if (Platform.isWindows) {
      return await WindowsProxyService.isProxyActive();
    } else if (Platform.isMacOS) {
      return await MacOSProxyService.isProxyActive();
    } else if (Platform.isLinux) {
      return await LinuxProxyService.isProxyActive();
    } else if (Platform.isAndroid) {
      return await MobileVpnService.isVpnActive();
    } else if (Platform.isIOS) {
      return await IosVpnService.isVpnActive();
    }
    return false;
  }

  static Timer? _autoReconnectTimer;

  /// Continuously monitors network interfaces (e.g. Wi-Fi <-> Mobile Data switch)
  /// and automatically re-establishes active VPN session when dropped.
  static void startAutoReconnectListener({
    required String proxyHost,
    required int proxyPort,
  }) {
    _autoReconnectTimer?.cancel();
    _autoReconnectTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final active = await isNetworkTunnelActive();
      if (!active) {
        await enableNetworkTunnel(proxyHost: proxyHost, proxyPort: proxyPort);
      }
    });
  }
}
