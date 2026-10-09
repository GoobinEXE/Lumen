import 'package:noa/l10n/app_localizations.dart';
import '../../features/state_of_mind/domain/state_of_mind_entry.dart';
import '../healthkit_bridge/healthkit_bridge.dart';
import 'health_app_source.dart';
import 'models/daily_environment_snapshot.dart';
import 'models/daily_recovery_snapshot.dart';
import 'models/health_demographics.dart';
import 'models/sleep_record.dart';

/// Contrato agnóstico de integração com saúde.
/// A UI fala só com este facade; connectors (HealthKit / Samsung / HC) ficam atrás.
abstract class HealthService {
  /// Fonte ativa após [initialize].
  HealthAppSource get activeSource;

  /// True quando a UI deve explicar o caminho OEM → Health Connect.
  bool get shouldGuideToHealthConnect;

  Future<void> initialize();

  /// Permissões do connector ativo (e fallback, se houver).
  Future<bool> requestPermissions();

  Future<bool> hasPermissions();

  /// Agenda de medicação do Health. Lista vazia sem permissão ou fora do iOS.
  Future<bool> isMedicationsApiAvailable();

  Future<List<HealthKitMedicationInfo>> readMedications();

  Future<List<HealthKitDoseEvent>> readDoseEvents({
    required String appleConceptId,
    required DateTime start,
    required DateTime end,
  });

  Future<List<SleepRecord>> getSleepHistory({int days = 7});

  Future<SleepRecord?> getLastNightSleep();

  Future<List<SleepRecord>> syncFromHealth({int days = 14});

  /// Histórico diário de HRV, FC em repouso, passos e exercício.
  Future<List<DailyRecoverySnapshot>> getRecoveryHistory({int days = 14});

  /// Histórico de ambiente (luz do dia + áudio). iOS via bridge; Android vazio.
  Future<List<DailyEnvironmentSnapshot>> getEnvironmentHistory({int days = 14});

  /// Altura, peso, sexo biológico e data de nascimento do app de saúde.
  /// Campo sem permissão ou sem registro volta nulo.
  Future<HealthDemographics> readDemographics();

  /// Espelha State of Mind no Apple Health (iOS 18+). No-op no Android.
  Future<bool> writeStateOfMind(StateOfMindEntry entry);

  /// Lê amostras de State of Mind do Apple Health (iOS 18+).
  Future<List<StateOfMindEntry>> getStateOfMindHistory({int days = 14});

  Future<bool> writeWaterIntake({
    required DateTime when,
    required double liters,
  });

  Future<bool> writeMindfulnessSession({
    required DateTime start,
    required DateTime end,
  });

  String sourceName(AppLocalizations l10n);
}
