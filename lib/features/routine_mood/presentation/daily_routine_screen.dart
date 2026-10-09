import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_surface.dart';
import '../../../core/theme/lumen_glass_style.dart';
import '../../../core/theme/responsive.dart';
import '../../../core/widgets/async_placeholders.dart';
import '../../../core/widgets/lumen_shell.dart';
import '../../tasks/domain/task_item.dart';
import '../../tasks/domain/task_period.dart';
import '../../tasks/presentation/task_providers.dart';
import '../../unstuck_assistant/presentation/unstuck_sheet.dart';
import '../domain/daily_routine_state.dart';
import '../domain/routine_snapshot.dart';
import 'check_in_form.dart';
import 'routine_providers.dart';
import 'routine_snapshot_card.dart';

export 'routine_providers.dart';
import '../../../core/widgets/glass_icon_button.dart';
import '../../../core/widgets/glass_nav_bar.dart';
import '../../../core/widgets/glass_toast.dart';

class DailyRoutineScreen extends ConsumerStatefulWidget {
  const DailyRoutineScreen({super.key});

  @override
  ConsumerState<DailyRoutineScreen> createState() => _DailyRoutineScreenState();
}

class _DailyRoutineScreenState extends ConsumerState<DailyRoutineScreen> {
  DailyRoutineState? _state;
  final TextEditingController _eveningController = TextEditingController();
  final TextEditingController _therapistNotesController =
      TextEditingController();
  final GlobalKey<CheckInFormState> _checkInKey = GlobalKey<CheckInFormState>();
  String? _anchorTaskId;
  bool _initialized = false;
  bool _isSaving = false;

  void _initFromState(DailyRoutineState state) {
    if (_initialized) return;
    _state = state;
    _eveningController.text = state.eveningReflection;
    _therapistNotesController.text = state.therapistNotes ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _eveningController.dispose();
    _therapistNotesController.dispose();
    super.dispose();
  }

  String _anchorTitleFromTasks(List<TaskItem> tasks) {
    if (_anchorTaskId == null) return '';
    for (final task in tasks) {
      if (task.id == _anchorTaskId) return task.title.trim();
    }
    return '';
  }

