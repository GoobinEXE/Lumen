import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'local_notifications_host.dart';

/// Infra compartilhada de timezone + zonedSchedule entre dose e tarefa.
class LocalNotificationScheduler {
  LocalNotificationScheduler._();

  static bool _timeZoneReady = false;

  static Future<void> ensureTimeZone() async {
    if (_timeZoneReady) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('[LocalNotificationScheduler] fuso: $e');
    }
    _timeZoneReady = true;
  }

  static Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String payload,
    required AndroidScheduleMode mode,
    required bool repeating,
    required NotificationDetails details,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    final plugin = LocalNotificationsHost.plugin;
    Future<void> schedule(AndroidScheduleMode selected) {
      return plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: selected,
        payload: payload,
        matchDateTimeComponents: repeating
            ? (matchDateTimeComponents ?? DateTimeComponents.dayOfWeekAndTime)
            : null,
      );
    }

    try {
      await schedule(mode);
    } catch (e) {
      if (mode != AndroidScheduleMode.alarmClock) {
        debugPrint('[LocalNotificationScheduler] agendar: $e');
        return;
      }
      try {
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      } catch (fallback) {
        debugPrint('[LocalNotificationScheduler] agendar: $fallback');
      }
    }
  }
}
