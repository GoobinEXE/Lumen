import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../routine_mood/presentation/routine_providers.dart';
import '../../routine_mood/presentation/routine_snapshot_card.dart';

class RoutineCalendarScreen extends ConsumerStatefulWidget {
  const RoutineCalendarScreen({super.key});

  @override
  ConsumerState<RoutineCalendarScreen> createState() =>
      _RoutineCalendarScreenState();
}

class _RoutineCalendarScreenState extends ConsumerState<RoutineCalendarScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  Future<void> _openDay(DateTime day) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => _DaySheet(day: day),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final locale = l10n.localeName;
    final marked = ref.watch(markedRoutineDaysProvider).value ?? const {};
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final monthLabel = DateFormat.yMMMM(locale).format(_month);
    final title = monthLabel.isEmpty
        ? monthLabel
        : monthLabel[0].toUpperCase() + monthLabel.substring(1);

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.routineCalendarTitle)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.screenV,
            AppSpacing.screenH,
            28,
          ),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: l10n.routineCalendarPrevious,
                  onPressed: () => _shiftMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.routineCalendarNext,
                  onPressed: () => _shiftMonth(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _MonthGrid(
              month: _month,
              marked: marked,
              localeName: locale,
              isDark: isDark,
              onDay: _openDay,
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySheet extends ConsumerWidget {
  const _DaySheet({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final snapshots = ref.watch(routineRepositoryProvider).getSnapshotsForDate(day);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final locale = l10n.localeName;
    final label = DateFormat.yMMMMEEEEd(locale).format(day);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.sheetTop,
          AppSpacing.screenH,
          AppSpacing.sheetBottom,
        ),
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (snapshots.isEmpty)
            Text(l10n.routineCalendarDayEmpty)
          else
            for (final snapshot in snapshots)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RoutineSnapshotCard(
                  snapshot: snapshot,
                  showDate: true,
                ),
              ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.marked,
    required this.localeName,
    required this.isDark,
    required this.onDay,
  });

  final DateTime month;
  final Set<DateTime> marked;
  final String localeName;
  final bool isDark;
  final ValueChanged<DateTime> onDay;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final start = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final firstSunday0 = first.weekday % 7;
    final leading = (firstSunday0 - start + 7) % 7;
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final labels = List<String>.generate(7, (index) {
      final weekday = DateTime(2024, 1, 7 + ((start + index) % 7));
      return DateFormat.E(localeName).format(weekday);
    });

    return Column(
      children: [
        Row(
          children: [
            for (final label in labels)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leading + days,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemBuilder: (context, index) {
            if (index < leading) return const SizedBox.shrink();
            final day = DateTime(month.year, month.month, index - leading + 1);
            final hasSaved = marked.contains(day);
            final isToday = day == todayDay;
            final ink = isDark ? AppColors.textLight : AppColors.textDark;
            return InkWell(
              onTap: () => onDay(day),
              customBorder: const CircleBorder(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isToday ? AppColors.primary : ink,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: hasSaved ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
