import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/providers.dart';
import '../../../integrations/system/system_settings.dart';
import '../../routine_mood/data/micro_habits_prefs.dart';
import '../data/task_quiet_hours_prefs.dart';
import '../data/task_repository.dart';
import '../domain/task_item.dart';
import '../domain/task_period.dart';
import '../domain/task_quiet_hours.dart';
import '../service/task_notification_bus.dart';
import '../service/task_reminder_service.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(sharedPreferencesProvider));
});

final taskReminderServiceProvider = Provider<TaskReminderService>((ref) {
  return TaskReminderService(ref.watch(sharedPreferencesProvider));
});

final taskSystemSettingsProvider = Provider<SystemSettings>((ref) {
  return SystemSettings();
});

/// Estado real de notificações liberadas (sem prompt). Consultado pelo
/// editor de tarefa só quando a tarefa tem horário de aviso.
final taskNotificationsEnabledProvider = FutureProvider.autoDispose<bool>((
  ref,
) {
  return ref.watch(taskReminderServiceProvider).notificationsEnabled();
});

/// Estado real da permissão de alarme exato no Android (sempre `true` fora
/// dele). Consultado pelo editor de tarefa só quando há horário de aviso.
final taskExactAlarmsAllowedProvider = FutureProvider.autoDispose<bool>((
  ref,
) {
  return ref.watch(taskReminderServiceProvider).exactAlarmsAllowed();
});

final taskQuietHoursProvider = StateNotifierProvider<TaskQuietHoursNotifier, TaskQuietHours>((
  ref,
) {
  return TaskQuietHoursNotifier(ref);
});

class TaskQuietHoursNotifier extends StateNotifier<TaskQuietHours> {
  TaskQuietHoursNotifier(this._ref)
      : super(getTaskQuietHours(_ref.read(sharedPreferencesProvider)));

  final Ref _ref;

  Future<void> save(TaskQuietHours hours) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await setTaskQuietHours(prefs, hours);
    state = hours;
    await _ref.read(tasksListProvider.notifier).syncReminders(force: true);
  }
}

final tasksListProvider =
    StateNotifierProvider<TasksListNotifier, AsyncValue<List<TaskItem>>>((ref) {
  return TasksListNotifier(ref);
});

class TasksListNotifier extends StateNotifier<AsyncValue<List<TaskItem>>> {
  /// Lista vazia inicial (não `loading`) — a Dia mostra o atalho do hub
  /// enquanto o seed/JSON local termina; o sync de lembretes não bloqueia a UI.
  TasksListNotifier(this._ref) : super(const AsyncValue.data([])) {
    TaskNotificationBus.tasksChanged.addListener(_onExternal);
    _ref.listen(appLocalizationsProvider, (previous, next) {
      if (previous == null || previous.localeName == next.localeName) return;
      _checkedSchedule = false;
      load();
    });
    load();
  }

  final Ref _ref;
  bool _checkedSchedule = false;

  @override
  void dispose() {
    TaskNotificationBus.tasksChanged.removeListener(_onExternal);
    super.dispose();
  }

  void _onExternal() => load();

  Future<void> load() async {
    try {
      final l10n = _ref.read(appLocalizationsProvider);
      final repo = _ref.read(taskRepositoryProvider);
      final tasks = await repo.loadOrSeed(defaultMicroHabits(l10n));
      if (!mounted) return;
      state = AsyncValue.data(tasks);
      // Sync de plugin/fuso não pode segurar o load — em teste o channel
      // de timezone pode nunca completar.
      unawaited(_syncReminders(tasks, force: false));
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> syncReminders({bool force = false}) async {
    final tasks = state.value;
    if (tasks == null) return;
    await _syncReminders(tasks, force: force);
  }

  Future<void> _syncReminders(List<TaskItem> tasks, {required bool force}) async {
    if (!force && _checkedSchedule) return;
    _checkedSchedule = true;
    try {
      final l10n = _ref.read(appLocalizationsProvider);
      final service = _ref.read(taskReminderServiceProvider);
      if (force) {
        await service.syncAll(tasks, l10n);
      } else {
        await service.syncIfNeeded(tasks, l10n);
      }
    } catch (e) {
      debugPrint('[Tasks] lembretes: $e');
      _checkedSchedule = false;
    }
  }

  Future<void> upsert(TaskItem task) async {
    final repo = _ref.read(taskRepositoryProvider);
    await repo.upsert(task);
    _checkedSchedule = false;
    await load();
  }

  Future<void> delete(String id) async {
    final repo = _ref.read(taskRepositoryProvider);
    await repo.delete(id);
    _checkedSchedule = false;
    await load();
  }

  Future<void> toggleComplete(TaskItem task) async {
    final repo = _ref.read(taskRepositoryProvider);
    final now = DateTime.now();
    final done = TaskPeriod.isCompletedInCurrentPeriod(task, now);
    if (done) {
      await repo.markIncomplete(task.id);
    } else {
      await repo.markComplete(task.id, now);
    }
    _checkedSchedule = false;
    await load();
  }
}