  Future<void> _saveRoutine(
    DailyRoutineState current,
    AppLocalizations l10n,
  ) async {
    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();
    final tasks = ref.read(tasksListProvider).value ?? const [];
    final taskRepo = ref.read(taskRepositoryProvider);
    final savedAt = DateTime.now();
    final checkIn = _checkInKey.currentState?.draft() ?? const CheckInDraft();
    final som = checkIn.toStateOfMind(timestamp: savedAt);
    final draft = (_state ?? current).copyWith(
      mainFocusAnchor: _anchorTitleFromTasks(tasks),
      therapistNotes: _therapistNotesController.text.trim(),
      eveningReflection: _eveningController.text.trim(),
      microHabits: taskRepo.titles(tasks),
      completedHabits: taskRepo.completedTitles(tasks, savedAt),
      stateOfMind: som,
      tookPrescribedMedication:
          (_state ?? current).tookPrescribedMedication ||
          checkIn.tookMedication,
    );
    final snapshot = RoutineSnapshot.capture(
      id: const Uuid().v4(),
      savedAt: savedAt,
      draft: draft,
    );

    await ref
        .read(moodEntriesProvider.notifier)
        .addEntry(
          valence: checkIn.valence,
          energy: checkIn.energy,
          focus: checkIn.focus,
          tookMedication: checkIn.tookMedication,
          sensoryOverload: checkIn.sensoryOverload,
          note: checkIn.note.isEmpty ? null : checkIn.note,
          emotionLabels: checkIn.emotionLabels,
          timestamp: savedAt,
        );
    // SoM do snapshot usa o mesmo timestamp do MoodEntry → ledger evita espelho duplo.
    await ref.read(routineHealthMirrorProvider.notifier).saveSnapshot(snapshot);

    final cleared = DailyRoutineState(
      date: DateTime(savedAt.year, savedAt.month, savedAt.day),
      microHabits: List<String>.from(draft.microHabits),
      // Água é acumulada do dia civil; save não pode zerar o contador.
      waterGlasses: draft.waterGlasses,
    );

    if (mounted) {
      _eveningController.clear();
      _therapistNotesController.clear();
      _checkInKey.currentState?.reset();
      setState(() {
        _state = cleared;
        _anchorTaskId = null;
        _isSaving = false;
      });
      showGlassToast(context, l10n.routineSavedSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = ref.watch(appLocalizationsProvider);
    final routineAsync = ref.watch(todayRoutineDraftProvider);
    final snapshots = ref.watch(todaySnapshotsProvider).value ?? const [];
    final tasksAsync = ref.watch(tasksListProvider);

    return PopScope(
      canPop: true,
      child: Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: false,
          child: routineAsync.when(
          loading: () => const FormSkeleton(),
          error: (err, stack) =>
              Center(child: Text(l10n.errorWithDetails('$err'))),
          data: (loadedState) {
            _initFromState(loadedState);
            final current = _state ?? loadedState;
            final todayFormatted = DateFormat(
              l10n.dateFormatFullPattern,
              l10n.localeName,
            ).format(DateTime.now());

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                12,
                AppSpacing.screenH,
                GlassNavBar.reservedBottom(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayFormatted.substring(0, 1).toUpperCase() +
                        todayFormatted.substring(1),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.routineCompassTitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GlassIconButton(
                        tooltip: l10n.homeMyDaysTitle,
                        icon: AppIcons.calendar,
                        onPressed: () => openRoutineCalendarScreen(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.routineCompassSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassSurface(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.card,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          AppIcons.unstuck,
                          size: 20,
                          color: AppColors.unstuck,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.diaUnstuckPrompt,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => UnstuckSheet.show(context),
                          child: Text(l10n.diaUnstuckOpen),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    context: context,
                    icon: AppIcons.checkin,
                    title: l10n.checkinSectionTitle,
                    subtitle: l10n.checkinSectionSubtitle,
                    child: RepaintBoundary(
                      child: CheckInForm(
                        key: _checkInKey,
                        // epoch força formulário limpo após salvar
                        // Android: halo animado + dezenas de GlassChip = jank no scroll.
                        showHalo: !lumenGlassAndroidLite(),
                        showFeelingHeader: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    context: context,
                    icon: AppIcons.tasks,
                    title: l10n.microHabitsTitle,
                    subtitle: l10n.dayChecklistSubtitle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        tasksAsync.when(
                      loading: () => const FormSkeleton(),
                      error: (err, stack) =>
                          Text(l10n.errorWithDetails('$err')),
                      data: (tasks) {
                        final now = DateTime.now();
                        final todayTasks = tasks
                            .where((t) => TaskPeriod.appliesOn(t, now))
                            .toList();
                        if (todayTasks.isEmpty) {
                          return Text(
                            l10n.tasksHubEmptyToday,
                            style: theme.textTheme.bodyMedium,
                          );
                        }
                        return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      l10n.dayFocusSubtitle,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.textMutedDark
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: todayTasks.length,
                                    itemBuilder: (context, index) {
                                      final task = todayTasks[index];
                                      final isDone =
                                          TaskPeriod.isCompletedInCurrentPeriod(
                                            task,
                                            now,
                                          );
                                      final isAnchor = _anchorTaskId == task.id;
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: Semantics(
                                              checked: isDone,
                                              label: task.title,
                                              child: CheckboxListTile(
                                                value: isDone,
                                                title: Text(
                                                  task.title,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: isAnchor
                                                        ? FontWeight.w700
                                                        : FontWeight.w400,
                                                    decoration: isDone
                                                        ? TextDecoration
                                                              .lineThrough
                                                        : null,
                                                  ),
                                                ),
                                                subtitle: task.timeOfDay == null
                                                    ? (isAnchor
                                                          ? Text(
                                                              l10n.taskDayAnchorBadge,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: AppColors
                                                                    .primary,
                                                              ),
                                                            )
                                                          : null)
                                                    : Text(
                                                        isAnchor
                                                            ? '${l10n.taskReminderChip(task.timeOfDay!)} · ${l10n.taskDayAnchorBadge}'
                                                            : l10n.taskReminderChip(
                                                                task.timeOfDay!,
                                                              ),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: isDark
                                                              ? AppColors
                                                                    .textMutedDark
                                                              : AppColors
                                                                    .textMuted,
                                                        ),
                                                      ),
                                                activeColor: AppColors.primary,
                                                contentPadding: EdgeInsets.zero,
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                                onChanged: (_) async {
                                                  HapticFeedback.selectionClick();
                                                  await ref
                                                      .read(
                                                        tasksListProvider
                                                            .notifier,
                                                      )
                                                      .toggleComplete(task);
                                                },
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: l10n.taskDayAnchorTooltip,
                                            constraints: const BoxConstraints(
                                              minWidth: kMinTapTarget,
                                              minHeight: kMinTapTarget,
                                            ),
                                            onPressed: () {
                                              HapticFeedback.selectionClick();
                                              setState(() {
                                                _anchorTaskId = isAnchor
                                                    ? null
                                                    : task.id;
                                              });
                                            },
                                            icon: Icon(
                                              isAnchor
                                                  ? AppIcons.anchor
                                                  : Icons.anchor_outlined,
                                              size: 20,
                                              color: isAnchor
                                                  ? AppColors.primary
                                                  : (isDark
                                                        ? AppColors
                                                              .textMutedDark
                                                        : AppColors.textMuted),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              );
                      },
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, kMinTapTarget),
                            ),
                            onPressed: () => openTasksHub(context),
                            icon: const Icon(AppIcons.tasks, size: 18),
                            label: Text(l10n.tasksHubOpenFromDay),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    context: context,
                    icon: AppIcons.water,
                    title: l10n.waterAndMedsTitle,
                    subtitle: l10n.routineBioCareSubtitle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                l10n.waterGlassesLabel,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(current.waterGlasses * 250).clamp(0, 2000)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              l10n.waterGoalSuffix,
                              style: TextStyle(
                                color: AppColors.mutedText(isDark),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            for (var i = 0; i < 8; i++)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  AppIcons.water,
                                  size: 22,
                                  color: i < current.waterGlasses
                                      ? AppColors.primary
                                      : AppColors.mutedText(
                                          isDark,
                                        ).withValues(alpha: 0.35),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  constraints: const BoxConstraints(
                                    minWidth: kMinTapTarget,
                                    minHeight: kMinTapTarget,
                                  ),
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: current.waterGlasses > 0
                                      ? () => setState(
                                          () => _state = _state?.copyWith(
                                            waterGlasses:
                                                current.waterGlasses - 1,
                                          ),
                                        )
                                      : null,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${current.waterGlasses}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      AppIcons.water,
                                      size: 18,
                                      color: isDark
                                          ? AppColors.primaryLight
                                          : AppColors.primary,
                                    ),
                                  ],
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(
                                    minWidth: kMinTapTarget,
                                    minHeight: kMinTapTarget,
                                  ),
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => setState(
                                    () => _state = _state?.copyWith(
                                      waterGlasses: current.waterGlasses + 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SwitchListTile(
                          value: current.tookPrescribedMedication,
                          activeThumbColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l10n.prescribedMedTakenLabel,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            l10n.prescribedMedTakenHint,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onChanged: (val) => setState(
                            () => _state = _state?.copyWith(
                              tookPrescribedMedication: val,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    context: context,
                    icon: AppIcons.couch,
                    title: l10n.eveningReflectionTitle,
                    subtitle: l10n.eveningReflectionSubtitle,
                    child: TextField(
                      controller: _eveningController,
                      onChanged: (val) =>
                          _state = _state?.copyWith(eveningReflection: val),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: l10n.eveningReflectionHint,
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.input),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    context: context,
                    icon: AppIcons.therapist,
                    title: l10n.therapistNotesTitle,
                    subtitle: l10n.therapistNotesSubtitle,
                    child: TextField(
                      controller: _therapistNotesController,
                      onChanged: (val) =>
                          _state = _state?.copyWith(therapistNotes: val),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: l10n.therapistNotesHint,
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.input),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? () {}
                          : () => _saveRoutine(current, l10n),
                      child: _isSaving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Theme.of(context)
                                        .elevatedButtonTheme
                                        .style
                                        ?.foregroundColor
                                        ?.resolve({}) ??
                                    Colors.white,
                              ),
                            )
                          : Text(l10n.saveRoutineButton),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.routineTimelineTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.routineTimelineSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (snapshots.isEmpty)
                    Text(
                      l10n.routineTimelineEmpty,
                      style: theme.textTheme.bodyMedium,
                    )
                  else
                    for (final snapshot in snapshots)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RoutineSnapshotCard(snapshot: snapshot),
                      ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
