import 'package:noa/l10n/app_localizations.dart';

import '../../features/state_of_mind/domain/state_of_mind_entry.dart';
import '../healthkit_bridge/healthkit_bridge.dart';
import 'health_app_connector.dart';
import 'health_app_source.dart';
import 'health_capability.dart';
import 'health_connector_selector.dart';
import 'health_service.dart';
import 'models/daily_environment_snapshot.dart';
import 'models/daily_recovery_snapshot.dart';
import 'models/health_demographics.dart';
import 'models/sleep_record.dart';

/// Facade de produto: escolhe connectors e faz fallback por capability.
class FacadeHealthService implements HealthService {
  FacadeHealthService({HealthConnectorSelector? selector})
      : _selector = selector ?? HealthConnectorSelector();

  final HealthConnectorSelector _selector;

  HealthAppConnector? _primary;
  HealthAppConnector? _fallback;
  bool _resolved = false;

  @override
  HealthAppSource get activeSource =>
      _primary?.source ?? HealthAppSource.healthConnect;

  @override
  bool get shouldGuideToHealthConnect =>
      activeSource == HealthAppSource.healthConnect;

  Future<void> _ensureResolved() async {
    if (_resolved) return;
    final selected = await _selector.resolve();
    _primary = selected.primary;
    _fallback = selected.fallback;
    _resolved = true;
  }

  HealthAppConnector? _forCapability(HealthCapability capability) {
    final primary = _primary;
    if (primary != null && primary.supports(capability)) return primary;
    final fallback = _fallback;
    if (fallback != null && fallback.supports(capability)) return fallback;
    return primary;
  }

  @override
  Future<void> initialize() async {
    await _ensureResolved();
    await _primary?.initialize();
    await _fallback?.initialize();
  }

  @override
  Future<bool> requestPermissions() async {
    await initialize();
    final primary = _primary;
    if (primary == null) return false;

    var granted = await primary.requestPermissions();
    // Samsung sem SDK linkado: permissões passam pelo Health Connect.
    if (!granted && _fallback != null) {
      granted = await _fallback!.requestPermissions();
    } else if (granted &&
        _fallback != null &&
        primary.source == HealthAppSource.samsungHealth) {
      // Gaps (ex.: HRV) precisam de permissão no HC também.
      await _fallback!.requestPermissions();
    }
    return granted;
  }

  @override
  Future<bool> hasPermissions() async {
    await _ensureResolved();
    final primary = await _primary?.hasPermissions() ?? false;
    if (primary) return true;
    return await _fallback?.hasPermissions() ?? false;
  }

  @override
  Future<List<SleepRecord>> syncFromHealth({int days = 14}) async {
    await initialize();
    final granted = await requestPermissions();
    if (!granted) return [];
    return getSleepHistory(days: days);
  }

  @override
  Future<SleepRecord?> getLastNightSleep() async {
    final history = await getSleepHistory(days: 1);
    return history.isNotEmpty ? history.first : null;
  }

  @override
  Future<List<SleepRecord>> getSleepHistory({int days = 7}) async {
    await _ensureResolved();
    final connector = _forCapability(HealthCapability.sleep);
    final result = await connector?.getSleepHistory(days: days) ?? const [];
    if (result.isNotEmpty) return result;
    if (connector != _fallback && _fallback != null) {
      return _fallback!.getSleepHistory(days: days);
    }
    return result;
  }

