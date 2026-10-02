import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/responsive.dart';
import '../../domain/efficacy_window.dart';
import '../../domain/medication_log.dart';

class EfficacyWindowBar extends ConsumerWidget {
  final MedicationLog log;
  final int durationHours;

  const EfficacyWindowBar({
    super.key,
    required this.log,
    this.durationHours = 12,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (log.takenAt == null) return const SizedBox.shrink();

    final l10n = ref.watch(appLocalizationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final takenTime = log.takenAt!;
    final window = EfficacyWindow.ofDose(
      takenAt: takenTime,
      durationHours: durationHours,
    );
    final peakStart = window.peakStart;
    final peakEnd = window.peakEnd;
    final crashTime = window.crashTime;

    final timeFormat = DateFormat.Hm(l10n.localeName);
    final now = DateTime.now();
    final isPastCrash = now.isAfter(crashTime);
    final isInPeak = now.isAfter(peakStart) && now.isBefore(peakEnd);

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(AppRadii.input),
          border: Border.all(
            color: isDark
                ? AppColors.cardBorderDark
                : AppColors.cardBorderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  AppIcons.unstuck,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.efficacyWindowTitle(durationHours),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: kMinBodySecondary,
                    ),
                  ),
                ),
                if (isInPeak)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadii.chip),
                      ),
                      child: Text(
                        l10n.efficacyPeakNow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: kMinBodySecondary,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                else if (isPastCrash)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadii.chip),
                      ),
                      child: Text(
                        l10n.efficacyEnded,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: kMinBodySecondary,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: const SizedBox(
                height: 12,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.peak,
                        AppColors.unstuck,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.efficacyTakenAt(timeFormat.format(takenTime)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: kMinBodySecondary,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.efficacyPeakRange(
                      timeFormat.format(peakStart),
                      timeFormat.format(peakEnd),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: kMinBodySecondary,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.efficacyEndAt(timeFormat.format(crashTime)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: kMinBodySecondary,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),

            if (now.isAfter(peakEnd) &&
                now.isBefore(crashTime.add(const Duration(hours: 2)))) ...[
              const SizedBox(height: 8),
              Text(
                l10n.efficacyAdhdTip,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: kMinBodySecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
