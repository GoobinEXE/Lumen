import 'package:noa/l10n/app_localizations.dart';

import '../../features/state_of_mind/domain/state_of_mind_entry.dart';
import '../healthkit_bridge/healthkit_bridge.dart';
import 'health_app_source.dart';
import 'health_capability.dart';
import 'models/daily_environment_snapshot.dart';
import 'models/daily_recovery_snapshot.dart';
import 'models/health_demographics.dart';
import 'models/sleep_record.dart';

/// Contrato de integração com um app / SDK de saúde.
///
/// Cada OEM ou plataforma (HealthKit, Samsung Health, Health Connect) implementa
/// esta interface. A UI só fala com [HealthService], que escolhe o connector.
abstract class HealthAppConnector {
  HealthAppSource get source;

  Set<HealthCapability> get supportedCapabilities;

  Future<bool> isAvailable();

  Future<void> initialize();

  Future<bool> requestPermissions();

  Future<bool> hasPermissions();

  Future<List<SleepRecord>> getSleepHistory({int days = 7});

  Future<List<DailyRecoverySnapshot>> getRecoveryHistory({int days = 14});

  Future<List<DailyEnvironmentSnapshot>> getEnvironmentHistory({int days = 14});

  Future<HealthDemographics> readDemographics();

  Future<bool> writeWaterIntake({
    required DateTime when,
    required double liters,
  });

  Future<bool> writeMindfulnessSession({
    required DateTime start,
    required DateTime end,
  });

  Future<bool> writeStateOfMind(StateOfMindEntry entry);

  Future<List<StateOfMindEntry>> getStateOfMindHistory({int days = 14});

  Future<bool> isMedicationsApiAvailable();

  Future<List<HealthKitMedicationInfo>> readMedications();

  Future<List<HealthKitDoseEvent>> readDoseEvents({
    required String appleConceptId,
    required DateTime start,
    required DateTime end,
  });

  String sourceName(AppLocalizations l10n);
}

extension HealthAppConnectorX on HealthAppConnector {
  bool supports(HealthCapability capability) =>
      supportedCapabilities.contains(capability);
}
