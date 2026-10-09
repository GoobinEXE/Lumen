import 'dart:io';

import 'package:flutter/foundation.dart';

import 'connectors/apple_health_kit_connector.dart';
import 'connectors/health_connect_connector.dart';
import 'connectors/samsung_health_connector.dart';
import 'health_app_connector.dart';

/// Par primary + fallback escolhido para a plataforma atual.
class SelectedHealthConnectors {
  const SelectedHealthConnectors({
    required this.primary,
    this.fallback,
  });

  final HealthAppConnector primary;
  final HealthAppConnector? fallback;
}

/// Escolhe o connector ativo: HealthKit (iOS), Samsung + HC, ou só HC.
class HealthConnectorSelector {
  HealthConnectorSelector({
    AppleHealthKitConnector? apple,
    SamsungHealthConnector? samsung,
    HealthConnectConnector? healthConnect,
  })  : _apple = apple ?? AppleHealthKitConnector(),
        _samsung = samsung ?? SamsungHealthConnector(),
        _healthConnect = healthConnect ?? HealthConnectConnector();

  final AppleHealthKitConnector _apple;
  final SamsungHealthConnector _samsung;
  final HealthConnectConnector _healthConnect;

  Future<SelectedHealthConnectors> resolve() async {
    if (!kIsWeb && Platform.isIOS) {
      return SelectedHealthConnectors(primary: _apple);
    }

    if (!kIsWeb && Platform.isAndroid) {
      if (await _samsung.isAvailable()) {
        return SelectedHealthConnectors(
          primary: _samsung,
          fallback: _healthConnect,
        );
      }
      return SelectedHealthConnectors(primary: _healthConnect);
    }

    return SelectedHealthConnectors(primary: _healthConnect);
  }
}
