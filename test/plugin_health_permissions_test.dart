import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:noa/integrations/health/plugin_health_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('iOS lê HRV SDNN e exercício em minutos, sem tipo do Android', () {
    expect(PluginHealthStore.recoveryReadTypes(ios: true).toSet(), {
      HealthDataType.HEART_RATE_VARIABILITY_SDNN,
      HealthDataType.RESTING_HEART_RATE,
      HealthDataType.STEPS,
      HealthDataType.EXERCISE_TIME,
    });
    expect(
      PluginHealthStore.recoveryReadTypes(ios: true),
      isNot(contains(HealthDataType.HEART_RATE_VARIABILITY_RMSSD)),
    );
    expect(
      PluginHealthStore.recoveryReadTypes(ios: true),
      isNot(contains(HealthDataType.WORKOUT)),
    );
    expect(PluginHealthStore.demographicsReadTypes(ios: true).toSet(), {
      HealthDataType.HEIGHT,
      HealthDataType.WEIGHT,
      HealthDataType.GENDER,
      HealthDataType.BIRTH_DATE,
    });
    expect(PluginHealthStore.writeTypes(ios: true), [
      HealthDataType.WATER,
      HealthDataType.MINDFULNESS,
    ]);
  });

  test('Android lê HRV RMSSD e exercício via treino, sem tipo do iOS', () {
    expect(PluginHealthStore.recoveryReadTypes(ios: false).toSet(), {
      HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
      HealthDataType.RESTING_HEART_RATE,
      HealthDataType.STEPS,
      HealthDataType.WORKOUT,
    });
    expect(
      PluginHealthStore.recoveryReadTypes(ios: false),
      isNot(contains(HealthDataType.HEART_RATE_VARIABILITY_SDNN)),
    );
    expect(
      PluginHealthStore.recoveryReadTypes(ios: false),
      isNot(contains(HealthDataType.EXERCISE_TIME)),
    );
    expect(PluginHealthStore.demographicsReadTypes(ios: false), [
      HealthDataType.HEIGHT,
      HealthDataType.WEIGHT,
    ]);
    expect(PluginHealthStore.writeTypes(ios: false), [
      HealthDataType.WATER,
      HealthDataType.WORKOUT,
    ]);
    expect(
      PluginHealthStore.writeTypes(ios: false),
      isNot(contains(HealthDataType.MINDFULNESS)),
    );
  });

  test('sono pede os estágios e a FC da noite', () {
    expect(PluginHealthStore.sleepReadTypes.toSet(), {
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_REM,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.HEART_RATE,
    });
    expect(PluginHealthStore.sleepReadTypes, hasLength(6));
  });

  test('cada tipo do pedido de permissão leva o acesso da mesma posição', () {
    final store = PluginHealthStore();
    for (final ios in [true, false]) {
      final types = store.allTypes(ios: ios);
      final access = store.allPermissions(ios: ios);
      final writes = PluginHealthStore.writeTypes(ios: ios);
      expect(access, hasLength(types.length));
      expect(types.sublist(types.length - writes.length), writes);
      final writeStart = types.length - writes.length;
      for (var i = 0; i < writeStart; i++) {
        expect(
          access[i],
          HealthDataAccess.READ,
          reason: '${types[i].name} ios=$ios',
        );
      }
      for (var i = writeStart; i < types.length; i++) {
        expect(
          access[i],
          HealthDataAccess.READ_WRITE,
          reason: '${types[i].name} ios=$ios',
        );
      }
    }
    expect(
      store.allTypes(ios: true).toSet(),
      hasLength(store.allTypes(ios: true).length),
    );
  });
}
