import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_surface.dart';
import '../../../core/theme/responsive.dart';
import '../../../core/widgets/async_placeholders.dart';
import '../../calendar/presentation/routine_calendar_screen.dart';
import '../../state_of_mind/presentation/state_of_mind_editor.dart';
import '../domain/daily_routine_state.dart';
import '../domain/routine_snapshot.dart';
import 'routine_providers.dart';
import 'routine_snapshot_card.dart';

export 'routine_providers.dart';

class DailyRoutineScreen extends ConsumerStatefulWidget {
  const DailyRoutineScreen({super.key});

  @override
  ConsumerState<DailyRoutineScreen> createState() => _DailyRoutineScreenState();
}

class _DailyRoutineScreenState extends ConsumerState<DailyRoutineScreen> {
  DailyRoutineState? _state;
  final TextEditingController _anchorController = TextEditingController();
  final TextEditingController _eveningController = TextEditingController();
  final TextEditingController _therapistNotesController =
      TextEditingController();
  final TextEditingController _newHabitController = TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;
  bool _addingHabit = false;
  int _draftEpoch = 0;

  void _initFromState(DailyRoutineState state) {
    if (_initialized) return;
    _state = state;
    _anchorController.text = state.mainFocusAnchor;
    _eveningController.text = state.eveningReflection;
    _therapistNotesController.text = state.therapistNotes ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _anchorController.dispose();
    _eveningController.dispose();
    _therapistNotesController.dispose();
    _newHabitController.dispose();
    super.dispose();
  }

  Future<void> _saveRoutine(
    DailyRoutineState current,
    AppLocalizations l10n,
  ) async {
    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();
    final draft = (_state ?? current).copyWith(
      mainFocusAnchor: _anchorController.text.trim(),
      therapistNotes: _therapistNotesController.text.trim(),
      eveningReflection: _eveningController.text.trim(),
    );
    final savedAt = DateTime.now();
    final snapshot = RoutineSnapshot.capture(
      id: const Uuid().v4(),
      savedAt: savedAt,
      draft: draft,
    );
    await ref.read(routineHealthMirrorProvider.notifier).saveSnapshot(snapshot);

    final cleared = DailyRoutineState(
      date: DateTime(savedAt.year, savedAt.month, savedAt.day),
      microHabits: List<String>.from(draft.microHabits),
    );

    if (mounted) {
      _anchorController.clear();
      _eveningController.clear();
      _therapistNotesController.clear();
      setState(() {
        _state = cleared;
        _draftEpoch++;
        _isSaving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.routineSavedSuccess)));
    }
  }

  void _removeHabit(String habit, DailyRoutineState current) {
    final habits = List<String>.from(current.microHabits)..remove(habit);
    final completed = Set<String>.from(current.completedHabits)..remove(habit);
    setState(
      () => _state = _state?.copyWith(
        microHabits: habits,
        completedHabits: completed,
      ),
    );
  }

  void _addHabit(DailyRoutineState current) {
    final l10n = ref.read(appLocalizationsProvider);
    final text = _newHabitController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.habitEmptyError)));
      return;
    }
    if (current.microHabits.contains(text)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.habitDuplicateError)));
      return;
    }
    final habits = List<String>.from(current.microHabits)..add(text);
    setState(() {
      _state = _state?.copyWith(microHabits: habits);
      _addingHabit = false;
      _newHabitController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = ref.watch(appLocalizationsProvider);
    final languageCode = ref.watch(activeLocaleProvider).languageCode;
    final routineAsync = ref.watch(todayRoutineDraftProvider);
    final snapshots = ref.watch(todaySnapshotsProvider).value ?? const [];

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.routineAppBarTitle),
          actions: [
            IconButton(
              tooltip: l10n.routineCalendarTitle,
              icon: const Icon(AppIcons.calendar),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RoutineCalendarScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: routineAsync.when(
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.screenV,
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
                  Text(
                    l10n.routineCompassTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    context: context,
                    icon: AppIcons.anchor,
                    title: l10n.routineAnchorLabel,
                    subtitle: l10n.routineAnchorSubtitle,
                    child: TextField(
                      controller: _anchorController,
                      onChanged: (val) =>
                          _state = _state?.copyWith(mainFocusAnchor: val),
                      decoration: InputDecoration(
                        hintText: l10n.routineAnchorHint,
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
                    icon: AppIcons.sunrise,
                    title: l10n.routineEmotionalStateTitle,
                    subtitle: l10n.routineEmotionalStateSubtitle,
                    child: StateOfMindEditor(
                      key: ValueKey(_draftEpoch),
                      initial: current.stateOfMind,
                      languageCode: languageCode,
                      onChanged: (entry) {
                        setState(
                          () => _state = _state?.copyWith(stateOfMind: entry),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    context: context,
                    icon: AppIcons.tasks,
                    title: l10n.microHabitsTitle,
                    subtitle: l10n.routineMicroHabitsSubtitle,
                    child: Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: current.microHabits.length,
                          itemBuilder: (context, index) {
                            final habit = current.microHabits[index];
                            final isDone = current.completedHabits.contains(
                              habit,
                            );
                            return Row(
                              children: [
                                Expanded(
                                  child: CheckboxListTile(
                                    value: isDone,
                                    title: Text(
                                      habit,
                                      style: TextStyle(
                                        fontSize: 14,
                                        decoration: isDone
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    activeColor: AppColors.primary,
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    onChanged: (val) {
                                      final updated = Set<String>.from(
                                        current.completedHabits,
                                      );
                                      if (val == true) {
                                        updated.add(habit);
                                      } else {
                                        updated.remove(habit);
                                      }
                                      setState(
                                        () => _state = _state?.copyWith(
                                          completedHabits: updated,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                IconButton(
                                  tooltip: l10n.removeTooltip,
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    size: 20,
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMuted,
                                  ),
                                  onPressed: () => _removeHabit(habit, current),
                                ),
                              ],
                            );
                          },
                        ),
                        if (_addingHabit) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newHabitController,
                                  autofocus: true,
                                  onSubmitted: (_) => _addHabit(current),
                                  decoration: InputDecoration(
                                    hintText: l10n.microHabitHint,
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.03),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.input,
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline),
                                color: AppColors.primary,
                                onPressed: () => _addHabit(current),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(() {
                                  _addingHabit = false;
                                  _newHabitController.clear();
                                }),
                              ),
                            ],
                          ),
                        ] else
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, kMinTapTarget),
                              ),
                              onPressed: () =>
                                  setState(() => _addingHabit = true),
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(l10n.addMicroHabitButton),
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
