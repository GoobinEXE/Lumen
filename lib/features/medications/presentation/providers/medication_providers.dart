import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../integrations/healthkit_bridge/healthkit_bridge.dart';
import '../../data/medication_repository.dart';
import '../../domain/medication.dart';
import '../../domain/medication_log.dart';
import '../../service/medication_notification_bus.dart';
import '../../service/medication_reminder_service.dart';
import '../../../../core/providers.dart';

final medicationReminderServiceProvider = Provider<MedicationReminderService>((
  ref,
) {
  return MedicationReminderService(ref.watch(sharedPreferencesProvider));
});

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MedicationRepository(prefs);
});

final medicationsListProvider = FutureProvider<List<Medication>>((ref) async {
  final repo = ref.watch(medicationRepositoryProvider);
  return repo.getMedications();
});

final appleHealthMedsAvailableProvider = FutureProvider<bool>((ref) async {
  final health = ref.watch(healthServiceProvider);
  await health.initialize();
  return health.isMedicationsApiAvailable();
});

/// Mescla dose events do Apple Health em MedicationLog (somente leitura).
List<MedicationLog> mergeDoseEventsIntoLogs({
  required String medicationId,
  required String medicationName,
  required List<MedicationLog> existing,
  required List<HealthKitDoseEvent> events,
}) {
  final result = List<MedicationLog>.from(existing);
  for (final event in events) {
    if (event.status != 'taken' && event.status != 'skipped') continue;
    final already = result.any(
      (l) =>
          l.medicationId == medicationId &&
          _sameMinute(l.scheduledTime, event.loggedAt),
    );
    if (already) continue;
    result.add(
      MedicationLog(
        id: 'apple_${event.loggedAt.millisecondsSinceEpoch}_$medicationId',
        medicationId: medicationId,
        medicationName: medicationName,
        scheduledTime: event.loggedAt,
        takenAt: event.status == 'taken' ? event.loggedAt : null,
        skipped: event.status == 'skipped',
        source: MedicationLogSource.appleHealth,
      ),
    );
  }
  return result;
}

bool _sameMinute(DateTime a, DateTime b) {
  return a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;
}

