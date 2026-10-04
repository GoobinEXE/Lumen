import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/health_sync/data/health_sync_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('copo, respiração e State of Mind ficam no dia civil', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final morning = DateTime(2026, 9, 20, 8);
    final night = DateTime(2026, 9, 20, 23, 30);
    final nextDay = DateTime(2026, 9, 21, 0, 5);

    await setSyncedWaterGlasses(prefs, morning, 3);
    expect(getSyncedWaterGlasses(prefs, night), 3);
    expect(getSyncedWaterGlasses(prefs, nextDay), 0);

    expect(wasMindfulnessSyncedToday(prefs, morning), isFalse);
    await setMindfulnessSyncedToday(prefs, night, synced: true);
    expect(wasMindfulnessSyncedToday(prefs, morning), isTrue);
    expect(wasMindfulnessSyncedToday(prefs, nextDay), isFalse);

    await setSyncedStateOfMindMs(prefs, morning, 123456);
    expect(getSyncedStateOfMindMs(prefs, night), 123456);
    expect(getSyncedStateOfMindMs(prefs, nextDay), isNull);
  });
}
