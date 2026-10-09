import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noa/l10n/app_localizations.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../medications/domain/medication.dart';
import '../../routine_mood/domain/mood_entry.dart';
import '../../../integrations/health/models/sleep_record.dart';
import '../data/user_profile_repository.dart';
import '../domain/user_profile.dart';
import 'profile_navigation.dart';

class ProfileSheetCard extends ConsumerWidget {
  const ProfileSheetCard({
    super.key,
    required this.profile,
    required this.displayName,
    required this.medications,
    required this.sleepRecords,
    required this.moodEntries,
    required this.periodDays,
    required this.therapistPhone,
    required this.onEditPhone,
  });

  final UserProfile profile;
  final String displayName;
  final List<Medication> medications;
  final List<SleepRecord> sleepRecords;
  final List<MoodEntry> moodEntries;
  final int periodDays;
  final String therapistPhone;
  final VoidCallback onEditPhone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final ink = isDark ? AppColors.textLight : AppColors.textDark;
    final muted = AppColors.mutedText(isDark);
    final border = isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;

    final avgSleep = sleepRecords.isEmpty
        ? null
        : sleepRecords.map((s) => s.totalHours).reduce((a, b) => a + b) /
            sleepRecords.length;
    final summary = [
      l10n.profileSummaryCheckins(moodEntries.length),
      if (avgSleep != null) l10n.profileSummarySleep(avgSleep.toStringAsFixed(1)),
    ].join(' · ');
    final medNames = medications.map((m) => m.name).where((n) => n.trim().isNotEmpty).toList();
    final phone = therapistPhone.trim();

    return Container(
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
        children: [
          Row(
            children: [
              Icon(
                AppIcons.person,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.profileSheetTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ),
              Text(
                l10n.weeklyCardLastNDays(periodDays),
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.profileSheetSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _editName(context, ref, l10n, profile),
            borderRadius: BorderRadius.circular(AppRadii.input),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: ink,
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (profile.trimmedName == null)
                          Text(
                            l10n.profileNameEmpty,
                            style: TextStyle(color: muted, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  Icon(AppIcons.edit, size: 18, color: muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: AppIcons.medication,
            label: l10n.profileMedsLabel,
            value: medNames.isEmpty
                ? l10n.profileMedsEmpty
                : '${l10n.profileMedsCount(medNames.length)} · ${medNames.join(', ')}',
            ink: ink,
            muted: muted,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: AppIcons.chat,
            label: l10n.profileTherapistPhoneLabel,
            value: phone.isEmpty ? l10n.profileTherapistPhoneEmpty : phone,
            ink: ink,
            muted: muted,
            onTap: onEditPhone,
          ),
          const SizedBox(height: 16),
          Divider(color: border),
          const SizedBox(height: 12),
          Text(
            summary,
            style: TextStyle(color: ink, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => openProfileScreen(context),
              icon: Icon(AppIcons.person, size: 18),
              label: Text(l10n.profileViewProfileCta),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    UserProfile profile,
  ) async {
    final controller = TextEditingController(text: profile.trimmedName ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.profileEditNameTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.profileNameLabel,
              hintText: l10n.profileNameHint,
            ),
            onSubmitted: (value) => Navigator.pop(ctx, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(l10n.profileNameSave),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (saved == null) return;
    HapticFeedback.lightImpact();
    await ref.read(userProfileProvider.notifier).updateName(saved);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.ink,
    required this.muted,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color ink;
  final Color muted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: muted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(color: ink, fontSize: 14, height: 1.35),
              ),
            ],
          ),
        ),
        if (onTap != null) Icon(AppIcons.edit, size: 16, color: muted),
      ],
    );
    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.input),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: child,
      ),
    );
  }
}
