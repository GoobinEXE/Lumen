import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../domain/medication.dart';
import '../domain/medication_log.dart';

class MedicationRepository {
  static const String _medsKey = 'noa_medications_list_v2';
  static const String _logsKey = 'noa_medication_logs_v2';
  final SharedPreferences _prefs;

  MedicationRepository(this._prefs);

  /// Retorna os medicamentos cadastrados
  Future<List<Medication>> getMedications() async {
    final raw = _prefs.getString(_medsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Medication.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMedication(Medication med) async {
    final list = await getMedications();
    final index = list.indexWhere((m) => m.id == med.id);
    if (index >= 0) {
      list[index] = med;
    } else {
      list.add(med);
    }
    await _saveMedications(list);
  }

  Future<void> deleteMedication(String id) async {
    final list = await getMedications();
    list.removeWhere((m) => m.id == id);
    await _saveMedications(list);
  }

  /// Alinha os logs do dia ao cadastro: cria o que falta, tira órfão e horário que saiu.
  Future<List<MedicationLog>> getLogsForDate(DateTime date) async {
    final allLogs = await _getAllLogs();
    final meds = await getMedications();
    final day = DateTime(date.year, date.month, date.day);
    final medsById = {for (final med in meds) med.id: med};

    final otherDays = <MedicationLog>[];
    final dayLogs = <MedicationLog>[];
    for (final log in allLogs) {
      if (_sameDay(log.scheduledTime, day)) {
        if (medsById.containsKey(log.medicationId)) {
          dayLogs.add(log);
        }
      } else {
        otherDays.add(log);
      }
    }

    final reconciled = _alignDayLogs(day, meds, dayLogs);
    final changed =
        reconciled.length != dayLogs.length ||
        !_sameLogList(reconciled, dayLogs);
    if (changed || allLogs.length != otherDays.length + dayLogs.length) {
      await _saveLogs([...otherDays, ...reconciled]);
    }
    reconciled.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return reconciled;
  }

  List<MedicationLog> _alignDayLogs(
    DateTime day,
    List<Medication> meds,
    List<MedicationLog> dayLogs,
  ) {
    final result = <MedicationLog>[];
    final used = <String>{};

    for (final med in meds.where((m) => m.active)) {
      if (!med.daysOfWeek.contains(day.weekday)) continue;
      final display = '${med.name} ${med.dosage}';
      final wanted = <DateTime>[];
      for (final timeStr in med.scheduledTimes) {
        final scheduled = _timeOnDay(day, timeStr);
        if (wanted.any((slot) => _sameMinute(slot, scheduled))) continue;
        wanted.add(scheduled);
      }
      wanted.sort();

      final own = dayLogs.where((l) => l.medicationId == med.id).toList();
      final matched = <MedicationLog>[];
      final loose = <MedicationLog>[];
      for (final log in own) {
        final hit = wanted.any((slot) => _sameMinute(slot, log.scheduledTime));
        if (hit) {
          matched.add(
            log.medicationName == display
                ? log
                : log.copyWith(medicationName: display),
          );
        } else {
          loose.add(log);
        }
      }

      final openSlots = wanted
          .where(
            (slot) =>
                !matched.any((log) => _sameMinute(log.scheduledTime, slot)),
          )
          .toList();
      // Dose já tomada ou pulada fica no horário em que aconteceu.
      // Só a pendente acompanha um horário novo da agenda.
      final movable =
          loose
              .where(
                (log) =>
                    log.source == MedicationLogSource.lumen &&
                    !log.isTaken &&
                    !log.skipped,
              )
              .toList()
            ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

      final relocated = <MedicationLog>[];
      final pairCount = openSlots.length < movable.length
          ? openSlots.length
          : movable.length;
      for (var i = 0; i < pairCount; i++) {
        final log = movable[i];
        relocated.add(
          log.copyWith(medicationName: display, scheduledTime: openSlots[i]),
        );
      }

      final covered = {...matched, ...relocated};
      for (final slot in wanted) {
        if (covered.any((log) => _sameMinute(log.scheduledTime, slot))) {
          continue;
        }
        covered.add(
          MedicationLog(
            id: const Uuid().v4(),
            medicationId: med.id,
            medicationName: display,
            scheduledTime: slot,
          ),
        );
      }

      result.addAll(covered);
      used.addAll(own.map((log) => log.id));

      for (final log in loose) {
        if (log.source != MedicationLogSource.lumen) continue;
        if (!log.isTaken && !log.skipped) continue;
        if (result.any((kept) => kept.id == log.id)) continue;
        result.add(
          log.medicationName == display
              ? log
              : log.copyWith(medicationName: display),
        );
      }
      for (final log in loose) {
        if (log.source == MedicationLogSource.appleHealth &&
            !result.any((kept) => kept.id == log.id)) {
          result.add(log);
        }
      }
    }

    for (final log in dayLogs) {
      if (used.contains(log.id)) continue;
      if (!meds.any((med) => med.id == log.medicationId)) continue;
      if (log.isTaken || log.skipped) result.add(log);
    }

    return result;
  }

  bool _sameLogList(List<MedicationLog> a, List<MedicationLog> b) {
    if (a.length != b.length) return false;
    final byId = {for (final log in b) log.id: log};
    for (final log in a) {
      final other = byId[log.id];
      if (other == null) return false;
      if (other.medicationName != log.medicationName) return false;
      if (!_sameMinute(other.scheduledTime, log.scheduledTime)) return false;
      if (other.takenAt != log.takenAt) return false;
      if (other.skipped != log.skipped) return false;
    }
    return true;
  }

  bool _sameDay(DateTime a, DateTime day) {
    return a.year == day.year && a.month == day.month && a.day == day.day;
  }

  DateTime _timeOnDay(DateTime day, String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final min = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return DateTime(day.year, day.month, day.day, hour, min);
  }

  Future<void> reload() => _prefs.reload();

  /// Garante um log do dia para a dose, para as ações da notificação.
  Future<MedicationLog> ensureDoseLog({
    required String medicationId,
    required String medicationName,
    required DateTime scheduled,
  }) async {
    final allLogs = await _getAllLogs();
    for (final log in allLogs) {
      if (log.medicationId == medicationId &&
          _sameMinute(log.scheduledTime, scheduled)) {
        return log;
      }
    }

    final created = MedicationLog(
      id: const Uuid().v4(),
      medicationId: medicationId,
      medicationName: medicationName,
      scheduledTime: scheduled,
    );
    allLogs.add(created);
    await _saveLogs(allLogs);
    return created;
  }

  Future<MedicationLog?> logById(String id) async {
    final allLogs = await _getAllLogs();
    for (final log in allLogs) {
      if (log.id == id) return log;
    }
    return null;
  }

  /// Confirma a tomada da dose e decrementa o estoque do medicamento
  Future<void> markAsTaken(String logId, DateTime takenAt) async {
    final allLogs = await _getAllLogs();
    final index = allLogs.indexWhere((l) => l.id == logId);
    if (index >= 0) {
      final log = allLogs[index];
      if (log.isTaken) return;
      allLogs[index] = log.copyWith(
        takenAt: takenAt,
        skipped: false,
        snoozedUntil: null,
      );
      await _saveLogs(allLogs);

      // Decrementar estoque do medicamento correspondente
      final meds = await getMedications();
      final medIndex = meds.indexWhere((m) => m.id == log.medicationId);
      if (medIndex >= 0) {
        final med = meds[medIndex];
        if (med.remainingStock > 0) {
          meds[medIndex] = med.copyWith(remainingStock: med.remainingStock - 1);
          await _saveMedications(meds);
        }
      }
    }
  }

  /// Adia a dose por X minutos
  Future<void> snoozeLog(String logId, int minutes) async {
    final allLogs = await _getAllLogs();
    final index = allLogs.indexWhere((l) => l.id == logId);
    if (index >= 0) {
      final snoozed = DateTime.now().add(Duration(minutes: minutes));
      allLogs[index] = allLogs[index].copyWith(snoozedUntil: snoozed);
      await _saveLogs(allLogs);
    }
  }

  /// Marca como pulado e solta o adiamento. copyWith não zera snoozedUntil.
  Future<void> skipLog(String logId, String reason) async {
    final allLogs = await _getAllLogs();
    final index = allLogs.indexWhere((l) => l.id == logId);
    if (index >= 0) {
      final log = allLogs[index];
      allLogs[index] = MedicationLog(
        id: log.id,
        medicationId: log.medicationId,
        medicationName: log.medicationName,
        scheduledTime: log.scheduledTime,
        takenAt: log.takenAt,
        skipped: true,
        skipReason: reason,
        source: log.source,
      );
      await _saveLogs(allLogs);
    }
  }

  /// Insere log externo (ex.: dose importada do Apple Health) sem mexer no estoque.
  Future<void> addExternalLog(MedicationLog log) async {
    final allLogs = await _getAllLogs();
    final exists = allLogs.any(
      (l) =>
          l.medicationId == log.medicationId &&
          l.scheduledTime.millisecondsSinceEpoch ==
              log.scheduledTime.millisecondsSinceEpoch &&
          l.source == MedicationLogSource.appleHealth,
    );
    if (exists) return;
    allLogs.add(log);
    await _saveLogs(allLogs);
  }

  bool _sameMinute(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  Future<List<MedicationLog>> _getAllLogs() async {
    final raw = _prefs.getString(_logsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => MedicationLog.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveMedications(List<Medication> list) async {
    final raw = jsonEncode(list.map((m) => m.toMap()).toList());
    await _prefs.setString(_medsKey, raw);
  }

  Future<void> _saveLogs(List<MedicationLog> list) async {
    final raw = jsonEncode(list.map((l) => l.toMap()).toList());
    await _prefs.setString(_logsKey, raw);
  }
}
