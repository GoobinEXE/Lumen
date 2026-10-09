import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/responsive.dart';
import '../../../core/widgets/async_placeholders.dart';
import '../domain/task_item.dart';
import '../domain/task_period.dart';
import 'task_editor_sheet.dart';
import 'task_providers.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/glass_nav_bar.dart';
import '../../../core/widgets/lumen_fab.dart';

class TasksHubScreen extends ConsumerWidget {
  const TasksHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tasksAsync = ref.watch(tasksListProvider);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(l10n.tasksHubTitle),
        actions: [
          IconButton(
            tooltip: l10n.taskManageQuietHours,
            icon: const Icon(Icons.bedtime_outlined),
            onPressed: () => TaskQuietHoursSheet.show(context),
          ),
          IconButton(
            tooltip: l10n.addMicroHabitButton,
            icon: const Icon(AppIcons.add),
            onPressed: () => TaskEditorSheet.show(context),
          ),
        ],
      ),
      floatingActionButton: LumenFab(
        onPressed: () => TaskEditorSheet.show(context),
        icon: AppIcons.add,
        tooltip: l10n.addMicroHabitButton,
      ),
      body: tasksAsync.when(
        loading: () => const FormSkeleton(),
        error: (err, _) => Center(child: Text(l10n.errorWithDetails('$err'))),
        data: (tasks) {
          final now = DateTime.now();
          final active = tasks.where((t) => t.active).toList();
          final today =
              active.where((t) => TaskPeriod.appliesOn(t, now)).toList();
          final allRecurring = active
              .where((t) => t.recurrence != TaskRecurrence.once)
              .toList();
          final once = active
              .where((t) => t.recurrence == TaskRecurrence.once)
              .toList();

          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.screenV,
              AppSpacing.screenH,
              GlassNavBar.reservedBottom(context) + 72,
            ),
            children: [
              _Group(
                title: l10n.tasksHubTodaySection,
                empty: l10n.tasksHubEmptyToday,
                tasks: today,
                now: now,
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              _Group(
                title: l10n.tasksHubRecurringSection,
                empty: l10n.tasksHubEmptyRecurring,
                tasks: allRecurring,
                now: now,
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              _Group(
                title: l10n.tasksHubOnceSection,
                empty: l10n.tasksHubEmptyOnce,
                tasks: once,
                now: now,
                isDark: isDark,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Group extends ConsumerWidget {
  const _Group({
    required this.title,
    required this.empty,
    required this.tasks,
    required this.now,
    required this.isDark,
  });

  final String title;
  final String empty;
  final List<TaskItem> tasks;
  final DateTime now;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          Text(empty, style: theme.textTheme.bodyMedium)
        else
          for (final task in tasks)
            _TaskRow(task: task, now: now, isDark: isDark),
      ],
    );
  }
}

class _TaskRow extends ConsumerWidget {
  const _TaskRow({
    required this.task,
    required this.now,
    required this.isDark,
  });

  final TaskItem task;
  final DateTime now;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final done = TaskPeriod.isCompletedInCurrentPeriod(task, now);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            checked: done,
            label: task.title,
            child: CheckboxListTile(
              value: done,
              title: Text(
                task.title,
                style: TextStyle(
                  fontSize: 14,
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: task.timeOfDay == null
                  ? null
                  : Text(
                      l10n.taskReminderChip(task.timeOfDay!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMuted,
                      ),
                    ),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (_) async {
                HapticFeedback.selectionClick();
                await ref.read(tasksListProvider.notifier).toggleComplete(task);
              },
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.taskEditorTitleEdit,
          constraints: const BoxConstraints(
            minWidth: kMinTapTarget,
            minHeight: kMinTapTarget,
          ),
          icon: Icon(
            Icons.edit_outlined,
            size: 20,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
          onPressed: () => TaskEditorSheet.show(context, existing: task),
        ),
      ],
    );
  }
}
