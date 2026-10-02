import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_surface.dart';
import '../../../core/theme/responsive.dart';
import '../../../core/widgets/async_placeholders.dart';

class RecoveryDashboardCard extends ConsumerWidget {
  const RecoveryDashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = ref.watch(appLocalizationsProvider);
    final lastAsync = ref.watch(lastRecoveryProvider);
    final historyAsync = ref.watch(recoveryHistoryProvider);
    final narrow = isNarrow(context);

    return GlassSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(
                    alpha: isDark ? 0.25 : 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.favoriteOutline,
                  color: isDark ? AppColors.primaryLight : AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.recoveryCardTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.recoveryCardSubtitle,
            style: TextStyle(
              fontSize: kMinBodySecondary,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          FadeSwap(
            child: lastAsync.when(
              loading: () => const SlotSkeleton(
                key: ValueKey('recovery-loading'),
                height: 120,
                bars: 3,
              ),
              error: (_, _) => Text(
                key: const ValueKey('recovery-error'),
                l10n.recoveryReadError,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                ),
              ),
              data: (snap) {
                if (snap == null) {
                  return Text(
                    key: const ValueKey('recovery-empty'),
                    l10n.recoveryNoData,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
                    ),
                  );
                }
                final primaryMetrics = [
                  _Metric(
                    label: l10n.labelHrv,
                    value: snap.hrvMs != null
                        ? l10n.unitMilliseconds(snap.hrvMs!.toStringAsFixed(0))
                        : '—',
                    isDark: isDark,
                  ),
                  _Metric(
                    label: l10n.labelRestingHr,
                    value: snap.restingHeartRate != null
                        ? snap.restingHeartRate!.toStringAsFixed(0)
                        : '—',
                    isDark: isDark,
                  ),
                  _Metric(
                    label: l10n.labelSteps,
                    value: snap.steps?.toString() ?? '—',
                    isDark: isDark,
                  ),
                  _Metric(
                    label: l10n.labelExercise,
                    value: snap.exerciseMinutes != null
                        ? l10n.durationMinutes(snap.exerciseMinutes!.round())
                        : '—',
                    isDark: isDark,
                  ),
                ];
                final secondaryMetrics = [
                  _Metric(
                    label: l10n.labelDaylight,
                    value: snap.timeInDaylightMinutes != null
                        ? l10n.durationMinutes(
                            snap.timeInDaylightMinutes!.round(),
                          )
                        : '—',
                    isDark: isDark,
                  ),
                  _Metric(
                    label: l10n.labelAmbientNoise,
                    value: snap.avgEnvironmentalDb != null
                        ? l10n.unitDecibels(
                            snap.avgEnvironmentalDb!.toStringAsFixed(0),
                          )
                        : '—',
                    isDark: isDark,
                  ),
                  _Metric(
                    label: l10n.labelHeadphoneNoise,
                    value: snap.avgHeadphoneDb != null
                        ? l10n.unitDecibels(
                            snap.avgHeadphoneDb!.toStringAsFixed(0),
                          )
                        : '—',
                    isDark: isDark,
                  ),
                ];
                return Column(
                  key: const ValueKey('recovery-data'),
                  children: [
                    _MetricsGrid(metrics: primaryMetrics, narrow: narrow),
                    const SizedBox(height: 10),
                    _MetricsGrid(metrics: secondaryMetrics, narrow: narrow),
                  ],
                );
              },
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: historyAsync.when(
              data: (list) {
                if (list.length < 2) return const SizedBox.shrink();
                final avgSteps = _avg(list.map((e) => e.steps?.toDouble()));
                final avgHrv = _avg(list.map((e) => e.hrvMs));
                final avgLight = _avg(list.map((e) => e.timeInDaylightMinutes));
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    [
                      if (avgHrv != null)
                        l10n.recoveryWeeklyHrv(avgHrv.toStringAsFixed(0)),
                      if (avgSteps != null)
                        l10n.recoveryAvgSteps(avgSteps.toStringAsFixed(0)),
                      if (avgLight != null)
                        l10n.recoveryAvgLight(avgLight.toStringAsFixed(0)),
                    ].join(' · '),
                    style: TextStyle(
                      fontSize: kMinBodySecondary,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
                    ),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 12),
                child: SlotSkeleton(height: 16, bars: 1),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  static double? _avg(Iterable<double?> values) {
    final nums = values.whereType<double>().toList();
    if (nums.isEmpty) return null;
    return nums.reduce((a, b) => a + b) / nums.length;
  }
}

class _MetricsGrid extends StatelessWidget {
  final List<_Metric> metrics;
  final bool narrow;

  const _MetricsGrid({required this.metrics, required this.narrow});

  @override
  Widget build(BuildContext context) {
    if (!narrow) {
      return Row(children: [for (final m in metrics) Expanded(child: m)]);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final m in metrics) SizedBox(width: itemWidth, child: m),
          ],
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _Metric({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: kMinBodySecondary,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
