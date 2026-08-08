import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../providers/role_provider.dart';
import '../../providers/daemon_provider.dart';

/// Settings screen — accessible from both Master and Client modes.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _dohEnabled = true;
  bool _killSwitchEnabled = true;
  bool _ttlEnabled = true;
  bool _dpiEnabled = true;
  bool _uaEnabled = true;

  Future<void> _syncDaemonPrivacy() async {
    try {
      final daemonClient = ref.read(daemonProvider);
      await daemonClient.setPrivacyConfig(
        ttlEnabled: _ttlEnabled,
        fragmenterEnabled: _dpiEnabled,
        uaHarmonizeEnabled: _uaEnabled,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(roleProvider);
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
          'Settings',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // Network Section
          _SectionHeader(title: 'Network', color: textColor),
          _SettingsCard(
            cardColor: cardColor,
            children: [
              _SettingsTile(
                icon: Icons.security_rounded,
                title: 'Encryption',
                subtitle: 'TLS 1.3 + ChaCha20-Poly1305',
                textColor: textColor,
                accentColor: accentColor,
              ),
              _Divider(color: textColor),
              _SettingsTile(
                icon: Icons.dns_rounded,
                title: 'DNS Privacy',
                subtitle: 'DNS-over-HTTPS (DoH)',
                textColor: textColor,
                accentColor: accentColor,
                trailing: Switch(
                  value: _dohEnabled,
                  onChanged: (val) => setState(() => _dohEnabled = val),
                  activeColor: accentColor,
                ),
              ),
              _Divider(color: textColor),
              _SettingsTile(
                icon: Icons.shield_rounded,
                title: 'Kill Switch',
                subtitle: 'Block traffic on disconnect',
                textColor: textColor,
                accentColor: accentColor,
                trailing: Switch(
                  value: _killSwitchEnabled,
                  onChanged: (val) => setState(() => _killSwitchEnabled = val),
                  activeColor: accentColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Privacy Section
          _SectionHeader(title: 'Privacy Engine', color: textColor),
          _SettingsCard(
            cardColor: cardColor,
            children: [
              _SettingsTile(
                icon: Icons.fingerprint_rounded,
                title: 'TTL Normalization',
                subtitle: 'Target TTL: 64 (Mobile signature)',
                textColor: textColor,
                accentColor: accentColor,
                trailing: Switch(
                  value: _ttlEnabled,
                  onChanged: (val) {
                    setState(() => _ttlEnabled = val);
                    _syncDaemonPrivacy();
                  },
                  activeColor: accentColor,
                ),
              ),
              _Divider(color: textColor),
              _SettingsTile(
                icon: Icons.broken_image_rounded,
                title: 'DPI Resilience',
                subtitle: 'Random packet fragmentation',
                textColor: textColor,
                accentColor: accentColor,
                trailing: Switch(
                  value: _dpiEnabled,
                  onChanged: (val) {
                    setState(() => _dpiEnabled = val);
                    _syncDaemonPrivacy();
                  },
                  activeColor: accentColor,
                ),
              ),
              _Divider(color: textColor),
              _SettingsTile(
                icon: Icons.phone_android_rounded,
                title: 'User-Agent Harmonization',
                subtitle: 'Mask desktop traffic as mobile',
                textColor: textColor,
                accentColor: accentColor,
                trailing: Switch(
                  value: _uaEnabled,
                  onChanged: (val) {
                    setState(() => _uaEnabled = val);
                    _syncDaemonPrivacy();
                  },
                  activeColor: accentColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // About Section
          _SectionHeader(title: 'About', color: textColor),
          _SettingsCard(
            cardColor: cardColor,
            children: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'Version',
                subtitle: '1.0.0-alpha',
                textColor: textColor,
                accentColor: accentColor,
              ),
              _Divider(color: textColor),
              _SettingsTile(
                icon: Icons.code_rounded,
                title: 'Open Source Licenses',
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

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.accentColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
