import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'providers/settings_provider.dart';

void main() {
  // Wrap entire app in runZonedGuarded for crash recovery
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize SharedPreferences before app starts
    final prefs = await SharedPreferences.getInstance();

    // Set global error widget for release mode
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (kReleaseMode) {
        return Material(
          child: Container(
            color: const Color(0xFF0A1628),
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFFF5252),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The app encountered an unexpected error.\nPlease restart AirBridge 5G.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      // In debug mode, show the default red error screen
      return ErrorWidget(details.exception);
    };

    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError(details.exception, details.stack);
    };

    // Catch platform dispatcher errors (e.g., platform channel failures)
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError(error, stack);
      return true; // Handled
    };

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const AirBridgeApp(),
      ),
    );
  }, (error, stack) {
    // Catch all uncaught async errors
    _logError(error, stack);
  });
}

/// Logs errors — in production, this would send to Sentry/Crashlytics.
void _logError(Object error, StackTrace? stack) {
  debugPrint('╔══════════════════════════════════════════════════════');
  debugPrint('║ [AirBridge 5G] UNCAUGHT ERROR');
  debugPrint('║ Error: $error');
  if (stack != null) {
    debugPrint('║ Stack: $stack');
  }
  debugPrint('╚══════════════════════════════════════════════════════');
}
