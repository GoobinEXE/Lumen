import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:noa/l10n/app_localizations.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/correlation_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../routine_mood/domain/mood_entry.dart';
import '../../../routine_mood/domain/routine_export.dart';
import '../../../sleep_analytics/domain/correlation_engine.dart';
import '../../domain/period_export_stats.dart';
import '../../../../integrations/health/models/daily_recovery_snapshot.dart';
import '../../../../integrations/health/models/sleep_record.dart';

class WeeklySummaryCardPreview extends StatelessWidget {
  final GlobalKey repaintKey;
  final String patientName;
  final List<SleepRecord> sleepRecords;
  final List<MoodEntry> moodEntries;
  final List<DailyRecoverySnapshot> recoverySnapshots;
  final List<RoutineExportLine> routineLines;
  final int periodDays;

  const WeeklySummaryCardPreview({
    super.key,
    required this.repaintKey,
    required this.patientName,
    required this.sleepRecords,
    required this.moodEntries,
    this.recoverySnapshots = const [],
    this.routineLines = const [],
    this.periodDays = 7,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textLight : AppColors.textDark;
    final muted = AppColors.mutedText(isDark);
    final border = isDark
        ? AppColors.cardBorderDark
        : AppColors.cardBorderLight;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;

    final stats = PeriodExportStats.from(
      sleepRecords: sleepRecords,
      moodEntries: moodEntries,
      recoverySnapshots: recoverySnapshots,
      routineLines: routineLines,
    );
    final avgSleep = stats.avgSleepHours;
    final deficitNights = stats.deficitNights;
    final paralyzedCount = stats.paralyzedCount;
    final focusedCount = stats.focusedCount;
    final sensoryCount = stats.sensoryCount;
    final medCount = stats.medCount;
    final avgHrv = stats.avgHrv;

    final insights = CorrelationEngine.analyze(
      sleepRecords: sleepRecords,
      moodEntries: moodEntries,
      recoverySnapshots: recoverySnapshots,
      copy: L10nCorrelationCopy(l10n),
    );
    final topInsight = insights.isNotEmpty ? insights.first : null;

    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.shadow).withValues(
                alpha: isDark ? 0.28 : 0.08,
              ),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  AppIcons.spa,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.weeklyCardHeader,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadii.chip),
                  ),
                  child: Text(
                    l10n.weeklyCardLastNDays(periodDays),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              patientName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ink,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.weeklyCardSubtitle,
              style: TextStyle(color: muted, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 12.0;
                final tileWidth = (constraints.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: tileWidth,
                      child: _MetricTile(
                        label: l10n.weeklyCardAvgSleep,
                        value: l10n.sleepHoursValue(
                          avgSleep.toStringAsFixed(1),
                        ),
                        subtitle: l10n.weeklyCardNightsUnder6h(deficitNights),
                        icon: AppIcons.sleep,
                        isDark: isDark,
                        ink: ink,
                        muted: muted,
                        border: border,
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _MetricTile(
                        label: l10n.weeklyCardCheckins,
                        value: '${moodEntries.length}',
                        subtitle: l10n.weeklyCardLastNDays(periodDays),
                        icon: AppIcons.checkin,
                        isDark: isDark,
                        ink: ink,
                        muted: muted,
                        border: border,
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _MetricTile(
                        label: l10n.weeklyCardParalysis,
                        value: l10n.weeklyCardReportsCount(paralyzedCount),
                        subtitle: l10n.weeklyCardStuckMoments,
                        icon: AppIcons.block,
                        isDark: isDark,
                        ink: ink,
                        muted: muted,
                        border: border,
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _MetricTile(
                        label: l10n.weeklyCardFluidFocus,
                        value: l10n.weeklyCardReportsCount(focusedCount),
                        subtitle: l10n.weeklyCardGoodConcentration,
                        icon: AppIcons.focusTarget,
                        isDark: isDark,
                        ink: ink,
                        muted: muted,
                        border: border,
                      ),
                    ),
                    if (sensoryCount > 0)
                      SizedBox(
                        width: tileWidth,
                        child: _MetricTile(
                          label: l10n.weeklyCardSensory,
                          value: l10n.weeklyCardReportsCount(sensoryCount),
                          subtitle: l10n.weeklyCardLastNDays(periodDays),
                          icon: AppIcons.headphones,
                          isDark: isDark,
                          ink: ink,
                          muted: muted,
                          border: border,
                        ),
                      ),
                    if (medCount > 0)
                      SizedBox(
                        width: tileWidth,
                        child: _MetricTile(
                          label: l10n.weeklyCardMedToggle,
                          value: l10n.weeklyCardReportsCount(medCount),
                          subtitle: l10n.weeklyCardLastNDays(periodDays),
                          icon: AppIcons.medication,
                          isDark: isDark,
                          ink: ink,
                          muted: muted,
                          border: border,
                        ),
                      ),
                    if (avgHrv != null)
                      SizedBox(
                        width: tileWidth,
                        child: _MetricTile(
                          label: l10n.weeklyCardRecoveryHrv,
                          value: l10n.unitMilliseconds(
                            avgHrv.toStringAsFixed(0),
                          ),
                          subtitle: l10n.weeklyCardLastNDays(periodDays),
                          icon: AppIcons.health,
                          isDark: isDark,
                          ink: ink,
                          muted: muted,
                          border: border,
                        ),
                      ),
                  ],
                );
              },
            ),
            if (topInsight != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppRadii.input),
                  border: Border.all(color: border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      AppIcons.forInsight(topInsight.iconKey),
                      color: isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topInsight.title,
                            style: TextStyle(
                              color: ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            topInsight.description,
                            style: TextStyle(
                              color: muted,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (routineLines.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.exportRoutineHeading,
                style: TextStyle(
                  color: ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.exportRoutineCount(routineLines.length),
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              for (final line in routineLines.take(8))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    l10n.homeRoutineSnapshotLine(
                      DateFormat('HH:mm', l10n.localeName).format(line.savedAt),
                      line.anchor.isEmpty
                          ? l10n.exportRoutineAnchorEmpty
                          : line.anchor,
                    ),
                    style: TextStyle(color: ink, fontSize: 13, height: 1.3),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    l10n.weeklyCardSyncedFooter,
                    style: TextStyle(color: muted, fontSize: 12, height: 1.35),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.16)
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadii.chip),
                  ),
                  child: Text(
                    l10n.weeklyCardPersonalUse,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.isDark,
    required this.ink,
    required this.muted,
    required this.border,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool isDark;
  final Color ink;
  final Color muted;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppRadii.input),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
            size: 18,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: ink,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: muted, fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }
}
