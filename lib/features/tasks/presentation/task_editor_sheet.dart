import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_surface.dart';
import '../../../core/theme/responsive.dart';
import '../../../core/widgets/glass_chip.dart';
import '../../../core/widgets/glass_toast.dart';
import '../../../integrations/system/system_settings.dart';
import '../../medications/presentation/widgets/system_time_picker.dart';
import '../domain/task_item.dart';
import '../domain/task_period.dart';
import '../domain/task_quiet_hours.dart';
import 'task_providers.dart';

class TaskEditorSheet extends ConsumerStatefulWidget {
  const TaskEditorSheet({super.key, this.existing});

  final TaskItem? existing;

  static Future<void> show(BuildContext context, {TaskItem? existing}) {
    return showLumenSheet<void>(
      context: context,
      builder: (context) => TaskEditorSheet(existing: existing),
    );
  }

  @override
  ConsumerState<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends ConsumerState<TaskEditorSheet> {
  late final TextEditingController _titleController;
  final _titleFocus = FocusNode();
  TimeOfDay? _time;
  TaskRecurrence _recurrence = TaskRecurrence.daily;
  int _nagMinutes = 5;
  TaskAlertStyle _alertStyle = TaskAlertStyle.notification;
  List<int> _weekdays = const [1, 2, 3, 4, 5, 6, 7];
  int _dayOfMonth = 1;
  DateTime? _onceDate;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _titleFocus.addListener(() {
      if (_titleFocus.hasFocus) {
        final ctx = _titleFocus.context;
        if (ctx != null) lumenEnsureSheetFieldVisible(ctx);
      }
    });
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    if (existing != null) {
      _recurrence = existing.recurrence;
      _nagMinutes = existing.naggingIntervalMinutes;
      _alertStyle = existing.alertStyle;
      _weekdays = List<int>.from(existing.weekdays);
      _dayOfMonth = existing.dayOfMonth;
      _onceDate = existing.onceDate;
      final parsed = existing.timeOfDay == null
          ? null
          : TaskPeriod.parseTimeOfDay(existing.timeOfDay!);
      if (parsed != null) {
        _time = TimeOfDay(hour: parsed.$1, minute: parsed.$2);
      }
    }
  }

  @override
  void dispose() {
    _titleFocus.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showSystemTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    setState(() => _time = picked);
  }

