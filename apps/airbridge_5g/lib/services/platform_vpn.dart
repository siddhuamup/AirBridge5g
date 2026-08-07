import 'dart:io' show Platform;
import 'windows_proxy.dart';
import 'android_vpn.dart';
import 'ios_vpn.dart';

/// Unified cross-platform network resilience manager.
/// Automatically selects WinINet proxy on Windows, VpnService on Android, and NetworkExtension on iOS.
class PlatformNetworkManager {
  /// Enables OS-level network tunnel/proxy routing.
  static Future<bool> enableNetworkTunnel({
    required String proxyHost,
    required int proxyPort,
  }) async {
    final proxyAddr = '$proxyHost:$proxyPort';
    if (Platform.isWindows) {
      return await WindowsProxyService.setSystemProxy(proxyAddr);
    } else if (Platform.isAndroid) {
      return await MobileVpnService.startVpn(proxyHost, proxyPort);
    } else if (Platform.isIOS) {
      return await IosVpnService.startVpn(proxyHost, proxyPort);
    }
    // Linux / macOS desktop fallbacks
    return true;
  }

  /// Disables OS-level network tunnel/proxy routing and restores default internet access.
  static Future<bool> disableNetworkTunnel() async {
    if (Platform.isWindows) {
      return await WindowsProxyService.disableSystemProxy();
    } else if (Platform.isAndroid) {
      return await MobileVpnService.stopVpn();
    } else if (Platform.isIOS) {
      return await IosVpnService.stopVpn();
    }
    return true;
  }
}
