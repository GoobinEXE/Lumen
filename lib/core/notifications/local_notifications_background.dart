import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/medications/service/medication_reminder_service.dart';
import '../../features/medications/service/reminder_schedule.dart';
import '../../features/tasks/domain/task_reminder_schedule.dart';
import '../../features/tasks/service/task_reminder_service.dart';
import 'local_notifications_host.dart';

/// Ponto de entrada do isolate de fundo. Precisa ser função de topo.
@pragma('vm:entry-point')
void localNotificationsBackground(NotificationResponse response) {
  WidgetsFlutterBinding.ensureInitialized();
  _handle(response);
}

Future<void> _handle(NotificationResponse response) async {
  try {
    final kind = LocalNotificationsHost.kindFromPayload(response.payload);
    if (kind == taskReminderKind || kind == taskSnoozeKind) {
      await TaskReminderService.handleBackgroundResponse(response);
      return;
    }
    if (kind == medicationDoseKind || kind == medicationSnoozeKind) {
      await MedicationReminderService.handleBackgroundResponse(response);
    }
  } catch (e) {
    // ignore: avoid_print
    print('[LocalNotifications] fundo: $e');
  }
}
