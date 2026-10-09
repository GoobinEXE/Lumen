import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/notifications/local_notification_scheduler.dart';
import '../../../core/notifications/local_notifications_host.dart';
import '../../medications/service/medication_reminder_service.dart'
    show localeFromSystem;
import '../data/task_quiet_hours_prefs.dart';
import '../data/task_repository.dart';
import '../domain/task_item.dart';
import '../domain/task_period.dart';
import '../domain/task_quiet_hours.dart';
import '../domain/task_reminder_schedule.dart';
import 'task_notification_bus.dart';

const _scheduleKey = 'noa_task_reminder_schedule_v1';
const _exactPromptedKey = 'noa_exact_alarm_prompted';

class TaskReminderService {
  TaskReminderService(this._prefs);

  final SharedPreferences _prefs;
  FlutterLocalNotificationsPlugin get _plugin => LocalNotificationsHost.plugin;

  Future<void> _queue = Future<void>.value();
  static bool _handlerBound = false;

  static Future<void> handleResponse(
    NotificationResponse response, {
    required bool notifyUi,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final l10n = lookupAppLocalizations(localeFromSystem());
      final service = TaskReminderService(prefs);
      await service.initialize(l10n);

      final intent = taskReminderLaunchIntent(
        dismissed:
            response.notificationResponseType ==
            NotificationResponseType.notificationDismissed,
        selectedAction:
            response.notificationResponseType ==
            NotificationResponseType.selectedNotificationAction,
        actionId: response.actionId,
        payload: response.payload,
      );
      if (intent == TaskReminderLaunchIntent.openRoutine) {
        TaskNotificationBus.requestOpenTasks();
        return;
      }
      await service.applyResponse(response, l10n, notifyUi: notifyUi);
    } catch (e) {
      debugPrint('[TaskReminder] resposta: $e');
    }
  }

  static Future<void> handleBackgroundResponse(
    NotificationResponse response,
  ) {
    return handleResponse(response, notifyUi: false);
  }

  Future<void> initialize(AppLocalizations l10n) async {
    if (!_handlerBound) {
      LocalNotificationsHost.taskHandler = (response, {required notifyUi}) {
        return handleResponse(response, notifyUi: notifyUi);
      };
      _handlerBound = true;
    }
    await LocalNotificationsHost.ensureInitialized(l10n);
  }

  Future<void> syncIfNeeded(List<TaskItem> tasks, AppLocalizations l10n) {
    return _locked(() => _sync(tasks, l10n, force: false));
  }

  Future<void> syncAll(List<TaskItem> tasks, AppLocalizations l10n) {
    return _locked(() => _sync(tasks, l10n, force: true));
  }

