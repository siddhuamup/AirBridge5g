import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys used for SharedPreferences persistence.
class SettingsKeys {
  static const dohEnabled = 'settings_doh_enabled';
  static const killSwitchEnabled = 'settings_kill_switch_enabled';
  static const ttlEnabled = 'settings_ttl_enabled';
  static const dpiEnabled = 'settings_dpi_enabled';
  static const uaEnabled = 'settings_ua_enabled';
  static const darkMode = 'settings_dark_mode';
  static const locale = 'settings_locale';
  static const bandwidthLimitKbps = 'settings_bandwidth_limit_kbps';
  static const lastRole = 'settings_last_role';
  static const proxyHost = 'settings_proxy_host';
  static const proxyPort = 'settings_proxy_port';
  static const autoQrRotation = 'settings_auto_qr_rotation';
}

/// Persisted application settings model.
class AppSettings {
  final bool dohEnabled;
  final bool killSwitchEnabled;
  final bool ttlEnabled;
  final bool dpiEnabled;
  final bool uaEnabled;
  final bool darkMode;
  final String locale;
  final int bandwidthLimitKbps;
  final String lastRole;
  final String proxyHost;
  final int proxyPort;
  final bool autoQrRotation;

  const AppSettings({
    this.dohEnabled = true,
    this.killSwitchEnabled = true,
    this.ttlEnabled = true,
    this.dpiEnabled = true,
    this.uaEnabled = true,
    this.darkMode = true,
    this.locale = 'en',
    this.bandwidthLimitKbps = 0,
    this.lastRole = 'unspecified',
    this.proxyHost = '127.0.0.1',
    this.proxyPort = 1080,
    this.autoQrRotation = true,
  });

  AppSettings copyWith({
    bool? dohEnabled,
    bool? killSwitchEnabled,
    bool? ttlEnabled,
    bool? dpiEnabled,
    bool? uaEnabled,
    bool? darkMode,
    String? locale,
    int? bandwidthLimitKbps,
    String? lastRole,
    String? proxyHost,
    int? proxyPort,
    bool? autoQrRotation,
  }) {
    return AppSettings(
      dohEnabled: dohEnabled ?? this.dohEnabled,
      killSwitchEnabled: killSwitchEnabled ?? this.killSwitchEnabled,
      ttlEnabled: ttlEnabled ?? this.ttlEnabled,
      dpiEnabled: dpiEnabled ?? this.dpiEnabled,
      uaEnabled: uaEnabled ?? this.uaEnabled,
      darkMode: darkMode ?? this.darkMode,
      locale: locale ?? this.locale,
      bandwidthLimitKbps: bandwidthLimitKbps ?? this.bandwidthLimitKbps,
      lastRole: lastRole ?? this.lastRole,
      proxyHost: proxyHost ?? this.proxyHost,
      proxyPort: proxyPort ?? this.proxyPort,
      autoQrRotation: autoQrRotation ?? this.autoQrRotation,
    );
  }
}

/// StateNotifier that persists settings to SharedPreferences.
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs) : super(const AppSettings()) {
    _load();
  }

  void _load() {
    state = AppSettings(
      dohEnabled: _prefs.getBool(SettingsKeys.dohEnabled) ?? true,
      killSwitchEnabled: _prefs.getBool(SettingsKeys.killSwitchEnabled) ?? true,
      ttlEnabled: _prefs.getBool(SettingsKeys.ttlEnabled) ?? true,
      dpiEnabled: _prefs.getBool(SettingsKeys.dpiEnabled) ?? true,
      uaEnabled: _prefs.getBool(SettingsKeys.uaEnabled) ?? true,
      darkMode: _prefs.getBool(SettingsKeys.darkMode) ?? true,
      locale: _prefs.getString(SettingsKeys.locale) ?? 'en',
      bandwidthLimitKbps: _prefs.getInt(SettingsKeys.bandwidthLimitKbps) ?? 0,
      lastRole: _prefs.getString(SettingsKeys.lastRole) ?? 'unspecified',
      proxyHost: _prefs.getString(SettingsKeys.proxyHost) ?? '127.0.0.1',
      proxyPort: _prefs.getInt(SettingsKeys.proxyPort) ?? 1080,
      autoQrRotation: _prefs.getBool(SettingsKeys.autoQrRotation) ?? true,
    );
  }

  Future<void> setDohEnabled(bool value) async {
    state = state.copyWith(dohEnabled: value);
    await _prefs.setBool(SettingsKeys.dohEnabled, value);
  }

  Future<void> setKillSwitchEnabled(bool value) async {
    state = state.copyWith(killSwitchEnabled: value);
    await _prefs.setBool(SettingsKeys.killSwitchEnabled, value);
  }

  Future<void> setTtlEnabled(bool value) async {
    state = state.copyWith(ttlEnabled: value);
    await _prefs.setBool(SettingsKeys.ttlEnabled, value);
  }

  Future<void> setDpiEnabled(bool value) async {
    state = state.copyWith(dpiEnabled: value);
    await _prefs.setBool(SettingsKeys.dpiEnabled, value);
  }

  Future<void> setUaEnabled(bool value) async {
    state = state.copyWith(uaEnabled: value);
    await _prefs.setBool(SettingsKeys.uaEnabled, value);
  }

  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(darkMode: value);
    await _prefs.setBool(SettingsKeys.darkMode, value);
  }

  Future<void> setLocale(String value) async {
    state = state.copyWith(locale: value);
    await _prefs.setString(SettingsKeys.locale, value);
  }

  Future<void> setBandwidthLimit(int kbps) async {
    state = state.copyWith(bandwidthLimitKbps: kbps);
    await _prefs.setInt(SettingsKeys.bandwidthLimitKbps, kbps);
  }

  Future<void> setLastRole(String role) async {
    state = state.copyWith(lastRole: role);
    await _prefs.setString(SettingsKeys.lastRole, role);
  }

  Future<void> setProxyHost(String host) async {
    state = state.copyWith(proxyHost: host);
    await _prefs.setString(SettingsKeys.proxyHost, host);
  }

  Future<void> setProxyPort(int port) async {
    state = state.copyWith(proxyPort: port);
    await _prefs.setInt(SettingsKeys.proxyPort, port);
  }

  Future<void> setAutoQrRotation(bool value) async {
    state = state.copyWith(autoQrRotation: value);
    await _prefs.setBool(SettingsKeys.autoQrRotation, value);
  }
}

/// Provider for SharedPreferences instance. Must be overridden at app startup.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized before use');
});

/// Provider for persisted settings.
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
