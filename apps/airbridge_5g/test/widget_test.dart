import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airbridge_5g/app.dart';
import 'package:airbridge_5g/features/home/home_screen.dart';

void main() {
  testWidgets('AirBridgeApp renders Home Screen with Provide and Receive options', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AirBridgeApp(),
      ),
    );

    // Allow entry animation to complete
    await tester.pumpAndSettle();

    // Verify title and brand
    expect(find.text('AirBridge 5G'), findsOneWidget);
    expect(find.text('Cross-Platform Network Resilience'), findsOneWidget);

    // Verify role selection cards
    expect(find.text('Provide Data'), findsOneWidget);
    expect(find.text('Receive Data'), findsOneWidget);
  });

  testWidgets('Tapping Provide Data navigates to Master Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AirBridgeApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Provide Data card
    await tester.tap(find.text('Provide Data'));
    await tester.pumpAndSettle();

    // Verify Master Dashboard header
    expect(find.text('MASTER NODE'), findsOneWidget);
    expect(find.text('Scan to Connect'), findsOneWidget);
    expect(find.text('Live Traffic'), findsOneWidget);
  });

  testWidgets('Tapping Receive Data navigates to Client Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AirBridgeApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Receive Data card
    await tester.tap(find.text('Receive Data'));
    await tester.pumpAndSettle();

    // Verify Client Dashboard header
    expect(find.text('CLIENT MODE'), findsOneWidget);
    expect(find.text('Scan QR Code'), findsOneWidget);
  });
}
