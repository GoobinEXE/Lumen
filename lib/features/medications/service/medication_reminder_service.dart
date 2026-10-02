import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/medication_repository.dart';
import '../domain/medication.dart';
import '../domain/medication_log.dart';
import 'medication_notification_bus.dart';
import 'reminder_schedule.dart';

const _scheduleKey = 'noa_med_reminder_schedule_v1';
const _exactPromptedKey = 'noa_exact_alarm_prompted';
const _fullScreenPromptedKey = 'noa_full_screen_intent_prompted';
const _localePrefKey = 'noa_preferred_locale_code';

/// Ponto de entrada do isolate de fundo. Precisa ser função de topo.
@pragma('vm:entry-point')
void medicationReminderBackground(NotificationResponse response) {
  WidgetsFlutterBinding.ensureInitialized();
  MedicationReminderService.handleBackgroundResponse(response);
}

class MedicationReminderService {
  MedicationReminderService(this._prefs);

  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void>? _initializing;
  String? _localeCode;
  AppLocalizations? _l10n;
  Future<void> _queue = Future<void>.value();
  static bool _timeZoneReady = false;

  static Future<void> consumeLaunch() async {
    try {
      final details = await FlutterLocalNotificationsPlugin()
          .getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return;
      final response = details.notificationResponse;
      if (response == null) return;

      final intent = reminderLaunchIntent(
        dismissed:
            response.notificationResponseType ==
            NotificationResponseType.notificationDismissed,
        selectedAction:
            response.notificationResponseType ==
            NotificationResponseType.selectedNotificationAction,
        actionId: response.actionId,
        payload: response.payload,
      );
      switch (intent) {
        case ReminderLaunchIntent.ignore:
          return;
        case ReminderLaunchIntent.openMedications:
          MedicationNotificationBus.requestOpenMedications();
          return;
        case ReminderLaunchIntent.taken:
        case ReminderLaunchIntent.snooze:
          final prefs = await SharedPreferences.getInstance();
          final l10n = lookupAppLocalizations(localeFromReminderPrefs(prefs));
          final service = MedicationReminderService(prefs);
          await service.initialize(l10n);
          await service.applyResponse(response, l10n, notifyUi: false);
      }
    } catch (e) {
      debugPrint('[MedicationReminder] abertura: $e');
    }
  }

