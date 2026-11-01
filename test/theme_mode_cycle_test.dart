import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/core/providers.dart';
import 'package:noa/core/theme/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'noa_theme_mode';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ciclo claro → escuro → sistema → claro persiste', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);

    final notifier = container.read(themeModeProvider.notifier);
    await notifier.cycle();
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(prefs.getString(_key), 'light');

    await notifier.cycle();
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(prefs.getString(_key), 'dark');

    await notifier.cycle();
    expect(container.read(themeModeProvider), ThemeMode.system);
    expect(prefs.getString(_key), 'system');

    await notifier.cycle();
    expect(container.read(themeModeProvider), ThemeMode.light);

    final restored = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(restored.dispose);
    expect(restored.read(themeModeProvider), ThemeMode.light);
  });

  test('valor ilegível fica no sistema e não regrava a chave', () async {
    SharedPreferences.setMockInitialValues(const {_key: 'sepia'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);
    expect(prefs.getString(_key), 'sepia');

    await container.read(themeModeProvider.notifier).cycle();
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(prefs.getString(_key), 'light');
  });
}
