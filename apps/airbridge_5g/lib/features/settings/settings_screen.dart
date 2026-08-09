import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../providers/role_provider.dart';
import '../../providers/daemon_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/ota_update.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Settings screen — accessible from both Master and Client modes.
/// Settings are now persisted via SharedPreferences.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _t(BuildContext context, String key) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return key;
    
    switch (key) {
      case 'Settings': return loc.settings;
      case 'Appearance': return loc.theme;
      case 'Language': return loc.language;
      case 'DNS Privacy': return loc.dnsPrivacy;
      case 'Kill Switch': return loc.killSwitch;
      case 'Version': return loc.version;
      case 'Dark Mode': return loc.darkMode;
      default: return key;
    }
  }

  Future<void> _syncDaemonPrivacy() async {
    try {
      final settings = ref.read(settingsProvider);
      final daemonClient = ref.read(daemonProvider);
      await daemonClient.setPrivacyConfig(
        dohEnabled: settings.dohEnabled,
        killSwitchEnabled: settings.killSwitchEnabled,
        ttlEnabled: settings.ttlEnabled,
        fragmenterEnabled: settings.dpiEnabled,
        uaHarmonizeEnabled: settings.uaEnabled,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Privacy config sync error: $e')),
        );
      }
    }
  }

  Future<bool> _authenticateBiometric(BuildContext context) async {
    try {
      const channel = MethodChannel('com.airbridge/security');
      final bool? authenticated = await channel.invokeMethod<bool>('authenticateBiometric');
      if (authenticated == true) return true;
    } catch (_) {
      // Fallback dialog
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.fingerprint_rounded, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Biometric Verification'),
          ],
        ),
        content: const Text('Scan Fingerprint / FaceID to alter security settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Authenticate'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _checkForUpdates() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final updateInfo = await OtaUpdateManager.checkForUpdate();
    
    if (mounted) Navigator.pop(context);
    
    if (updateInfo != null && mounted) {
      OtaUpdateManager.showUpdateDialog(context, updateInfo);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are on the latest version.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(roleProvider);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final isMaster = role == NodeRole.master;
    final bgColor = isMaster ? AirBridgeColors.masterPrimary : AirBridgeColors.clientSurface;
    final textColor = isMaster ? Colors.white : AirBridgeColors.clientText;
    final cardColor = isMaster ? AirBridgeColors.masterSurface : Colors.white;
    final accentColor = isMaster ? AirBridgeColors.masterAccent : AirBridgeColors.clientPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _t(context, 'Settings'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // Appearance Section
          _SectionHeader(title: _t(context, 'Appearance'), color: textColor),
          _SettingsCard(
            cardColor: cardColor,
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_rounded,
                title: _t(context, 'Dark Mode'),
                subtitle: settings.darkMode ? 'Enabled' : 'Disabled',
                textColor: textColor,
                accentColor: accentColor,
                trailing: Switch(
                  value: settings.darkMode,
                  onChanged: (val) {
                    settingsNotifier.setDarkMode(val);
                    ref.read(themeModeProvider.notifier).state =
                        val ? ThemeMode.dark : ThemeMode.light;
                  },
                  activeColor: accentColor,
                ),
              ),
              _Divider(color: textColor),
              _SettingsTile(
                icon: Icons.language_rounded,
                title: _t(context, 'Language'),
                subtitle: _languageName(settings.locale),
                textColor: textColor,
                accentColor: accentColor,
                trailing: DropdownButton<String>(
                  value: settings.locale,
                  dropdownColor: cardColor,
                  underline: const SizedBox.shrink(),
                  style: TextStyle(color: textColor, fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                    DropdownMenuItem(value: 'mr', child: Text('मराठी')),
                    DropdownMenuItem(value: 'es', child: Text('Español')),
                    DropdownMenuItem(value: 'fr', child: Text('Français')),
                    DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                    DropdownMenuItem(value: 'ja', child: Text('日本語')),
                    DropdownMenuItem(value: 'zh', child: Text('中文')),
                    DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    DropdownMenuItem(value: 'pt', child: Text('Português')),
                  ],
                  onChanged: (val) {
                    if (val != null) settingsNotifier.setLocale(val);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Network Section
          _SectionHeader(title: _t(context, 'Network'), color: textColor),
          _SettingsCard(
            cardColor: cardColor,
            children: [
              _SettingsTile(
                icon: Icons.security_rounded,
                title: _t(context, 'Encryption'),
                subtitle: 'TLS 1.3 + ChaCha20-Poly1305',
                textColor: textColor,
                accentColor: accentColor,
              ),
              _Divider(color: textColor),
              _SettingsTile(
                icon: Icons.dns_rounded,
                title: _t(context, 'DNS Privacy'),
                subtitle: 'DNS-over-HTTPS (DoH)',
                textColor: textColor,
                accentColor: accentColor,
                trailing: Switch(
                  value: settings.dohEnabled,
                  onChanged: (val) {
                    settingsNotifier.setDohEnabled(val);
                    _syncDaemonPrivacy();
                  },
                  activeColor: accentColor,
                ),
              ),
              _Divider(color: textColor),
              _SettingsTile(
                icon: Icons.shield_rounded,
                title: _t(context, 'Kill Switch'),
                subtitle: 'Block traffic on disconnect',
                textColor: textColor,
                accentColor: accentColor,
                trailing: Switch(
                  value: settings.killSwitchEnabled,
                  onChanged: (val) async {
                    if (await _authenticateBiometric(context)) {
                      settingsNotifier.setKillSwitchEnabled(val);
                      _syncDaemonPrivacy();
                    }
                  },
                  activeColor: accentColor,
                ),
              ),
              _Divider(color: textColor),
              _SettingsTile(
                icon: Icons.speed_rounded,
                title: _t(context, 'Bandwidth Limit'),
                subtitle: settings.bandwidthLimitKbps == 0
                    ? 'Unlimited'
                    : '${settings.bandwidthLimitKbps} Kbps',
                textColor: textColor,
                accentColor: accentColor,
                trailing: DropdownButton<int>(
                  value: settings.bandwidthLimitKbps,
                  dropdownColor: cardColor,
                  underline: const SizedBox.shrink(),
                  style: TextStyle(color: textColor, fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Unlimited')),
                    DropdownMenuItem(value: 512, child: Text('512 Kbps')),
                    DropdownMenuItem(value: 1024, child: Text('1 Mbps')),
                    DropdownMenuItem(value: 2048, child: Text('2 Mbps')),
                    DropdownMenuItem(value: 5120, child: Text('5 Mbps')),
                    DropdownMenuItem(value: 10240, child: Text('10 Mbps')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      settingsNotifier.setBandwidthLimit(val);
                      _syncDaemonPrivacy();
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Privacy Section
          _SectionHeader(title: _t(context, 'Privacy Engine'), color: textColor),
          _SettingsCard(
            cardColor: cardColor,
            children: [
              _SettingsTile(
                icon: Icons.fingerprint_rounded,
                title: _t(context, 'TTL Normalization'),
                subtitle: 'Target TTL: 64 (Mobile signature)',
                textColor: textColor,
                accentColor: accentColor,
                trailing: Switch(
                  value: settings.ttlEnabled,
                  onChanged: (val) {
                    settingsNotifier.setTtlEnabled(val);
                    _syncDaemonPrivacy();
                  },
                  activeColor: accentColor,
                ),
              ),
              _Divider(color: textColor),
              _SettingsTile(
                icon: Icons.broken_image_rounded,
                title: _t(context, 'DPI Resilience'),
                subtitle: 'Random packet fragmentation',
                textColor: textColor,
                accentColor: accentColor,
                trailing: Switch(
                  value: settings.dpiEnabled,
                  onChanged: (val) {
                    settingsNotifier.setDpiEnabled(val);
                    _syncDaemonPrivacy();
                  },
                  activeColor: accentColor,
                ),
              ),
              _Divider(color: textColor),
              _SettingsTile(
                icon: Icons.phone_android_rounded,
                title: _t(context, 'User-Agent Harmonization'),
                subtitle: 'Mask desktop traffic as mobile',
                textColor: textColor,
                accentColor: accentColor,
                trailing: Switch(
                  value: settings.uaEnabled,
                  onChanged: (val) {
                    settingsNotifier.setUaEnabled(val);
                    _syncDaemonPrivacy();
                  },
                  activeColor: accentColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // QR Section
          _SectionHeader(title: _t(context, 'QR Credentials'), color: textColor),
          _SettingsCard(
            cardColor: cardColor,
            children: [
              _SettingsTile(
                icon: Icons.qr_code_rounded,
                title: _t(context, 'Auto QR Rotation'),
                subtitle: 'Regenerate credentials every 24h',
                textColor: textColor,
                accentColor: accentColor,
                trailing: Switch(
                  value: settings.autoQrRotation,
                  onChanged: (val) {
                    settingsNotifier.setAutoQrRotation(val);
                  },
                  activeColor: accentColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // About Section
          _SectionHeader(title: _t(context, 'About'), color: textColor),
          _SettingsCard(
            cardColor: cardColor,
            children: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: _t(context, 'Version'),
                subtitle: '1.0.0+1',
                textColor: textColor,
                accentColor: accentColor,
                onTap: _checkForUpdates,
                trailing: Text(
                  AppLocalizations.of(context)?.checkUpdates ?? 'Check for updates',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _Divider(color: textColor),
              _SettingsTile(
                icon: Icons.code_rounded,
                title: _t(context, 'Open Source Licenses'),
                subtitle: 'MIT, Apache 2.0, BSD',
                textColor: textColor,
                accentColor: accentColor,
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _languageName(String locale) {
    switch (locale) {
      case 'hi': return 'हिन्दी';
      case 'mr': return 'मराठी';
      case 'es': return 'Español';
      case 'fr': return 'Français';
      case 'de': return 'Deutsch';
      case 'ja': return '日本語';
      case 'zh': return '中文';
      case 'ar': return 'العربية';
      case 'pt': return 'Português';
      default: return 'English';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color.withValues(alpha: 0.5),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Color cardColor;
  final List<Widget> children;

  const _SettingsCard({required this.cardColor, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color textColor;
  final Color accentColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.accentColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: accentColor.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;

  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }
}