  Future<void> _pickOnceDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _onceDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() => _onceDate = picked);
  }

  Future<void> _save(AppLocalizations l10n) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showGlassToast(context, l10n.taskEmptyTitleError);
      return;
    }
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    final existing = widget.existing;
    final task = TaskItem(
      id: existing?.id ?? const Uuid().v4(),
      title: title,
      timeOfDay: _time == null
          ? null
          : TaskPeriod.formatTimeOfDay(_time!.hour, _time!.minute),
      recurrence: _recurrence,
      naggingIntervalMinutes: _nagMinutes,
      alertStyle: _alertStyle,
      weekdays: _weekdays,
      dayOfMonth: _dayOfMonth,
      onceDate: _recurrence == TaskRecurrence.once
          ? (_onceDate ?? DateTime.now())
          : null,
      completedPeriodKey: existing?.completedPeriodKey,
      snoozedUntil: existing?.snoozedUntil,
      active: existing?.active ?? true,
    );
    await ref.read(tasksListProvider.notifier).upsert(task);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = ref.watch(appLocalizationsProvider);
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return GlassSheet(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.sheetTop,
        AppSpacing.screenH,
        AppSpacing.sheetBottom,
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editing ? l10n.taskEditorTitleEdit : l10n.taskEditorTitleNew,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.taskTitleLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              focusNode: _titleFocus,
              scrollPadding: lumenSheetFieldScrollPadding,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: l10n.taskTitleHint,
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.input),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.taskTimeLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                GlassChip(
                  label: l10n.taskTimeNone,
                  selected: _time == null,
                  onTap: () => setState(() => _time = null),
                ),
                GlassActionChip(
                  label: _time == null
                      ? l10n.taskTimePick
                      : TaskPeriod.formatTimeOfDay(
                          _time!.hour,
                          _time!.minute,
                        ),
                  onTap: _pickTime,
                ),
              ],
            ),
            if (_time != null) ...[
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.taskQuietHoursEditorNote,
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, kMinTapTarget),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => TaskQuietHoursSheet.show(context),
                      child: Text(l10n.taskQuietHoursEditorLink),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.taskReminderClosedAppNote,
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ),
              const _ReminderPermissionBanners(),
            ],
            const SizedBox(height: 16),
            Text(l10n.taskRecurrenceLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in _recurrenceOptions(l10n))
                  GlassChip(
                    label: entry.$2,
                    selected: _recurrence == entry.$1,
                    onTap: () => setState(() => _recurrence = entry.$1),
                  ),
              ],
            ),
            if (_recurrence == TaskRecurrence.once) ...[
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.taskOnceDateLabel),
                subtitle: Text(
                  _onceDate == null
                      ? l10n.taskTimePick
                      : MaterialLocalizations.of(context).formatMediumDate(
                          _onceDate!,
                        ),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickOnceDate,
              ),
            ],
            if (_recurrence == TaskRecurrence.weekly ||
                _recurrence == TaskRecurrence.biweekly) ...[
              const SizedBox(height: 12),
              Text(l10n.taskWeekdaysLabel, style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  for (final day in _weekdayLabels(l10n).entries)
                    GlassChip(
                      label: day.value,
                      selected: _weekdays.contains(day.key),
                      onTap: () {
                        setState(() {
                          final next = Set<int>.from(_weekdays);
                          if (next.contains(day.key)) {
                            next.remove(day.key);
                          } else {
                            next.add(day.key);
                          }
                          _weekdays = next.isEmpty
                              ? [DateTime.monday]
                              : (next.toList()..sort());
                        });
                      },
                    ),
                ],
              ),
            ],
            if (_recurrence == TaskRecurrence.monthly) ...[
              const SizedBox(height: 12),
              Text(l10n.taskDayOfMonthLabel, style: theme.textTheme.labelLarge),
              Slider(
                value: _dayOfMonth.toDouble(),
                min: 1,
                max: 28,
                divisions: 27,
                label: '$_dayOfMonth',
                onChanged: (v) => setState(() => _dayOfMonth = v.round()),
              ),
            ],
            const SizedBox(height: 8),
            Text(l10n.taskNagIntervalLabel, style: theme.textTheme.labelLarge),
            Slider(
              value: _nagMinutes.toDouble().clamp(1, 60),
              min: 1,
              max: 60,
              divisions: 59,
              label: l10n.taskNagIntervalValue(_nagMinutes),
              onChanged: (v) => setState(() => _nagMinutes = v.round()),
            ),
            const SizedBox(height: 8),
            Text(l10n.taskAlertStyleLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final style in TaskAlertStyle.values)
                  GlassChip(
                    label: _alertLabel(l10n, style),
                    selected: _alertStyle == style,
                    onTap: () => setState(() => _alertStyle = style),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _alertHint(l10n, _alertStyle),
              style: TextStyle(fontSize: 12, color: muted),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? () {} : () => _save(l10n),
                child: Text(l10n.taskSaveButton),
              ),
            ),
            if (_editing) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          await ref
                              .read(tasksListProvider.notifier)
                              .delete(widget.existing!.id);
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                  child: Text(l10n.taskDeleteButton),
                ),
              ),
            ],
          ],
        ),
    );
  }

  List<(TaskRecurrence, String)> _recurrenceOptions(AppLocalizations l10n) => [
        (TaskRecurrence.once, l10n.taskRecurrenceOnce),
        (TaskRecurrence.daily, l10n.taskRecurrenceDaily),
        (TaskRecurrence.weekly, l10n.taskRecurrenceWeekly),
        (TaskRecurrence.biweekly, l10n.taskRecurrenceBiweekly),
        (TaskRecurrence.monthly, l10n.taskRecurrenceMonthly),
      ];

  Map<int, String> _weekdayLabels(AppLocalizations l10n) => {
        DateTime.monday: l10n.weekdayMonShort,
        DateTime.tuesday: l10n.weekdayTueShort,
        DateTime.wednesday: l10n.weekdayWedShort,
        DateTime.thursday: l10n.weekdayThuShort,
        DateTime.friday: l10n.weekdayFriShort,
        DateTime.saturday: l10n.weekdaySatShort,
        DateTime.sunday: l10n.weekdaySunShort,
      };

  String _alertLabel(AppLocalizations l10n, TaskAlertStyle style) {
    switch (style) {
      case TaskAlertStyle.notification:
        return l10n.taskAlertStyleNotification;
      case TaskAlertStyle.alarm:
        return l10n.taskAlertStyleAlarm;
      case TaskAlertStyle.insistent:
        return l10n.taskAlertStyleInsistent;
    }
  }

  String _alertHint(AppLocalizations l10n, TaskAlertStyle style) {
    switch (style) {
      case TaskAlertStyle.notification:
        return l10n.taskAlertStyleNotificationHint;
      case TaskAlertStyle.alarm:
        return l10n.taskAlertStyleAlarmHint;
      case TaskAlertStyle.insistent:
        return l10n.taskAlertStyleInsistentHint;
    }
  }
}

