import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:noa/l10n/app_localizations.dart';

import '../../features/medications/service/reminder_schedule.dart';
import '../../features/tasks/domain/task_reminder_schedule.dart';

typedef LocalNotificationHandler = Future<void> Function(
  NotificationResponse response, {
  required bool notifyUi,
});

/// Init única do plugin — dose e tarefa compartilham categorias Darwin.
class LocalNotificationsHost {
  LocalNotificationsHost._();

  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void>? _initializing;
  static String? _localeCode;
  static AppLocalizations? _l10n;
  static DidReceiveBackgroundNotificationResponseCallback? _background;

  static LocalNotificationHandler? medicationHandler;
  static LocalNotificationHandler? taskHandler;

  static AppLocalizations? get l10n => _l10n;

  static void bindBackground(
    DidReceiveBackgroundNotificationResponseCallback callback,
  ) {
    _background = callback;
  }

  static Future<void> ensureInitialized(AppLocalizations l10n) {
    final code = l10n.localeName.split('_').first;
    if (_initializing != null && _localeCode == code) return _initializing!;
    _localeCode = code;
    _l10n = l10n;
    final future = _configure(l10n, code);
    _initializing = future;
    return future;
  }

  static Future<void> consumeLaunch() async {
    try {
      final details = await plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return;
      final response = details.notificationResponse;
      if (response == null) return;
      await dispatch(response, notifyUi: false);
    } catch (e) {
      debugPrint('[LocalNotifications] abertura: $e');
    }
  }

  static Future<void> dispatch(
    NotificationResponse response, {
    required bool notifyUi,
  }) async {
    final kind = kindFromPayload(response.payload);
    if (kind == taskReminderKind || kind == taskSnoozeKind) {
      final handler = taskHandler;
      if (handler != null) await handler(response, notifyUi: notifyUi);
      return;
    }
    if (kind == medicationDoseKind || kind == medicationSnoozeKind) {
      final handler = medicationHandler;
      if (handler != null) await handler(response, notifyUi: notifyUi);
    }
  }

  static String? kindFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final map = jsonDecode(payload);
      if (map is! Map) return null;
      return map['kind'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _configure(
    AppLocalizations l10n,
    String languageCode,
  ) async {
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
        DarwinNotificationCategory(
          taskReminderCategoryId(languageCode),
          actions: [
            DarwinNotificationAction.plain(
              taskActionComplete,
              l10n.taskNotificationActionComplete,
            ),
            DarwinNotificationAction.plain(
              taskActionSnooze,
              l10n.taskNotificationActionSnooze,
            ),
          ],
        ),
      ],
    );

    try {
      await plugin.initialize(
        settings: InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
        ),
        onDidReceiveNotificationResponse: _onForeground,
        onDidReceiveBackgroundNotificationResponse: _background,
      );
    } catch (e) {
      debugPrint('[LocalNotifications] init: $e');
    }
  }

  static void _onForeground(NotificationResponse response) {
    // Agenda o Future; erros não derrubam o isolate de UI.
    dispatch(response, notifyUi: true).catchError((Object e) {
      debugPrint('[LocalNotifications] foreground: $e');
    });
  }
}
