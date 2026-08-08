import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../providers/role_provider.dart';
import '../../providers/daemon_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';

/// Settings screen — accessible from both Master and Client modes.
/// Settings are now persisted via SharedPreferences.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _t(String key, String locale) {
    const translations = {
      'Settings': {'hi': 'सेटिंग्स', 'mr': 'सेटिंग्ज', 'es': 'Ajustes', 'fr': 'Paramètres', 'de': 'Einstellungen', 'ja': '設定', 'zh': '设置', 'ar': 'الإعدادات', 'pt': 'Configurações'},
      'Appearance': {'hi': 'दिखावट', 'mr': 'दिसणे', 'es': 'Apariencia', 'fr': 'Apparence', 'de': 'Erscheinungsbild', 'ja': '外観', 'zh': '外观', 'ar': 'المظهر', 'pt': 'Aparência'},
      'Network': {'hi': 'नेटवर्क', 'mr': 'नेटवर्क', 'es': 'Red', 'fr': 'Réseau', 'de': 'Netzwerk', 'ja': 'ネットワーク', 'zh': '网络', 'ar': 'الشبكة', 'pt': 'Rede'},
      'Privacy Engine': {'hi': 'प्राइवेसी इंजन', 'mr': 'प्रायव्हसी इंजिन', 'es': 'Motor de Privacidad', 'fr': 'Moteur de Confidentialité', 'de': 'Datenschutz-Engine', 'ja': 'プライバシーエンジン', 'zh': '隐私引擎', 'ar': 'محرك الخصوصية', 'pt': 'Motor de Privacidade'},
      'About': {'hi': 'के बारे में', 'mr': 'बद्दल', 'es': 'Acerca de', 'fr': 'À propos', 'de': 'Über', 'ja': '情報', 'zh': '关于', 'ar': 'حول', 'pt': 'Sobre'},
      'Dark Mode': {'hi': 'डार्क मोड', 'mr': 'डार्क मोड', 'es': 'Modo Oscuro', 'fr': 'Mode Sombre', 'de': 'Dunkelmodus', 'ja': 'ダークモード', 'zh': '深色模式', 'ar': 'الوضع الداكن', 'pt': 'Modo Escuro'},
      'Language': {'hi': 'भाषा', 'mr': 'भाषा', 'es': 'Idioma', 'fr': 'Langue', 'de': 'Sprache', 'ja': '言語', 'zh': '语言', 'ar': 'اللغة', 'pt': 'Idioma'},
      'Encryption': {'hi': 'एन्क्रिप्शन', 'mr': 'एन्क्रिप्शन', 'es': 'Cifrado', 'fr': 'Chiffrement', 'de': 'Verschlüsselung', 'ja': '暗号化', 'zh': '加密', 'ar': 'التشفير', 'pt': 'Criptografia'},
      'DNS Privacy': {'hi': 'डीएनएस गोपनीयता', 'mr': 'डीएनएस गोपनीयता', 'es': 'Privacidad DNS', 'fr': 'Confidentialité DNS', 'de': 'DNS-Datenschutz', 'ja': 'DNSプライバシー', 'zh': 'DNS隐私', 'ar': 'خصوصية DNS', 'pt': 'Privacidade DNS'},
      'Kill Switch': {'hi': 'किल स्विच', 'mr': 'किल स्विच', 'es': 'Interruptor de Corte', 'fr': 'Kill Switch', 'de': 'Kill-Switch', 'ja': 'キルスイッチ', 'zh': '切断开关', 'ar': 'مفتاح الإيقاف', 'pt': 'Kill Switch'},
      'Bandwidth Limit': {'hi': 'बैंडविड्थ सीमा', 'mr': 'बँडविड्थ मर्यादा', 'es': 'Límite de Ancho de Banda', 'fr': 'Limite de Bande Passante', 'de': 'Bandbreitenbegrenzung', 'ja': '帯域幅制限', 'zh': '带宽限制', 'ar': 'حد نطاق التردد', 'pt': 'Limite de Largura de Banda'},
      'TTL Normalization': {'hi': 'टीटीएल समानीकरण', 'mr': 'टीटीएल नॉर्मलायझेशन', 'es': 'Normalización TTL', 'fr': 'Normalisation TTL', 'de': 'TTL-Normalisierung', 'ja': 'TTL正規化', 'zh': 'TTL标准化', 'ar': 'تطبيع TTL', 'pt': 'Normalização TTL'},
      'DPI Resilience': {'hi': 'डीपीआई लचीलापन', 'mr': 'डीपीआय रेझिलियन्स', 'es': 'Resiliencia DPI', 'fr': 'Résilience DPI', 'de': 'DPI-Resilienz', 'ja': 'DPI耐性', 'zh': 'DPI抗性', 'ar': 'مرونة DPI', 'pt': 'Resiliência DPI'},
      'User-Agent Harmonization': {'hi': 'यूज़र-एजेंट सामंजस्य', 'mr': 'युझर-एजंट सुसंगतता', 'es': 'Armonización User-Agent', 'fr': 'Harmonisation User-Agent', 'de': 'User-Agent-Harmonisierung', 'ja': 'User-Agent適合', 'zh': 'User-Agent谐调', 'ar': 'تنسيق وكيل المستخدم', 'pt': 'Harmonização de User-Agent'},
      'QR Credentials': {'hi': 'क्यूआर क्रेडेंशियल', 'mr': 'क्यूआर क्रेडेंशियल', 'es': 'Credenciales QR', 'fr': 'Identifiants QR', 'de': 'QR-Anmeldedaten', 'ja': 'QR資格情報', 'zh': 'QR凭据', 'ar': 'بيانات اعتماد QR', 'pt': 'Credenciais QR'},
      'Auto QR Rotation': {'hi': 'ऑटो क्यूआर रोटेशन', 'mr': 'ऑटो क्यूआर रोटेशन', 'es': 'Rotación Automática QR', 'fr': 'Rotation Auto des QR', 'de': 'Auto-QR-Rotation', 'ja': 'QR自動ローテーション', 'zh': 'QR自动轮换', 'ar': 'تدوير QR التلقائي', 'pt': 'Rotação Automática de QR'},
      'Version': {'hi': 'संस्करण', 'mr': 'आवृत्ती', 'es': 'Versión', 'fr': 'Version', 'de': 'Version', 'ja': 'バージョン', 'zh': '版本', 'ar': 'الإصدار', 'pt': 'Versão'},
      'Open Source Licenses': {'hi': 'ओपन सोर्स लाइसेंस', 'mr': 'ओपन सोर्स परवाने', 'es': 'Licencias de Código Abierto', 'fr': 'Licences Open Source', 'de': 'Open-Source-Lizenzen', 'ja': 'オープンソースライセンス', 'zh': '开源许可证', 'ar': 'تراخيص المصدر المفتوح', 'pt': 'Licenças de Código Aberto'},
    };
    return translations[key]?[locale] ?? key;
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
          _t('Settings', settings.locale),
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // Appearance Section
          _SectionHeader(title: _t('Appearance', settings.locale), color: textColor),
          _SettingsCard(
            cardColor: cardColor,
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_rounded,
                title: _t('Dark Mode', settings.locale),
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
                title: _t('Language', settings.locale),
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
          _SectionHeader(title: _t('Network', settings.locale), color: textColor),
          _SettingsCard(
            cardColor: cardColor,
            children: [
              _SettingsTile(
                icon: Icons.security_rounded,
                title: _t('Encryption', settings.locale),
                subtitle: 'TLS 1.3 + ChaCha20-Poly1305',
                textColor: textColor,
                accentColor: accentColor,
              ),
              _Divider(color: textColor),
              _SettingsTile(
                icon: Icons.dns_rounded,
                title: _t('DNS Privacy', settings.locale),
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
                title: _t('Kill Switch', settings.locale),
                subtitle: 'Block traffic on disconnect',
                textColor: textColor,
                accentColor: accentColor,
                trailing: Switch(
                  value: settings.killSwitchEnabled,
                  onChanged: (val) {
                    settingsNotifier.setKillSwitchEnabled(val);
                    _syncDaemonPrivacy();
                  },
                  activeColor: accentColor,
                ),
              ),
              _Divider(color: textColor),
              _SettingsTile(
                icon: Icons.speed_rounded,
                title: _t('Bandwidth Limit', settings.locale),
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
          _SectionHeader(title: _t('Privacy Engine', settings.locale), color: textColor),
          _SettingsCard(
            cardColor: cardColor,
            children: [
              _SettingsTile(
                icon: Icons.fingerprint_rounded,
                title: _t('TTL Normalization', settings.locale),
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
                title: _t('DPI Resilience', settings.locale),
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
                title: _t('User-Agent Harmonization', settings.locale),
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
          _SectionHeader(title: _t('QR Credentials', settings.locale), color: textColor),
          _SettingsCard(
            cardColor: cardColor,
            children: [
              _SettingsTile(
                icon: Icons.qr_code_rounded,
                title: _t('Auto QR Rotation', settings.locale),
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
          _SectionHeader(title: _t('About', settings.locale), color: textColor),
          _SettingsCard(
            cardColor: cardColor,
            children: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: _t('Version', settings.locale),
                subtitle: '1.0.0-alpha',
                textColor: textColor,
                accentColor: accentColor,
              ),
              _Divider(color: textColor),
              _SettingsTile(
                icon: Icons.code_rounded,
                title: _t('Open Source Licenses', settings.locale),
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
