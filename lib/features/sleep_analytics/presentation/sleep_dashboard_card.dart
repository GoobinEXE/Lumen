import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/providers.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_surface.dart';
import '../../../core/theme/responsive.dart';
import '../../../core/widgets/async_placeholders.dart';
import '../../../core/widgets/glass_toast.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';
import '../../health_sync/data/health_sync_prefs.dart';
import '../../health_sync/presentation/health_sync_consent_sheet.dart';

class SleepDashboardCard extends ConsumerWidget {
  const SleepDashboardCard({super.key});

  Future<void> _onSyncPressed(BuildContext context, WidgetRef ref) async {
    final l10n = ref.read(appLocalizationsProvider);
    final result = await HealthSyncConsentSheet.show(context);
    if (!context.mounted) return;

    final android = !kIsWeb && Platform.isAndroid;
    if (result == true) {
      showGlassToast(
        context,
        android
            ? l10n.healthSyncSuccessMessageAndroid
            : l10n.healthSyncSuccessMessage,
      );
    } else if (result == false) {
      showGlassToast(
        context,
        android
            ? l10n.healthSyncDeniedMessageAndroid
            : l10n.healthSyncDeniedMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = ref.watch(appLocalizationsProvider);
    final lastNightAsync = ref.watch(lastNightSleepProvider);
    final healthService = ref.watch(healthServiceProvider);
    final syncEnabled = ref.watch(healthSyncEnabledProvider);
    final sourceName = healthService.sourceName(l10n);
    final narrow = isNarrow(context);

    final syncTooltip = syncEnabled
        ? l10n.healthSyncConnectedLabel
        : l10n.syncHealthButton;
    final syncIcon = Icon(
      syncEnabled ? Icons.sync_rounded : Icons.link_rounded,
      size: 18,
    );

    final titleBlock = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.sleepRem.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.input),
          ),
          child: const Icon(
            AppIcons.sleep,
            color: AppColors.sleepRem,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.sleepCardTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                syncEnabled
                    ? '$sourceName · ${l10n.healthSyncConnectedLabel}'
                    : sourceName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontSize: kMinBodySecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return GlassSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (narrow) ...[
              titleBlock,
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: syncTooltip,
                  constraints: const BoxConstraints(
                    minWidth: kMinTapTarget,
                    minHeight: kMinTapTarget,
                  ),
                  onPressed: () => _onSyncPressed(context, ref),
                  icon: syncIcon,
                ),
              ),
            ] else
              Row(
                children: [
                  Expanded(child: titleBlock),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, kMinTapTarget),
                    ),
                    onPressed: () => _onSyncPressed(context, ref),
                    icon: syncIcon,
                    label: Text(
                      syncTooltip,
                      style: const TextStyle(fontSize: kMinBodySecondary),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            FadeSwap(
              child: lastNightAsync.when(
                loading: () => const SlotSkeleton(
                  key: ValueKey('sleep-loading'),
                  height: 140,
                  bars: 3,
                ),
                error: (err, stack) => Text(
                  key: const ValueKey('sleep-error'),
                  l10n.errorLoadingSleep('$err'),
                ),
                data: (sleep) {
                  if (sleep == null) {
                    return Column(
                      key: const ValueKey('sleep-empty'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sleepNoDataTitle,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          !kIsWeb && Platform.isAndroid
                              ? l10n.sleepNoDataHintAndroid
                              : l10n.sleepNoDataHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedText(isDark),
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    key: const ValueKey('sleep-data'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Text(
                            SleepRecord.formatDuration(sleep.totalSleep),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: sleep.hasSleepDeficit
                                  ? AppColors.warning
                                  : AppColors.primary,
                            ),
                          ),
                          Text(
                            l10n.totalSleepLabel,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.primary.withValues(alpha: 0.25)
                                  : AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(
                                AppRadii.input,
                              ),
                            ),
                            child: Text(
                              l10n.sleepScoreLabel(sleep.qualityScore),
                              style: TextStyle(
                                fontSize: kMinBodySecondary,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: sleep.averageHeartRate != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  l10n.sleepAvgNightHr(
                                    '${sleep.averageHeartRate}',
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.mutedText(isDark),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 14),
                      RepaintBoundary(child: _buildSleepStagesBar(sleep)),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildStageLegend(
                            l10n.stageDeep,
                            sleep.deepSleep,
                            AppColors.sleepDeep,
                            isDark,
                          ),
                          _buildStageLegend(
                            l10n.stageRem,
                            sleep.remSleep,
                            AppColors.sleepRem,
                            isDark,
                          ),
                          _buildStageLegend(
                            l10n.stageLight,
                            sleep.lightSleep,
                            AppColors.sleepLight,
                            isDark,
                          ),
                          _buildStageLegend(
                            l10n.stageAwake,
                            sleep.awakeDuration,
                            AppColors.sleepAwake,
                            isDark,
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: sleep.hasRemDeficit
                            ? Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.input,
                                    ),
                                    border: Border.all(
                                      color: AppColors.warning.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        AppIcons.warning,
                                        size: 18,
                                        color: AppColors.warning,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${l10n.remDeficitAlert} (${SleepRecord.formatDuration(sleep.remSleep)})',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildSleepStagesBar(SleepRecord sleep) {
    final totalMinutes =
        sleep.totalSleep.inMinutes + sleep.awakeDuration.inMinutes;
    if (totalMinutes <= 0) return const SizedBox.shrink();

    final deepFlex = (sleep.deepSleep.inMinutes / totalMinutes * 100)
        .round()
        .clamp(1, 100);
    final remFlex = (sleep.remSleep.inMinutes / totalMinutes * 100)
        .round()
        .clamp(1, 100);
    final lightFlex = (sleep.lightSleep.inMinutes / totalMinutes * 100)
        .round()
        .clamp(1, 100);
    final awakeFlex = (sleep.awakeDuration.inMinutes / totalMinutes * 100)
        .round()
        .clamp(1, 100);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            Expanded(
              flex: deepFlex,
              child: Container(color: AppColors.sleepDeep),
            ),
            Expanded(
              flex: remFlex,
              child: Container(color: AppColors.sleepRem),
            ),
            Expanded(
              flex: lightFlex,
              child: Container(color: AppColors.sleepLight),
            ),
            Expanded(
              flex: awakeFlex,
              child: Container(color: AppColors.sleepAwake),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageLegend(
    String name,
    Duration duration,
    Color color,
    bool isDark,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$name: ${SleepRecord.formatDuration(duration)}',
          style: TextStyle(
            fontSize: kMinBodySecondary,
            color: AppColors.mutedText(isDark),
          ),
        ),
      ],
    );
  }
}
