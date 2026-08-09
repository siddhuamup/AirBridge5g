import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airbridge_5g/providers/role_provider.dart';
import 'package:airbridge_5g/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RoleProvider', () {
    test('initial state is neutral', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      expect(container.read(roleProvider), NodeRole.neutral);
    });

    test('can set role to master', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(roleProvider.notifier).setRole(NodeRole.master);
      expect(container.read(roleProvider), NodeRole.master);
    });

    test('can clear role to neutral', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(roleProvider.notifier).setRole(NodeRole.client);
      expect(container.read(roleProvider), NodeRole.client);

      container.read(roleProvider.notifier).clearRole();
      expect(container.read(roleProvider), NodeRole.neutral);
    });
  });

  group('SettingsProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial values are defaults', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final settings = container.read(settingsProvider);
      expect(settings.darkMode, false);
      expect(settings.dohEnabled, false);
      expect(settings.killSwitchEnabled, true);
    });

    test('can update dark mode', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      container.read(settingsProvider.notifier).setDarkMode(true);
      expect(container.read(settingsProvider).darkMode, true);
    });
  });
}
