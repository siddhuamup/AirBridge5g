import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:airbridge_5g/app.dart';
import 'package:airbridge_5g/providers/settings_provider.dart';
import 'package:airbridge_5g/providers/daemon_provider.dart';
import 'package:airbridge_5g/services/daemon_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalDaemonClient localDaemon;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    localDaemon = LocalDaemonClient();
  });

  testWidgets('AirBridgeApp renders Home Screen with Provide and Receive options', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          daemonProvider.overrideWithValue(localDaemon),
        ],
        child: const AirBridgeApp(),
      ),
    );

    // Allow entry animation to complete
    await tester.pump(const Duration(seconds: 1));

    // Verify title and brand
    expect(find.text('AirBridge 5G'), findsAtLeastNWidgets(1));
    expect(find.text('Cross-Platform Network Resilience'), findsOneWidget);

    // Verify role selection cards
    expect(find.text('Provide Data'), findsOneWidget);
    expect(find.text('Receive Data'), findsOneWidget);
  });

  testWidgets('Tapping Provide Data navigates to Master Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          daemonProvider.overrideWithValue(localDaemon),
        ],
        child: const AirBridgeApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    // Tap Provide Data card
    await tester.tap(find.text('Provide Data'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Verify Master Dashboard header
    expect(find.text('MASTER NODE'), findsOneWidget);
    expect(find.text('Scan to Connect'), findsOneWidget);
    expect(find.text('Live Traffic'), findsOneWidget);
  });

  testWidgets('Tapping Receive Data navigates to Client Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          daemonProvider.overrideWithValue(localDaemon),
        ],
        child: const AirBridgeApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    // Tap Receive Data card
    await tester.tap(find.text('Receive Data'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Verify Client Dashboard header
    expect(find.text('CLIENT MODE'), findsOneWidget);
    expect(find.text('Scan QR Code'), findsOneWidget);
  });
}