class TaskQuietHoursSheet extends ConsumerStatefulWidget {
  const TaskQuietHoursSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showLumenSheet<void>(
      context: context,
      builder: (context) => const TaskQuietHoursSheet(),
    );
  }

  @override
  ConsumerState<TaskQuietHoursSheet> createState() =>
      _TaskQuietHoursSheetState();
}

class _TaskQuietHoursSheetState extends ConsumerState<TaskQuietHoursSheet> {
  late TimeOfDay _start;
  late TimeOfDay _end;

  @override
  void initState() {
    super.initState();
    final hours = ref.read(taskQuietHoursProvider);
    _start = TimeOfDay(hour: hours.startHour, minute: hours.startMinute);
    _end = TimeOfDay(hour: hours.endHour, minute: hours.endMinute);
  }

  Future<void> _pick(bool start) async {
    final picked = await showSystemTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = ref.watch(appLocalizationsProvider);

    return GlassSheet(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.sheetTop,
        AppSpacing.screenH,
        AppSpacing.sheetBottom,
      ),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.taskQuietHoursTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(l10n.taskQuietHoursSubtitle),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.taskQuietHoursStart),
              trailing: Text(
                TaskPeriod.formatTimeOfDay(_start.hour, _start.minute),
              ),
              onTap: () => _pick(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.taskQuietHoursEnd),
              trailing: Text(
                TaskPeriod.formatTimeOfDay(_end.hour, _end.minute),
              ),
              onTap: () => _pick(false),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await ref.read(taskQuietHoursProvider.notifier).save(
                        TaskQuietHours(
                          startHour: _start.hour,
                          startMinute: _start.minute,
                          endHour: _end.hour,
                          endMinute: _end.minute,
                        ),
                      );
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                child: Text(l10n.taskQuietHoursSave),
              ),
            ),
          ],
        ),
    );
  }
}

/// Avisos de permissão da tarefa (notificação desligada / alarme exato
/// faltando no Android). Consulta o estado real do aparelho — nada de
/// store paralelo — e só aparece quando o estado real pede atenção.
class _ReminderPermissionBanners extends ConsumerWidget {
  const _ReminderPermissionBanners();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final notificationsEnabled = ref.watch(taskNotificationsEnabledProvider);
    final exactAlarmsAllowed = ref.watch(taskExactAlarmsAllowedProvider);

    final banners = <Widget>[];

    if (notificationsEnabled.valueOrNull == false) {
      banners.add(
        _PermissionBanner(
          title: l10n.taskNotificationsDeniedTitle,
          body: l10n.taskNotificationsDeniedBody,
          actionLabel: l10n.taskNotificationsDeniedAction,
          onAction: () => _openSystemSettings(
            context,
            ref,
            SystemSettingsTarget.notifications,
          ),
        ),
      );
    }

    if (exactAlarmsAllowed.valueOrNull == false) {
      banners.add(
        _PermissionBanner(
          title: l10n.taskExactAlarmMissingTitle,
          body: l10n.taskExactAlarmMissingBody,
          actionLabel: l10n.taskExactAlarmMissingAction,
          // Sem destino próprio pra tela "Alarmes e lembretes" — a ficha
          // do app chega lá com 1–2 toques extras do próprio sistema.
          onAction: () =>
              _openSystemSettings(context, ref, SystemSettingsTarget.app),
        ),
      );
    }

    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        for (final banner in banners) banner,
      ],
    );
  }

  Future<void> _openSystemSettings(
    BuildContext context,
    WidgetRef ref,
    SystemSettingsTarget target,
  ) async {
    HapticFeedback.selectionClick();
    final l10n = ref.read(appLocalizationsProvider);
    final ok = await ref.read(taskSystemSettingsProvider).open(target);
    if (!context.mounted || ok) return;
    showGlassToast(context, l10n.settingsOpenSystemFailed);
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        container: true,
        label: '$title. $body',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(AppRadii.input),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                AppIcons.warning,
                size: 20,
                color: AppColors.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(body, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, kMinTapTarget),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: onAction,
                        child: Text(actionLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