  static Future<void> handleBackgroundResponse(
    NotificationResponse response,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final l10n = lookupAppLocalizations(localeFromReminderPrefs(prefs));
      final service = MedicationReminderService(prefs);
      await service.initialize(l10n);
      await service.applyResponse(response, l10n, notifyUi: false);
    } catch (e) {
      debugPrint('[MedicationReminder] fundo: $e');
    }
  }

  Future<void> initialize(AppLocalizations l10n) {
    final code = l10n.localeName.split('_').first;
    if (_initializing != null && _localeCode == code) return _initializing!;
    _localeCode = code;
    _l10n = l10n;
    final future = _configure(l10n, code);
    _initializing = future;
    return future;
  }

  Future<void> syncIfNeeded(List<Medication> meds, AppLocalizations l10n) {
    return _locked(() => _sync(meds, l10n, force: false));
  }

  Future<void> syncAll(List<Medication> meds, AppLocalizations l10n) {
    return _locked(() => _sync(meds, l10n, force: true));
  }

  Future<void> scheduleSnooze({
    required AppLocalizations l10n,
    required String logId,
    required String medicationId,
    required String medicationName,
    required String time,
    int minutes = 15,
  }) {
    return _locked(() async {
      await initialize(l10n);
      await _ensureTimeZone();
      final mode = await _androidMode(prompt: false);
      final id = snoozeNotificationId(logId);
      final when = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));
      await _zoned(
        id: id,
        title: l10n.medSnoozeNotificationTitle(medicationName),
        body: l10n.medSnoozeNotificationBody(minutes),
        when: when,
        payload: ReminderPayload(
          kind: medicationSnoozeKind,
          medicationId: medicationId,
          name: medicationName,
          time: time,
          logId: logId,
          minutes: minutes,
        ).encode(),
        mode: mode,
        repeating: false,
        details: _details(l10n),
      );
      final stored = _read();
      final snoozes =
          stored.snoozes.where((item) => item.logId != logId).toList()
            ..add(_Snooze(id: id, medicationId: medicationId, logId: logId));
      await _write(stored.copyWith(snoozes: snoozes));
    });
  }

  Future<void> cancelSnooze(String logId) {
    return _locked(() async {
      final stored = _read();
      final match = stored.snoozes.where((item) => item.logId == logId);
      for (final item in match) {
        await _plugin.cancel(id: item.id);
      }
      await _write(
        stored.copyWith(
          snoozes: stored.snoozes.where((item) => item.logId != logId).toList(),
        ),
      );
    });
  }

  Future<void> applyResponse(
    NotificationResponse response,
    AppLocalizations l10n, {
    required bool notifyUi,
  }) async {
    final intent = reminderLaunchIntent(
      dismissed:
          response.notificationResponseType ==
          NotificationResponseType.notificationDismissed,
      selectedAction:
          response.notificationResponseType ==
          NotificationResponseType.selectedNotificationAction,
      actionId: response.actionId,
      payload: response.payload,
    );
    switch (intent) {
      case ReminderLaunchIntent.ignore:
        return;
      case ReminderLaunchIntent.openMedications:
        if (notifyUi) MedicationNotificationBus.requestOpenMedications();
        return;
      case ReminderLaunchIntent.taken:
      case ReminderLaunchIntent.snooze:
        break;
    }

    final payload = ReminderPayload.decode(response.payload);
    if (payload == null) return;

    final repo = MedicationRepository(_prefs);
    final log = await _logFor(repo, payload);
    if (log == null) return;

    if (intent == ReminderLaunchIntent.taken) {
      await repo.markAsTaken(log.id, DateTime.now());
      await cancelSnooze(log.id);
    } else if (intent == ReminderLaunchIntent.snooze) {
      await repo.snoozeLog(log.id, 15);
      await scheduleSnooze(
        l10n: l10n,
        logId: log.id,
        medicationId: payload.medicationId,
        medicationName: payload.name,
        time: payload.time,
        minutes: 15,
      );
    }

    if (notifyUi) MedicationNotificationBus.notifyDoseChanged();
  }

  Future<void> _configure(AppLocalizations l10n, String languageCode) async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          medicationDoseCategoryId(languageCode),
          actions: [
            DarwinNotificationAction.plain(
              medicationActionTaken,
              l10n.notificationActionTaken,
            ),
            DarwinNotificationAction.plain(
              medicationActionSnooze,
              l10n.notificationActionSnooze,
            ),
          ],
        ),
      ],
    );

    try {
      await _plugin.initialize(
        settings: InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
        ),
        onDidReceiveNotificationResponse: _onForegroundResponse,
        onDidReceiveBackgroundNotificationResponse:
            medicationReminderBackground,
      );
    } catch (e) {
      debugPrint('[MedicationReminder] init: $e');
    }
  }

  void _onForegroundResponse(NotificationResponse response) {
    final l10n = _l10n;
    if (l10n == null) return;
    applyResponse(response, l10n, notifyUi: true);
  }

  Future<void> _sync(
    List<Medication> meds,
    AppLocalizations l10n, {
    required bool force,
  }) async {
    await initialize(l10n);
    await _ensureTimeZone();

    final expected = _occurrences(meds, l10n);
    final peeked = await _androidMode(prompt: false);
    final peekedSignature = _signature(expected, peeked, l10n.localeName);
    final stored = _read();
    if (!force && stored.signature == peekedSignature) return;

    if (expected.isNotEmpty) {
      await _requestPermissions();
    }
    final mode = await _androidMode(prompt: expected.isNotEmpty);
    await _apply(
      expected: expected,
      meds: meds,
      l10n: l10n,
      mode: mode,
      stored: stored,
    );
  }

  Future<void> _apply({
    required List<_PlannedDose> expected,
    required List<Medication> meds,
    required AppLocalizations l10n,
    required AndroidScheduleMode mode,
    required _StoredSchedule stored,
  }) async {
    final details = _details(l10n);
    final nextIds = expected.map((item) => item.id).toSet();
    for (final id in stored.ids) {
      if (!nextIds.contains(id)) {
        await _plugin.cancel(id: id);
      }
    }

    final kept = <_Snooze>[];
    final activeIds = meds.map((med) => med.id).toSet();
    for (final snooze in stored.snoozes) {
      if (activeIds.contains(snooze.medicationId)) {
        kept.add(snooze);
      } else {
        await _plugin.cancel(id: snooze.id);
      }
    }

    for (final dose in expected) {
      await _zoned(
        id: dose.id,
        title: dose.title,
        body: dose.body,
        when: dose.when,
        payload: dose.payload,
        mode: mode,
        repeating: true,
        details: details,
      );
    }

    await _write(
      _StoredSchedule(
        ids: nextIds.toList(),
        signature: _signature(expected, mode, l10n.localeName),
        snoozes: kept,
      ),
    );
  }

  List<_PlannedDose> _occurrences(
    List<Medication> meds,
    AppLocalizations l10n,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    final planned = <_PlannedDose>[];
    for (final med in meds) {
      if (!med.active) continue;
      final upcoming = upcomingDoseOccurrences(
        now: now,
        scheduledTimes: med.scheduledTimes,
        daysOfWeek: med.daysOfWeek,
      );
      for (final slot in upcoming) {
        planned.add(
          _PlannedDose(
            id: doseNotificationId(
              medicationId: med.id,
              time: slot.time,
              weekday: slot.weekday,
            ),
            when: tz.TZDateTime(
              tz.local,
              slot.at.year,
              slot.at.month,
              slot.at.day,
              slot.at.hour,
              slot.at.minute,
            ),
            title: l10n.medDoseReminderTitle(med.name),
            body: l10n.medDoseReminderBody,
            payload: ReminderPayload(
              kind: medicationDoseKind,
              medicationId: med.id,
              name: med.name,
              time: slot.time,
            ).encode(),
          ),
        );
      }
    }
    return planned;
  }

  Future<void> _zoned({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String payload,
    required AndroidScheduleMode mode,
    required bool repeating,
    required NotificationDetails details,
  }) async {
    Future<void> schedule(AndroidScheduleMode selected) {
      return _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: selected,
        payload: payload,
        matchDateTimeComponents: repeating
            ? DateTimeComponents.dayOfWeekAndTime
            : null,
      );
    }

    try {
      await schedule(mode);
    } catch (e) {
      if (mode != AndroidScheduleMode.alarmClock) {
        debugPrint('[MedicationReminder] agendar: $e');
        return;
      }
      try {
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      } catch (fallback) {
        debugPrint('[MedicationReminder] agendar: $fallback');
      }
    }
  }

  NotificationDetails _details(AppLocalizations l10n) {
    final languageCode = l10n.localeName.split('_').first;
    final darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.active,
      categoryIdentifier: medicationDoseCategoryId(languageCode),
    );
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_reminders',
        l10n.medReminderChannelName,
        channelDescription: l10n.medReminderChannelDesc,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
        icon: '@mipmap/ic_launcher',
        actions: [
          AndroidNotificationAction(
            medicationActionTaken,
            l10n.notificationActionTaken,
            showsUserInterface: false,
            cancelNotification: true,
            semanticAction: SemanticAction.markAsRead,
          ),
          AndroidNotificationAction(
            medicationActionSnooze,
            l10n.notificationActionSnooze,
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: darwin,
      macOS: darwin,
    );
  }

  Future<AndroidScheduleMode> _androidMode({required bool prompt}) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return AndroidScheduleMode.alarmClock;

    final exact = await android.canScheduleExactNotifications();
    if (exact == true) return AndroidScheduleMode.alarmClock;
    if (!prompt || (_prefs.getBool(_exactPromptedKey) ?? false)) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }

    await _prefs.setBool(_exactPromptedKey, true);
    final granted = await android.requestExactAlarmsPermission();
    if (granted == true) return AndroidScheduleMode.alarmClock;
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    if (!(_prefs.getBool(_fullScreenPromptedKey) ?? false)) {
      await _prefs.setBool(_fullScreenPromptedKey, true);
      await android?.requestFullScreenIntentPermission();
    }
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<MedicationLog?> _logFor(
    MedicationRepository repo,
    ReminderPayload payload,
  ) async {
    final logId = payload.logId;
    if (logId != null) {
      final existing = await repo.logById(logId);
      if (existing != null) return existing;
    }
    return repo.ensureDoseLog(
      medicationId: payload.medicationId,
      medicationName: payload.name,
      scheduled: scheduledDoseInstant(payload.time),
    );
  }

  Future<void> _ensureTimeZone() async {
    if (_timeZoneReady) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('[MedicationReminder] fuso: $e');
    }
    _timeZoneReady = true;
  }

  Future<void> _locked(Future<void> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.then((_) {}, onError: (_, _) {});
    return next;
  }

  String _signature(
    List<_PlannedDose> doses,
    AndroidScheduleMode mode,
    String locale,
  ) {
    final ids = doses.map((dose) => dose.id).toList()..sort();
    return '${mode.name}|$locale|${ids.join(',')}';
  }

  _StoredSchedule _read() {
    final raw = _prefs.getString(_scheduleKey);
    if (raw == null || raw.isEmpty) return const _StoredSchedule.empty();
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return const _StoredSchedule.empty();
      final ids = (map['ids'] as List<dynamic>? ?? const [])
          .map((id) => id as int)
          .toList();
      final snoozes = (map['snoozes'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => _Snooze(
              id: item['id'] as int,
              medicationId: item['medicationId'] as String,
              logId: item['logId'] as String,
            ),
          )
          .toList();
      return _StoredSchedule(
        ids: ids,
        signature: map['signature'] as String? ?? '',
        snoozes: snoozes,
      );
    } catch (_) {
      return const _StoredSchedule.empty();
    }
  }

  Future<void> _write(_StoredSchedule stored) {
    return _prefs.setString(
      _scheduleKey,
      jsonEncode({
        'ids': stored.ids,
        'signature': stored.signature,
        'snoozes': [
          for (final item in stored.snoozes)
            {
              'id': item.id,
              'medicationId': item.medicationId,
              'logId': item.logId,
            },
        ],
      }),
    );
  }
}

