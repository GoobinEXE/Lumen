import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/core/providers.dart';
import 'package:noa/core/theme/glass_level_provider.dart';
import 'package:noa/core/theme/lumen_glass_level.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('overrideLevel: system não força nível', () {
    expect(LumenGlassPreference.system.overrideLevel, isNull);
    expect(
      LumenGlassPreference.clear.overrideLevel,
      LumenGlassLevel.clear,
    );
    expect(
      LumenGlassPreference.tinted.overrideLevel,
      LumenGlassLevel.tinted,
    );
    expect(
      LumenGlassPreference.solid.overrideLevel,
      LumenGlassLevel.solid,
    );
  });

  test('persiste e restaura noa_glass_level_v1', () async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(glassLevelPreferenceProvider),
      LumenGlassPreference.system,
    );

    await container
        .read(glassLevelPreferenceProvider.notifier)
        .setPreference(LumenGlassPreference.tinted);

    expect(
      container.read(glassLevelPreferenceProvider),
      LumenGlassPreference.tinted,
    );
    expect(prefs.getString(glassLevelPrefKey), 'tinted');

    final restored = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(restored.dispose);
    expect(
      restored.read(glassLevelPreferenceProvider),
      LumenGlassPreference.tinted,
    );
  });

  test('preferência explícita ganha da acessibilidade na resolução', () {
    expect(
      resolveLumenGlassLevel(
        reduceTransparency: true,
        highContrast: true,
        preference: LumenGlassPreference.clear.overrideLevel,
      ),
      LumenGlassLevel.clear,
    );
  });
}
