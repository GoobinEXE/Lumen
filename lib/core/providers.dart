import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../features/routine_mood/data/mood_repository.dart';
import '../features/routine_mood/domain/mood_entry.dart';
import '../features/sleep_analytics/domain/correlation_engine.dart';
import '../integrations/health/apple_health_service.dart';
import '../integrations/health/health_service.dart';
import '../integrations/health/models/daily_environment_snapshot.dart';
import '../integrations/health/models/daily_recovery_snapshot.dart';
import '../integrations/health/models/sleep_record.dart';
import '../features/state_of_mind/domain/state_of_mind_entry.dart';
import 'localization/correlation_copy.dart';
import 'localization/locale_provider.dart';

/// Provedor de SharedPreferences (inicializado no main)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences precisa ser inicializado no main');
});

/// Serviço de Saúde (Apple HealthKit / Health Connect)
final healthServiceProvider = Provider<HealthService>((ref) {
  return AppleHealthService();
});

/// Histórico de Sono dos últimos 14 dias
final sleepHistoryProvider = FutureProvider<List<SleepRecord>>((ref) async {
  final healthService = ref.watch(healthServiceProvider);
  await healthService.initialize();
  return healthService.getSleepHistory(days: 14);
});

/// Sono dos últimos 30 dias, para o resumo clínico cobrir a janela maior.
final clinicalSleepHistoryProvider = FutureProvider<List<SleepRecord>>((ref) async {
  final healthService = ref.watch(healthServiceProvider);
  await healthService.initialize();
  return healthService.getSleepHistory(days: 30);
});

/// Histórico de recuperação (HRV, FC repouso, passos, exercício)
final recoveryHistoryProvider =
    FutureProvider<List<DailyRecoverySnapshot>>((ref) async {
  final healthService = ref.watch(healthServiceProvider);
  await healthService.initialize();
  return healthService.getRecoveryHistory(days: 14);
});

/// Recuperação dos últimos 30 dias para o resumo clínico.
final clinicalRecoveryHistoryProvider =
    FutureProvider<List<DailyRecoverySnapshot>>((ref) async {
  final healthService = ref.watch(healthServiceProvider);
  await healthService.initialize();
  return healthService.getRecoveryHistory(days: 30);
});

/// Histórico de ambiente (luz + áudio ambiental/fones) — iOS bridge.
final environmentHistoryProvider =
    FutureProvider<List<DailyEnvironmentSnapshot>>((ref) async {
  final healthService = ref.watch(healthServiceProvider);
  await healthService.initialize();
  return healthService.getEnvironmentHistory(days: 14);
});

/// Histórico de State of Mind do Apple Health (iOS 18+).
final appleStateOfMindHistoryProvider =
    FutureProvider<List<StateOfMindEntry>>((ref) async {
  final healthService = ref.watch(healthServiceProvider);
  await healthService.initialize();
  return healthService.getStateOfMindHistory(days: 14);
});

/// Snapshot de recuperação mais recente
final lastRecoveryProvider =
    Provider<AsyncValue<DailyRecoverySnapshot?>>((ref) {
  final historyAsync = ref.watch(recoveryHistoryProvider);
  return historyAsync.whenData((list) => list.isNotEmpty ? list.first : null);
});

/// Snapshot de ambiente mais recente
final lastEnvironmentProvider =
    Provider<AsyncValue<DailyEnvironmentSnapshot?>>((ref) {
  final historyAsync = ref.watch(environmentHistoryProvider);
  return historyAsync.whenData((list) => list.isNotEmpty ? list.first : null);
});

/// Sono da noite anterior
final lastNightSleepProvider = Provider<AsyncValue<SleepRecord?>>((ref) {
  final historyAsync = ref.watch(sleepHistoryProvider);
  return historyAsync.whenData((list) => list.isNotEmpty ? list.first : null);
});

/// Repositório de Humor e Rotina
final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MoodRepository(prefs);
});

/// Notifier para gerenciar a lista de registros de humor
class MoodEntriesNotifier extends StateNotifier<AsyncValue<List<MoodEntry>>> {
  final MoodRepository _repository;

  MoodEntriesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadEntries();
  }

  Future<void> loadEntries() async {
    try {
      final entries = await _repository.getAllEntries();
      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addEntry({
    required int valence,
    required EnergyLevel energy,
    required FocusState focus,
    required bool tookMedication,
    required bool sensoryOverload,
    String? note,
    Set<String> emotionLabels = const {},
  }) async {
    final newEntry = MoodEntry(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      valence: valence,
      energy: energy,
      focus: focus,
      tookMedication: tookMedication,
      sensoryOverload: sensoryOverload,
      note: note,
      emotionLabels: emotionLabels,
    );

    await _repository.addEntry(newEntry);
    await loadEntries();
  }
}

final moodEntriesProvider =
    StateNotifierProvider<MoodEntriesNotifier, AsyncValue<List<MoodEntry>>>((ref) {
  final repository = ref.watch(moodRepositoryProvider);
  return MoodEntriesNotifier(repository);
});

/// Provedor de Insights de Correlação entre Sono, Recuperação e Sintomas de TDAH
final correlationInsightsProvider = Provider<List<CorrelationInsight>>((ref) {
  final sleepAsync = ref.watch(sleepHistoryProvider);
  final moodAsync = ref.watch(moodEntriesProvider);
  final recoveryAsync = ref.watch(recoveryHistoryProvider);

  final sleepRecords = sleepAsync.asData?.value ?? [];
  final moodEntries = moodAsync.asData?.value ?? [];
  final recoverySnapshots = recoveryAsync.asData?.value ?? [];

  final l10n = ref.watch(appLocalizationsProvider);
  return CorrelationEngine.analyze(
    sleepRecords: sleepRecords,
    moodEntries: moodEntries,
    recoverySnapshots: recoverySnapshots,
    copy: L10nCorrelationCopy(l10n),
  );
});
