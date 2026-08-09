import 'dart:io';
import 'package:flutter/foundation.dart';

/// Manages system proxy settings for Desktop platforms (Windows, macOS, Linux).
class SystemProxyManager {
  static Future<bool> setProxy(String host, int port) async {
    if (!kIsWeb && Platform.isWindows) {
      return _setWindowsProxy(host, port);
    } else if (!kIsWeb && Platform.isMacOS) {
      return _setMacOSProxy(host, port);
    } else if (!kIsWeb && Platform.isLinux) {
      return _setLinuxProxy(host, port);
    }
    return false;
  }

  static Future<bool> clearProxy() async {
    if (!kIsWeb && Platform.isWindows) {
      return _clearWindowsProxy();
    } else if (!kIsWeb && Platform.isMacOS) {
      return _clearMacOSProxy();
    } else if (!kIsWeb && Platform.isLinux) {
      return _clearLinuxProxy();
    }
    return false;
  }

  static Future<bool> _setWindowsProxy(String host, int port) async {
    try {
      // Uses Windows Registry to set proxy
      final result1 = await Process.run('reg', [
        'add',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v', 'ProxyEnable',
        '/t', 'REG_DWORD',
        '/d', '1',
        '/f'
      ]);
      final result2 = await Process.run('reg', [
        'add',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v', 'ProxyServer',
        '/t', 'REG_SZ',
        '/d', '$host:$port',
        '/f'
      ]);
      return result1.exitCode == 0 && result2.exitCode == 0;
    } catch (e) {
      debugPrint('Failed to set Windows proxy: $e');
      return false;
    }
  }

  static Future<bool> _clearWindowsProxy() async {
    try {
      final result = await Process.run('reg', [
        'add',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v', 'ProxyEnable',
        '/t', 'REG_DWORD',
        '/d', '0',
        '/f'
      ]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Failed to clear Windows proxy: $e');
      return false;
    }
  }

  static Future<bool> _setMacOSProxy(String host, int port) async {
    try {
      // Need to find active network interface, defaulting to Wi-Fi
      final result1 = await Process.run('networksetup', ['-setsocksfirewallproxy', 'Wi-Fi', host, port.toString()]);
      final result2 = await Process.run('networksetup', ['-setsocksfirewallproxystate', 'Wi-Fi', 'on']);
      return result1.exitCode == 0 && result2.exitCode == 0;
    } catch (e) {
      debugPrint('Failed to set macOS proxy: $e');
      return false;
    }
  }

  static Future<bool> _clearMacOSProxy() async {
    try {
      final result = await Process.run('networksetup', ['-setsocksfirewallproxystate', 'Wi-Fi', 'off']);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Failed to clear macOS proxy: $e');
      return false;
    }
  }

  static Future<bool> _setLinuxProxy(String host, int port) async {
    try {
      // GNOME gsettings
      await Process.run('gsettings', ['set', 'org.gnome.system.proxy', 'mode', "'manual'"]);
      await Process.run('gsettings', ['set', 'org.gnome.system.proxy.socks', 'host', "'$host'"]);
      await Process.run('gsettings', ['set', 'org.gnome.system.proxy.socks', 'port', port.toString()]);
      return true;
    } catch (e) {
      debugPrint('Failed to set Linux proxy: $e');
      return false;
    }
  }

  static Future<bool> _clearLinuxProxy() async {
    try {
      final result = await Process.run('gsettings', ['set', 'org.gnome.system.proxy', 'mode', "'none'"]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Failed to clear Linux proxy: $e');
      return false;
    }
  }
}
