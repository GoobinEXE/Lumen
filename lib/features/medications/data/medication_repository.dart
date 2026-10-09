import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/persistence/async_mutex.dart';
import '../../../core/persistence/stored_json.dart';
import '../../../core/time/civil_day.dart';
import '../domain/medication.dart';
import '../domain/medication_log.dart';

class MedicationRepository {
  static const String _medsKey = 'noa_medications_list_v2';
  static const String _logsKey = 'noa_medication_logs_v2';
  final SharedPreferences _prefs;

  /// Blob inteiro ilegível: não sobrescrever. Itens podres só são pulados.
  var _preserveUnreadableMeds = false;
  var _preserveUnreadableLogs = false;

  /// Cache process-wide — UI e handler de notificação compartilham a mesma visão.
  static List<Medication>? _medsCache;
  static List<MedicationLog>? _logsCache;
  static String? _medsRawFingerprint;
  static String? _logsRawFingerprint;

  MedicationRepository(this._prefs);

  Future<T> _synchronized<T>(Future<T> Function() action) =>
      PersistenceLocks.medications.synchronized(action);

  bool _hasStatus(MedicationLog log) =>
      log.isTaken || log.skipped || log.snoozedUntil != null;

  Future<List<Medication>> getMedications() async => _readMeds();

  Future<void> saveMedication(Medication med) {
    return _synchronized(() async {
      final list = List<Medication>.from(await _readMeds());
      final index = list.indexWhere((m) => m.id == med.id);
      if (index >= 0) {
        list[index] = med;
      } else {
        list.add(med);
      }
      await _saveMedications(list);
    });
  }

  Future<void> deleteMedication(String id) {
    return _synchronized(() async {
      final list = await _readMeds();
      await _saveMedications(list.where((m) => m.id != id).toList());
    });
  }

  Future<List<MedicationLog>> getAllLogs() =>
      Future<List<MedicationLog>>.value(_readLogs());

  Future<List<MedicationLog>> getLogsForDate(DateTime date) {
    return _synchronized(() => _getLogsForDate(date));
  }

