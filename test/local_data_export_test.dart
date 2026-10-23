import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/settings/service/local_data_export.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('coleta só chaves noa_ e monta o payload de backup', () async {
    SharedPreferences.setMockInitialValues({
      'noa_theme_mode': 'dark',
      'noa_user_profile_v1': '{"id":"x"}',
      'flutter.something_else': 'ignore',
    });
    final prefs = await SharedPreferences.getInstance();
    const exporter = LocalDataExport();

    final keys = exporter.collectKeys(prefs);
    expect(keys.keys, unorderedEquals(['noa_theme_mode', 'noa_user_profile_v1']));
    expect(keys['noa_theme_mode'], 'dark');
    expect(keys.containsKey('flutter.something_else'), isFalse);

    final payload = exporter.buildPayload(
      prefs,
      exportedAt: DateTime(2026, 10, 6, 12),
    );
    expect(payload['app'], 'lumen');
    expect(payload['exportedAt'], '2026-10-06T12:00:00.000');
    expect(payload['keys'], keys);
  });

  test('backup guarda bool, número e lista e ignora chave sem o prefixo', () async {
    SharedPreferences.setMockInitialValues({
      'noa_health_sync_enabled': true,
      'noa_quiet_start': 22,
      'noa_weight': 62.5,
      'noa_habits': <String>['Água', 'Respirar'],
      'noaTheme': 'dark',
      'secret_noa_backup': 'fora',
    });
    final prefs = await SharedPreferences.getInstance();
    final keys = const LocalDataExport().collectKeys(prefs);

    expect(keys['noa_health_sync_enabled'], isTrue);
    expect(keys['noa_quiet_start'], 22);
    expect(keys['noa_weight'], 62.5);
    expect(keys['noa_habits'], ['Água', 'Respirar']);
    expect(keys.containsKey('noaTheme'), isFalse);
    expect(keys.containsKey('secret_noa_backup'), isFalse);
  });
}
