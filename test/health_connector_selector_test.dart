import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/connectors/health_connect_connector.dart';
import 'package:noa/integrations/health/connectors/samsung_health_connector.dart';
import 'package:noa/integrations/health/facade_health_service.dart';
import 'package:noa/integrations/health/health_app_connector.dart';
import 'package:noa/integrations/health/health_app_source.dart';
import 'package:noa/integrations/health/health_capability.dart';
import 'package:noa/integrations/health/health_connector_selector.dart';
import 'package:noa/integrations/samsung_health_bridge/samsung_health_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthConnectorSelector', () {
    test('Android sem Samsung usa Health Connect como primary', () async {
      const channel = MethodChannel('dev.prism.lumen/samsung_health_bridge');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'isAvailable') return false;
        return null;
      });

      final selected = await HealthConnectorSelector(
        samsung: SamsungHealthConnector(bridge: SamsungHealthBridge()),
        healthConnect: HealthConnectConnector(),
      ).resolve();

      // Em host de teste (macOS/VM) o seletor cai no HC genérico.
      expect(selected.primary.source, HealthAppSource.healthConnect);
      expect(selected.fallback, isNull);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
  });

  group('FacadeHealthService fallback', () {
    test('shouldGuideToHealthConnect segue a fonte ativa', () {
      final service = FacadeHealthService();
      expect(service.activeSource, HealthAppSource.healthConnect);
      expect(service.shouldGuideToHealthConnect, isTrue);
    });
  });

  group('HealthCapability contract', () {
    test('Health Connect declara mindfulness e exercício', () {
      final connector = HealthConnectConnector();
      expect(connector.supports(HealthCapability.mindfulnessWrite), isTrue);
      expect(connector.supports(HealthCapability.exercise), isTrue);
      expect(connector.supports(HealthCapability.stateOfMind), isFalse);
      expect(connector.supports(HealthCapability.medications), isFalse);
    });

    test('Samsung sem SDK não declara capabilities até conectar', () {
      final connector = SamsungHealthConnector();
      expect(connector.supportedCapabilities, isEmpty);
      expect(connector.supports(HealthCapability.sleep), isFalse);
    });
  });
}