  /// Leitura do dia sem reconciliar nem gravar (digest / feed).
  Future<List<MedicationLog>> getLogsForDateReadOnly(DateTime date) async {
    final day = civilDay(date);
    return _readLogs()
        .where((log) => isSameCivilDay(log.scheduledTime, day))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  Future<List<MedicationLog>> _getLogsForDate(DateTime date) async {
    final allLogs = _readLogs();
    final meds = await _readMeds();
    if (_preserveUnreadableLogs || _preserveUnreadableMeds) {
      final day = civilDay(date);
      return allLogs.where((log) => isSameCivilDay(log.scheduledTime, day)).toList();
    }
    final day = civilDay(date);
    final medsById = {for (final med in meds) med.id: med};

    final otherDays = <MedicationLog>[];
    final dayLogs = <MedicationLog>[];
    for (final log in allLogs) {
      if (isSameCivilDay(log.scheduledTime, day)) {
        if (medsById.containsKey(log.medicationId)) {
          dayLogs.add(log);
        }
      } else {
        otherDays.add(log);
      }
    }

    final reconciled = alignDayLogs(day, meds, dayLogs);
    final changed =
        reconciled.length != dayLogs.length || !_sameLogList(reconciled, dayLogs);
    final droppedOrphans = allLogs.length != otherDays.length + dayLogs.length;
    if (changed || droppedOrphans) {
      await _saveLogs([...otherDays, ...reconciled]);
    }
    reconciled.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return reconciled;
  }

  /// Reconcilição pura do dia — testável sem SharedPreferences.
  static List<MedicationLog> alignDayLogs(
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
      final wantedKeys = <String>{};
      for (final timeStr in med.scheduledTimes) {
        final scheduled = _timeOnDay(day, timeStr);
        final key = _minuteKey(scheduled);
        if (!wantedKeys.add(key)) continue;
        wanted.add(scheduled);
      }
      wanted.sort();

      final own = dayLogs.where((l) => l.medicationId == med.id).toList();
      final matched = <MedicationLog>[];
      final loose = <MedicationLog>[];
      for (final log in own) {
        final key = _minuteKey(log.scheduledTime);
        if (wantedKeys.contains(key)) {
          matched.add(
            log.medicationName == display
                ? log
                : log.copyWith(medicationName: display),
          );
        } else {
          loose.add(log);
        }
      }

      final matchedKeys = {
        for (final log in matched) _minuteKey(log.scheduledTime),
      };
      final openSlots = wanted
          .where((slot) => !matchedKeys.contains(_minuteKey(slot)))
          .toList();
      final movable =
          loose.where((log) => log.source == MedicationLogSource.lumen).toList()
            ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

      final relocated = <MedicationLog>[];
      final pairCount =
          openSlots.length < movable.length ? openSlots.length : movable.length;
      for (var i = 0; i < pairCount; i++) {
        final log = movable[i];
        relocated.add(
          log.copyWith(medicationName: display, scheduledTime: openSlots[i]),
        );
      }

      final coveredById = <String, MedicationLog>{
        for (final log in matched) log.id: log,
        for (final log in relocated) log.id: log,
      };
      final coveredKeys = {
        for (final log in coveredById.values) _minuteKey(log.scheduledTime),
      };
      for (final slot in wanted) {
        final key = _minuteKey(slot);
        if (coveredKeys.contains(key)) continue;
        final created = MedicationLog(
          id: const Uuid().v4(),
          medicationId: med.id,
          medicationName: display,
          scheduledTime: slot,
        );
        coveredById[created.id] = created;
        coveredKeys.add(key);
      }

      result.addAll(coveredById.values);
      used.addAll(own.map((log) => log.id));

      final resultIds = coveredById.keys.toSet();
      for (final log in movable.skip(pairCount)) {
        if (_staticHasStatus(log)) {
          result.add(
            log.medicationName == display
                ? log
                : log.copyWith(medicationName: display),
          );
          resultIds.add(log.id);
        }
      }
      for (final log in loose) {
        if (log.source == MedicationLogSource.appleHealth &&
            !resultIds.contains(log.id)) {
          result.add(log);
          resultIds.add(log.id);
        }
      }
    }

    final medIds = {for (final med in meds) med.id};
    for (final log in dayLogs) {
      if (used.contains(log.id)) continue;
      if (!medIds.contains(log.medicationId)) continue;
      if (_staticHasStatus(log)) result.add(log);
    }

    return result;
  }

  static bool _staticHasStatus(MedicationLog log) =>
      log.isTaken || log.skipped || log.snoozedUntil != null;

  static String _minuteKey(DateTime t) =>
      '${t.year}-${t.month}-${t.day} ${t.hour}:${t.minute}';

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

  static DateTime _timeOnDay(DateTime day, String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final min = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return DateTime(day.year, day.month, day.day, hour, min);
  }

  Future<void> reload() async {
    await _prefs.reload();
    _medsCache = null;
    _logsCache = null;
    _medsRawFingerprint = null;
    _logsRawFingerprint = null;
  }

  Future<MedicationLog> ensureDoseLog({
    required String medicationId,
    required String medicationName,
    required DateTime scheduled,
  }) {
    return _synchronized(() async {
      final allLogs = List<MedicationLog>.from(_readLogs());
      for (final log in allLogs) {
        if (log.medicationId == medicationId &&
            _sameMinute(log.scheduledTime, scheduled)) {
          return log;
        }
      }

      final sameDay = allLogs
          .where(
            (log) =>
                log.medicationId == medicationId &&
                log.source == MedicationLogSource.lumen &&
                isSameCivilDay(log.scheduledTime, scheduled),
          )
          .toList();
      final statusful = sameDay.where(_hasStatus).toList();
      if (statusful.length == 1) return statusful.first;
      if (sameDay.length == 1) return sameDay.first;

      final created = MedicationLog(
        id: const Uuid().v4(),
        medicationId: medicationId,
        medicationName: medicationName,
        scheduledTime: scheduled,
      );
      allLogs.add(created);
      await _saveLogs(allLogs);
      return created;
    });
  }

  Future<MedicationLog?> logById(String id) async {
    for (final log in _readLogs()) {
      if (log.id == id) return log;
    }
    return null;
  }