  /// Estado real da permissão de notificação no aparelho (sem prompt).
  /// Android 13+: `areNotificationsEnabled`. iOS/macOS: `checkPermissions().isEnabled`.
  /// Plataforma sem resolver (ex. web/desktop não suportado) assume liberado.
  Future<bool> notificationsEnabled() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final enabled = await android.areNotificationsEnabled();
        return enabled ?? true;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final permissions = await ios.checkPermissions();
        return permissions?.isEnabled ?? true;
      }
      final macos = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      if (macos != null) {
        final permissions = await macos.checkPermissions();
        return permissions?.isEnabled ?? true;
      }
      return true;
    } catch (e) {
      debugPrint('[TaskReminder] estado de notificação: $e');
      return true;
    }
  }

  /// Permissão de alarme exato no Android (sem prompt). Sempre `true` fora
  /// do Android, onde o conceito não existe.
  Future<bool> exactAlarmsAllowed() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return true;
      final allowed = await android.canScheduleExactNotifications();
      return allowed ?? true;
    } catch (e) {
      debugPrint('[TaskReminder] estado de alarme exato: $e');
      return true;
    }
  }

  Future<void> applyResponse(
    NotificationResponse response,
    AppLocalizations l10n, {
    required bool notifyUi,
  }) async {
    final intent = taskReminderLaunchIntent(
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
      case TaskReminderLaunchIntent.ignore:
        return;
      case TaskReminderLaunchIntent.openRoutine:
        if (notifyUi) TaskNotificationBus.requestOpenTasks();
        return;
      case TaskReminderLaunchIntent.complete:
      case TaskReminderLaunchIntent.snooze:
        break;
    }

    final payload = TaskReminderPayload.decode(response.payload);
    if (payload == null) return;

    final repo = TaskRepository(_prefs);
    await repo.reload();
    final now = DateTime.now();

    if (intent == TaskReminderLaunchIntent.complete) {
      await repo.markComplete(payload.taskId, now);
    } else if (intent == TaskReminderLaunchIntent.snooze) {
      final task = await repo.getById(payload.taskId);
      final minutes = task?.naggingIntervalMinutes ?? payload.minutes ?? 5;
      await repo.snooze(
        payload.taskId,
        now.add(Duration(minutes: minutes < 1 ? 1 : minutes)),
      );
    }

    final tasks = await repo.getTasks();
    await syncAll(tasks, l10n);
    if (notifyUi) TaskNotificationBus.notifyTasksChanged();
  }

  Future<void> _sync(
    List<TaskItem> tasks,
    AppLocalizations l10n, {
    required bool force,
  }) async {
    await initialize(l10n);
    try {
      await _ensureTimeZone();
    } catch (e) {
      debugPrint('[TaskReminder] fuso: $e');
      return;
    }

    final quiet = getTaskQuietHours(_prefs);
    final expected = _occurrences(tasks, l10n, quiet);
    final peeked = await _androidMode(prompt: false);
    final peekedSignature = _signature(expected, peeked, l10n.localeName, quiet);
    final stored = _read();
    if (!force && stored.signature == peekedSignature) return;

    if (expected.isNotEmpty) {
      await _requestPermissions();
    }
    final mode = await _androidMode(prompt: expected.isNotEmpty);
    await _apply(expected: expected, mode: mode, stored: stored, quiet: quiet, locale: l10n.localeName);
  }

  Future<void> _apply({
    required List<_PlannedTask> expected,
    required AndroidScheduleMode mode,
    required _StoredSchedule stored,
    required TaskQuietHours quiet,
    required String locale,
  }) async {
    final nextIds = expected.map((item) => item.id).toSet();
    for (final id in stored.ids) {
      if (!nextIds.contains(id)) {
        await _plugin.cancel(id: id);
      }
    }

    for (final item in expected) {
      await _zoned(
        id: item.id,
        title: item.title,
        body: item.body,
        when: item.when,
        payload: item.payload,
        mode: mode,
        details: item.details,
      );
    }

    await _write(
      _StoredSchedule(
        ids: nextIds.toList(),
        signature: _signature(expected, mode, locale, quiet),
      ),
    );
  }

  List<_PlannedTask> _occurrences(
    List<TaskItem> tasks,
    AppLocalizations l10n,
    TaskQuietHours quiet,
  ) {
    final now = DateTime.now();
    final planned = <_PlannedTask>[];
    for (final task in tasks) {
      if (!task.hasReminder) continue;
      final period = TaskPeriod.window(
        recurrence: task.recurrence,
        now: now,
        onceDate: task.onceDate,
      );
      final fires = TaskPeriod.upcomingFires(
        task: task,
        now: now,
        quietHours: quiet,
      );
      for (var i = 0; i < fires.length; i++) {
        final at = fires[i];
        planned.add(
          _PlannedTask(
            id: taskNotificationId(
              taskId: task.id,
              periodKey: period.periodKey,
              slot: i,
            ),
            when: tz.TZDateTime(
              tz.local,
              at.year,
              at.month,
              at.day,
              at.hour,
              at.minute,
            ),
            title: l10n.taskReminderTitle(task.title),
            body: l10n.taskReminderBody,
            payload: TaskReminderPayload(
              kind: taskReminderKind,
              taskId: task.id,
              title: task.title,
              periodKey: period.periodKey,
              alertStyle: task.alertStyle,
              minutes: task.naggingIntervalMinutes,
            ).encode(),
            details: _details(l10n, task.alertStyle),
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
    required NotificationDetails details,
  }) {
    return LocalNotificationScheduler.zonedSchedule(
      id: id,
      title: title,
      body: body,
      when: when,
      payload: payload,
      mode: mode,
      repeating: false,
      details: details,
    );
  }

  NotificationDetails _details(AppLocalizations l10n, TaskAlertStyle style) {
    final languageCode = l10n.localeName.split('_').first;
    final insistent = style == TaskAlertStyle.insistent;
    final alarmLike =
        style == TaskAlertStyle.alarm || style == TaskAlertStyle.insistent;

    final darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: insistent
          ? InterruptionLevel.timeSensitive
          : InterruptionLevel.active,
      categoryIdentifier: taskReminderCategoryId(languageCode),
    );

    return NotificationDetails(
      android: AndroidNotificationDetails(
        alarmLike ? 'task_reminders_alarm' : 'task_reminders',
        l10n.taskReminderChannelName,
        channelDescription: l10n.taskReminderChannelDesc,
        importance: alarmLike ? Importance.max : Importance.defaultImportance,
        priority: alarmLike ? Priority.high : Priority.defaultPriority,
        category: alarmLike
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.reminder,
        audioAttributesUsage: alarmLike
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
        visibility: NotificationVisibility.public,
        fullScreenIntent: insistent,
        icon: '@mipmap/ic_launcher',
        actions: [
          AndroidNotificationAction(
            taskActionComplete,
            l10n.taskNotificationActionComplete,
            showsUserInterface: false,
            cancelNotification: true,
            semanticAction: SemanticAction.markAsRead,
          ),
          AndroidNotificationAction(
            taskActionSnooze,
            l10n.taskNotificationActionSnooze,
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

  Future<void> _ensureTimeZone() => LocalNotificationScheduler.ensureTimeZone();

  Future<void> _locked(Future<void> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.then((_) {}, onError: (_, _) {});
    return next;
  }

  String _signature(
    List<_PlannedTask> items,
    AndroidScheduleMode mode,
    String locale,
    TaskQuietHours quiet,
  ) {
    final ids = items.map((item) => '${item.id}@${item.when.toIso8601String()}').toList()
      ..sort();
    return '${mode.name}|$locale|${quiet.startHour}:${quiet.startMinute}-${quiet.endHour}:${quiet.endMinute}|${ids.join(',')}';
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
      return _StoredSchedule(
        ids: ids,
        signature: map['signature'] as String? ?? '',
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
      }),
    );
  }
}

class _PlannedTask {
  const _PlannedTask({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
    required this.payload,
    required this.details,
  });

  final int id;
  final tz.TZDateTime when;
  final String title;
  final String body;
  final String payload;
  final NotificationDetails details;
}

class _StoredSchedule {
  const _StoredSchedule({
    required this.ids,
    required this.signature,
  });

  const _StoredSchedule.empty()
      : ids = const [],
        signature = '';

  final List<int> ids;
  final String signature;
}