  @override
  Future<List<DailyRecoverySnapshot>> getRecoveryHistory({
    int days = 14,
  }) async {
    await _ensureResolved();
    final primary = _primary;
    final fallback = _fallback;

    final primaryList =
        await primary?.getRecoveryHistory(days: days) ?? const [];
    if (fallback == null) return primaryList;

    // Mescla gaps (ex.: HRV só no HC) quando Samsung é primary.
    final fallbackList = await fallback.getRecoveryHistory(days: days);
    if (primaryList.isEmpty) return fallbackList;
    if (fallbackList.isEmpty) return primaryList;

    String dayKey(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final byKey = {for (final s in primaryList) dayKey(s.date): s};
    for (final f in fallbackList) {
      final key = dayKey(f.date);
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = f;
        continue;
      }
      byKey[key] = existing.copyWith(
        hrvMs: existing.hrvMs ?? f.hrvMs,
        restingHeartRate: existing.restingHeartRate ?? f.restingHeartRate,
        steps: existing.steps ?? f.steps,
        exerciseMinutes: existing.exerciseMinutes ?? f.exerciseMinutes,
      );
    }
    return byKey.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<List<DailyEnvironmentSnapshot>> getEnvironmentHistory({
    int days = 14,
  }) async {
    await _ensureResolved();
    final connector = _forCapability(HealthCapability.environment);
    return connector?.getEnvironmentHistory(days: days) ?? const [];
  }

  @override
  Future<HealthDemographics> readDemographics() async {
    await _ensureResolved();
    final connector = _forCapability(HealthCapability.demographics);
    var result =
        await connector?.readDemographics() ?? HealthDemographics.empty;
    if (result.isEmpty &&
        connector != _fallback &&
        _fallback != null &&
        _fallback!.supports(HealthCapability.demographics)) {
      result = await _fallback!.readDemographics();
    }
    return result;
  }

  @override
  Future<bool> writeWaterIntake({
    required DateTime when,
    required double liters,
  }) async {
    await _ensureResolved();
    final connector = _forCapability(HealthCapability.waterWrite);
    final ok = await connector?.writeWaterIntake(when: when, liters: liters) ??
        false;
    if (ok) return true;
    if (connector != _fallback &&
        _fallback != null &&
        _fallback!.supports(HealthCapability.waterWrite)) {
      return _fallback!.writeWaterIntake(when: when, liters: liters);
    }
    return false;
  }

  @override
  Future<bool> writeMindfulnessSession({
    required DateTime start,
    required DateTime end,
  }) async {
    await _ensureResolved();
    final connector = _forCapability(HealthCapability.mindfulnessWrite);
    final ok = await connector?.writeMindfulnessSession(
          start: start,
          end: end,
        ) ??
        false;
    if (ok) return true;
    if (connector != _fallback &&
        _fallback != null &&
        _fallback!.supports(HealthCapability.mindfulnessWrite)) {
      return _fallback!.writeMindfulnessSession(start: start, end: end);
    }
    return false;
  }

  @override
  Future<bool> writeStateOfMind(StateOfMindEntry entry) async {
    await _ensureResolved();
    final connector = _forCapability(HealthCapability.stateOfMind);
    return connector?.writeStateOfMind(entry) ?? false;
  }

  @override
  Future<List<StateOfMindEntry>> getStateOfMindHistory({int days = 14}) async {
    await _ensureResolved();
    final connector = _forCapability(HealthCapability.stateOfMind);
    return connector?.getStateOfMindHistory(days: days) ?? const [];
  }

  @override
  Future<bool> isMedicationsApiAvailable() async {
    await _ensureResolved();
    final connector = _forCapability(HealthCapability.medications);
    return connector?.isMedicationsApiAvailable() ?? false;
  }

  @override
  Future<List<HealthKitMedicationInfo>> readMedications() async {
    await _ensureResolved();
    final connector = _forCapability(HealthCapability.medications);
    return connector?.readMedications() ?? const [];
  }

  @override
  Future<List<HealthKitDoseEvent>> readDoseEvents({
    required String appleConceptId,
    required DateTime start,
    required DateTime end,
  }) async {
    await _ensureResolved();
    final connector = _forCapability(HealthCapability.medications);
    return connector?.readDoseEvents(
          appleConceptId: appleConceptId,
          start: start,
          end: end,
        ) ??
        const [];
  }

  @override
  String sourceName(AppLocalizations l10n) {
    final primary = _primary;
    if (primary == null) return l10n.healthSourceUnavailable;
    // Samsung detectado mas sem SDK: rótulo Samsung + dados via HC.
    if (primary.source == HealthAppSource.samsungHealth &&
        !primary.supports(HealthCapability.sleep) &&
        _fallback != null) {
      return l10n.healthSourceSamsung;
    }
    return primary.sourceName(l10n);
  }
}
