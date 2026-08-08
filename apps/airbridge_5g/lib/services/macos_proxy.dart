import 'dart:io' show Platform, Process;

/// macOS system proxy configuration using `networksetup` CLI.
/// Sets SOCKS proxy on all active network services (Wi-Fi, Ethernet).
class MacOSProxyService {
  /// Configures the macOS system-wide SOCKS5 proxy server.
  static Future<bool> setSystemProxy(String proxyHost, int proxyPort) async {
    if (!Platform.isMacOS) return false;
    try {
      final services = await _getActiveNetworkServices();
      for (final service in services) {
        // Enable SOCKS proxy
        await Process.run('networksetup', [
          '-setsocksfirewallproxy',
          service,
          proxyHost,
          proxyPort.toString(),
        ]);
        // Turn it on
        await Process.run('networksetup', [
          '-setsocksfirewallproxystate',
          service,
          'on',
        ]);
      }
      return true;
    } catch (e) {
      print('[MacOSProxyService] Error setting system proxy: $e');
      return false;
    }
  }

  /// Disables the macOS system-wide SOCKS5 proxy.
  static Future<bool> disableSystemProxy() async {
    if (!Platform.isMacOS) return false;
    try {
      final services = await _getActiveNetworkServices();
      for (final service in services) {
        await Process.run('networksetup', [
          '-setsocksfirewallproxystate',
          service,
          'off',
        ]);
      }
      return true;
    } catch (e) {
      print('[MacOSProxyService] Error disabling system proxy: $e');
      return false;
    }
  }

  /// Alias for disableSystemProxy.
  static Future<bool> clearSystemProxy() => disableSystemProxy();

  /// Queries whether SOCKS proxy is currently active on Wi-Fi.
  static Future<bool> isProxyActive() async {
    if (!Platform.isMacOS) return false;
    try {
      final result = await Process.run('networksetup', [
        '-getsocksfirewallproxy',
        'Wi-Fi',
      ]);
      final output = result.stdout.toString();
      return output.contains('Enabled: Yes');
    } catch (e) {
      print('[MacOSProxyService] Error querying proxy status: $e');
      return false;
    }
  }

  /// Returns active network service names (e.g. "Wi-Fi", "Ethernet").
  static Future<List<String>> _getActiveNetworkServices() async {
    try {
      final result = await Process.run('networksetup', ['-listallnetworkservices']);
      final lines = result.stdout.toString().split('\n');
      return lines
          .where((l) => l.isNotEmpty && !l.startsWith('*') && !l.contains('denotes'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
    } catch (e) {
      return ['Wi-Fi'];
    }
  }
}
