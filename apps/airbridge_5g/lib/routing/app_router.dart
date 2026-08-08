import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../features/home/home_screen.dart';
import '../ui/windows_shell.dart';
import '../features/master/master_dashboard.dart';
import '../features/client/client_dashboard.dart';
import '../features/settings/settings_screen.dart';
import '../features/diagnostics/diagnostics_screen.dart';
import '../features/analytics/analytics_screen.dart';

/// GoRouter provider for navigation with deep linking support.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          if (!kIsWeb && Platform.isWindows) {
            return WindowsShell(child: child);
          }
          return child;
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/master',
            name: 'master',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const MasterDashboard(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
            ),
          ),
          GoRoute(
            path: '/client',
            name: 'client',
            // Deep link: airbridge://connect?host=X&port=Y
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: ClientDashboard(
                deepLinkHost: state.uri.queryParameters['host'],
                deepLinkPort: int.tryParse(state.uri.queryParameters['port'] ?? ''),
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/diagnostics',
            name: 'diagnostics',
            builder: (context, state) => const DiagnosticsScreen(),
          ),
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
        ],
      ),
    ],
  );
});
