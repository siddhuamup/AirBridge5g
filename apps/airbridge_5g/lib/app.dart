import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/role_provider.dart';
import 'providers/theme_provider.dart';
import 'routing/app_router.dart';

/// Root application widget for AirBridge 5G.
/// Dynamically switches between MaterialApp and CupertinoApp
/// based on the target platform.
class AirBridgeApp extends ConsumerWidget {
  const AirBridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final role = ref.watch(roleProvider);

    // Platform-adaptive app shell
    if (_isApplePlatform) {
      return CupertinoApp.router(
        title: 'AirBridge 5G',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: _cupertinoTheme(role),
      );
    }

    return MaterialApp.router(
      title: 'AirBridge 5G',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: themeMode,
      theme: _materialLightTheme(role),
      darkTheme: _materialDarkTheme(role),
    );
  }

  bool get _isApplePlatform {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  /// Material 3 light theme — morphs based on role.
  ThemeData _materialLightTheme(NodeRole role) {
    final ColorScheme scheme;
    switch (role) {
      case NodeRole.master:
        scheme = ColorScheme.fromSeed(
          seedColor: AirBridgeColors.masterPrimary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AirBridgeColors.masterPrimary,
          secondary: AirBridgeColors.masterAccent,
          surface: AirBridgeColors.masterSurface,
          onSurface: Colors.white,
        );
      case NodeRole.client:
        scheme = ColorScheme.fromSeed(
          seedColor: AirBridgeColors.clientPrimary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AirBridgeColors.clientPrimary,
          secondary: AirBridgeColors.clientAccent,
          surface: AirBridgeColors.clientSurface,
        );
      default:
        scheme = ColorScheme.fromSeed(
          seedColor: AirBridgeColors.neutralPrimary,
          brightness: Brightness.dark,
        );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: GoogleFonts.interTextTheme(),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// Material 3 dark theme — always dark navy for master.
  ThemeData _materialDarkTheme(NodeRole role) {
    return _materialLightTheme(role); // Role already drives brightness
  }

  /// Cupertino theme for iOS.
  CupertinoThemeData _cupertinoTheme(NodeRole role) {
    final Color primaryColor;
    final Brightness brightness;

    switch (role) {
      case NodeRole.master:
        primaryColor = AirBridgeColors.masterAccent;
        brightness = Brightness.dark;
      case NodeRole.client:
        primaryColor = AirBridgeColors.clientPrimary;
        brightness = Brightness.light;
      default:
        primaryColor = AirBridgeColors.neutralPrimary;
        brightness = Brightness.dark;
    }

    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      textTheme: CupertinoTextThemeData(
        primaryColor: primaryColor,
      ),
    );
  }
}

/// AirBridge 5G color palette — the DNA of the polymorphic UI.
class AirBridgeColors {
  AirBridgeColors._();

  // Master Mode: Dark Navy + 5G Radiant Green
  static const masterPrimary = Color(0xFF0A1628);   // Deep navy
  static const masterSecondary = Color(0xFF0F2040);  // Navy surface
  static const masterAccent = Color(0xFF00E676);     // 5G Radiant green
  static const masterAccentGlow = Color(0xFF69F0AE); // Green glow
  static const masterSurface = Color(0xFF101D33);    // Card surface
  static const masterError = Color(0xFFFF5252);

  // Client Mode: Minimalist Sky Blue
  static const clientPrimary = Color(0xFF039BE5);    // Sky blue
  static const clientSecondary = Color(0xFF4FC3F7);  // Light sky
  static const clientAccent = Color(0xFF00B0FF);     // Bright accent
  static const clientSurface = Color(0xFFF5F9FF);    // Light surface
  static const clientCardBg = Color(0xFFFFFFFF);
  static const clientText = Color(0xFF1A2B42);

  // Neutral (Home screen before role selection)
  static const neutralPrimary = Color(0xFF1A237E);   // Indigo
  static const neutralAccent = Color(0xFF448AFF);    // Blue accent
  static const neutralSurface = Color(0xFF0D1421);
}