class TodayMedicationLogsNotifier
    extends StateNotifier<AsyncValue<List<MedicationLog>>> {
  final MedicationRepository _repository;
  final MedicationReminderService _reminderService;
  final Ref _ref;

  bool _checkedSchedule = false;

  TodayMedicationLogsNotifier(
    this._repository,
    this._reminderService,
    this._ref,
  ) : super(const AsyncValue.loading()) {
    MedicationNotificationBus.doseChanged.addListener(_onExternalDose);
    _ref.listen(appLocalizationsProvider, (previous, next) {
      if (previous == null || previous.localeName == next.localeName) return;
      _checkedSchedule = false;
      loadTodayLogs();
    });
    loadTodayLogs();
  }

  @override
  void dispose() {
    MedicationNotificationBus.doseChanged.removeListener(_onExternalDose);
    super.dispose();
  }

  void _onExternalDose() {
    _ref.invalidate(medicationsListProvider);
    loadTodayLogs();
  }

  Future<void> loadTodayLogs() async {
    try {
      await _repository.reload();
      final logs = await _repository.getLogsForDate(DateTime.now());
      if (!mounted) return;
      state = AsyncValue.data(logs);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
    if (!mounted || _checkedSchedule) return;
    _checkedSchedule = true;
    try {
      final meds = await _repository.getMedications();
      // Não aguardar: fuso/plugin podem nunca completar em teste.
      unawaited(
        _reminderService.syncIfNeeded(
          meds,
          _ref.read(appLocalizationsProvider),
        ).catchError((Object e) {
          _checkedSchedule = false;
          debugPrint('[Medications] lembretes: $e');
        }),
      );
    } catch (e) {
      _checkedSchedule = false;
      debugPrint('[Medications] lembretes: $e');
    }
  }

  Future<void> markTaken(String logId) async {
    final now = DateTime.now();
    await _repository.reload();
    await _repository.markAsTaken(logId, now);
    await _reminderService.cancelSnooze(logId);
    // Plano: doses no Health são read-only — não escrevemos de volta.
    await loadTodayLogs();
  }

  Future<void> snooze(
    String logId,
    String medicationName, {
    int minutes = 15,
  }) async {
    await _repository.reload();
    await _repository.snoozeLog(logId, minutes);
    final log = await _repository.logById(logId);
    final l10n = _ref.read(appLocalizationsProvider);
    if (log != null) {
      final scheduled = log.scheduledTime;
      final time =
          '${scheduled.hour.toString().padLeft(2, '0')}:${scheduled.minute.toString().padLeft(2, '0')}';
      await _reminderService.scheduleSnooze(
        l10n: l10n,
        logId: logId,
        medicationId: log.medicationId,
        medicationName: medicationName,
        time: time,
        minutes: minutes,
      );
    }
    await loadTodayLogs();
  }

  Future<void> skip(String logId, String reason) async {
    await _repository.skipLog(logId, reason);
    await _reminderService.cancelSnooze(logId);
    await loadTodayLogs();
  }

  Future<void> saveMedication(Medication med) async {
    await _repository.saveMedication(med);
    await _syncReminders();
    _ref.invalidate(medicationsListProvider);
    await loadTodayLogs();
  }

  Future<void> deleteMedication(String id) async {
    await _repository.deleteMedication(id);
    await _syncReminders();
    _ref.invalidate(medicationsListProvider);
    await loadTodayLogs();
  }

  Future<void> _syncReminders() async {
    try {
      final meds = await _repository.getMedications();
      await _reminderService.syncAll(meds, _ref.read(appLocalizationsProvider));
      _checkedSchedule = true;
    } catch (e) {
      debugPrint('[Medications] lembretes: $e');
    }
  }

  /// Importa/vincula medicamentos do Apple Health (leitura).
  Future<int> importFromAppleHealth() async {
    final health = _ref.read(healthServiceProvider);
    await health.initialize();
    final remote = await health.readMedications();
    if (remote.isEmpty) return 0;

    final existing = await _repository.getMedications();
    var imported = 0;
    for (final info in remote) {
      if (!info.isActive) continue;

      final byConcept = existing.where(
        (m) => m.appleConceptId == info.appleConceptId,
      );
      final byName = existing.where(
        (m) =>
            m.name.toLowerCase() == info.name.toLowerCase() ||
            (info.nickname != null &&
                m.name.toLowerCase() == info.nickname!.toLowerCase()),
      );

      Medication med;
      if (byConcept.isNotEmpty) {
        med = byConcept.first.copyWith(
          rxNormCode: info.rxNormCode ?? byConcept.first.rxNormCode,
          source: MedicationSource.linked,
        );
        await _repository.saveMedication(med);
      } else if (byName.isNotEmpty) {
        med = byName.first.copyWith(
          appleConceptId: info.appleConceptId,
          rxNormCode: info.rxNormCode,
          source: MedicationSource.linked,
        );
        await _repository.saveMedication(med);
        imported++;
      } else {
        final l10n = _ref.read(appLocalizationsProvider);
        med = Medication(
          id: const Uuid().v4(),
          name: info.nickname?.isNotEmpty == true ? info.nickname! : info.name,
          dosage: info.form ?? l10n.defaultDoseFallback,
          scheduledTimes: const ['08:00'],
          instructions: l10n.defaultMedInstructions,
          appleConceptId: info.appleConceptId,
          rxNormCode: info.rxNormCode,
          source: MedicationSource.appleHealth,
        );
        await _repository.saveMedication(med);
        imported++;
      }

      final start = DateTime.now().subtract(const Duration(days: 7));
      final events = await health.readDoseEvents(
        appleConceptId: info.appleConceptId,
        start: start,
        end: DateTime.now(),
      );
      final existingLogs = await _repository.getLogsForDate(DateTime.now());
      final merged = mergeDoseEventsIntoLogs(
        medicationId: med.id,
        medicationName: med.name,
        existing: existingLogs,
        events: events,
      );
      for (final log in merged) {
        if (log.source == MedicationLogSource.appleHealth &&
            !existingLogs.any((e) => e.id == log.id)) {
          await _repository.addExternalLog(log);
        }
      }
    }
    _ref.invalidate(medicationsListProvider);
    await _syncReminders();
    await loadTodayLogs();
    return imported;
  }

  /// Atualiza doses do Health ao abrir a tela (evita dados stale).
  Future<void> refreshAppleHealthDoses() async {
    try {
      final health = _ref.read(healthServiceProvider);
      await health.initialize();
      final available = await health.isMedicationsApiAvailable();
      if (!available) return;
      final meds = await _repository.getMedications();
      final linked = meds
          .where((m) => m.isLinkedToAppleHealth)
          .toList(growable: false);
      if (linked.isEmpty) return;

      final start = DateTime.now().subtract(const Duration(days: 2));
      final end = DateTime.now();
      for (final med in linked) {
        final events = await health.readDoseEvents(
          appleConceptId: med.appleConceptId!,
          start: start,
          end: end,
        );
        if (events.isEmpty) continue;
        final existing = await _repository.getLogsForDate(DateTime.now());
        final merged = mergeDoseEventsIntoLogs(
          medicationId: med.id,
          medicationName: med.name,
          existing: existing,
          events: events,
        );
        for (final log in merged) {
          if (log.source == MedicationLogSource.appleHealth &&
              !existing.any((e) => e.id == log.id)) {
            await _repository.addExternalLog(log);
          }
        }
      }
      await loadTodayLogs();
    } catch (e) {
      debugPrint('[Medications] refreshAppleHealthDoses: $e');
    }
  }
}

final todayMedicationLogsProvider =
    StateNotifierProvider<
      TodayMedicationLogsNotifier,
      AsyncValue<List<MedicationLog>>
    >((ref) {
      final repo = ref.watch(medicationRepositoryProvider);
      final reminder = ref.watch(medicationReminderServiceProvider);
      return TodayMedicationLogsNotifier(repo, reminder, ref);
    });