Locale localeFromReminderPrefs(SharedPreferences prefs) {
  final saved = prefs.getString(_localePrefKey);
  if (saved != null && saved.isNotEmpty && saved != 'system') {
    return Locale(saved);
  }
  final code = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
  switch (code) {
    case 'en':
      return const Locale('en');
    case 'ja':
      return const Locale('ja');
    case 'es':
      return const Locale('es');
    default:
      return const Locale('pt');
  }
}

class _PlannedDose {
  const _PlannedDose({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final tz.TZDateTime when;
  final String title;
  final String body;
  final String payload;
}

class _Snooze {
  const _Snooze({
    required this.id,
    required this.medicationId,
    required this.logId,
  });

  final int id;
  final String medicationId;
  final String logId;
}

class _StoredSchedule {
  const _StoredSchedule({
    required this.ids,
    required this.signature,
    required this.snoozes,
  });

  const _StoredSchedule.empty()
    : ids = const [],
      signature = '',
      snoozes = const [];

  final List<int> ids;
  final String signature;
  final List<_Snooze> snoozes;

  _StoredSchedule copyWith({
    List<int>? ids,
    String? signature,
    List<_Snooze>? snoozes,
  }) {
    return _StoredSchedule(
      ids: ids ?? this.ids,
      signature: signature ?? this.signature,
      snoozes: snoozes ?? this.snoozes,
    );
  }
}