  Future<void> markAsTaken(String logId, DateTime takenAt) {
    return _synchronized(() async {
      final allLogs = List<MedicationLog>.from(_readLogs());
      final index = allLogs.indexWhere((l) => l.id == logId);
      if (index < 0) return;
      final log = allLogs[index];
      if (log.isTaken) return;
      allLogs[index] = log.copyWith(
        takenAt: takenAt,
        skipped: false,
        snoozedUntil: null,
      );
      await _saveLogs(allLogs);

      final meds = List<Medication>.from(await _readMeds());
      final medIndex = meds.indexWhere((m) => m.id == log.medicationId);
      if (medIndex >= 0) {
        final med = meds[medIndex];
        if (med.remainingStock > 0) {
          meds[medIndex] = med.copyWith(
            remainingStock: med.remainingStock - 1,
          );
          await _saveMedications(meds);
        }
      }
    });
  }

  Future<void> snoozeLog(String logId, int minutes) {
    return _synchronized(() async {
      final allLogs = List<MedicationLog>.from(_readLogs());
      final index = allLogs.indexWhere((l) => l.id == logId);
      if (index < 0) return;
      final snoozed = DateTime.now().add(Duration(minutes: minutes));
      allLogs[index] = allLogs[index].copyWith(snoozedUntil: snoozed);
      await _saveLogs(allLogs);
    });
  }

  Future<void> skipLog(String logId, String reason) {
    return _synchronized(() async {
      final allLogs = List<MedicationLog>.from(_readLogs());
      final index = allLogs.indexWhere((l) => l.id == logId);
      if (index < 0) return;
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
    });
  }

  Future<void> addExternalLog(MedicationLog log) {
    return _synchronized(() async {
      final allLogs = List<MedicationLog>.from(_readLogs());
      final exists = allLogs.any(
        (l) =>
            l.medicationId == log.medicationId &&
            _sameMinute(l.scheduledTime, log.scheduledTime),
      );
      if (exists) return;
      allLogs.add(log);
      await _saveLogs(allLogs);
    });
  }

  bool _sameMinute(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  Future<List<Medication>> _readMeds() async {
    final raw = _prefs.getString(_medsKey);
    final fingerprint = raw ?? '';
    final cached = _medsCache;
    if (cached != null && _medsRawFingerprint == fingerprint) return cached;

    final read = decodeStoredJsonList<Medication>(
      raw,
      (map) {
        try {
          return Medication.fromMap(map);
        } catch (_) {
          return null;
        }
      },
    );
    if (read.unreadable) {
      _preserveUnreadableMeds = true;
      _medsCache = const [];
      _medsRawFingerprint = fingerprint;
      return _medsCache!;
    }
    _preserveUnreadableMeds = false;
    _medsCache = read.items;
    _medsRawFingerprint = fingerprint;
    return read.items;
  }

  List<MedicationLog> _readLogs() {
    final raw = _prefs.getString(_logsKey);
    final fingerprint = raw ?? '';
    final cached = _logsCache;
    if (cached != null && _logsRawFingerprint == fingerprint) return cached;

    final read = decodeStoredJsonList<MedicationLog>(
      raw,
      (map) {
        try {
          return MedicationLog.fromMap(map);
        } catch (_) {
          return null;
        }
      },
    );
    if (read.unreadable) {
      _preserveUnreadableLogs = true;
      _logsCache = const [];
      _logsRawFingerprint = fingerprint;
      return _logsCache!;
    }
    _preserveUnreadableLogs = false;
    _logsCache = read.items;
    _logsRawFingerprint = fingerprint;
    return read.items;
  }

  Future<void> _saveMedications(List<Medication> list) async {
    if (_preserveUnreadableMeds) return;
    final encoded = encodeStoredJsonList(list.map((m) => m.toMap()));
    await _prefs.setString(_medsKey, encoded);
    _medsCache = List<Medication>.from(list);
    _medsRawFingerprint = encoded;
  }

  Future<void> _saveLogs(List<MedicationLog> list) async {
    if (_preserveUnreadableLogs) return;
    final encoded = encodeStoredJsonList(list.map((l) => l.toMap()));
    await _prefs.setString(_logsKey, encoded);
    _logsCache = List<MedicationLog>.from(list);
    _logsRawFingerprint = encoded;
  }
}
