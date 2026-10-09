import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:noa/l10n/app_localizations.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_surface.dart';
import '../../../core/widgets/async_placeholders.dart';
import '../../../core/widgets/lumen_shell.dart';
import '../../calendar/presentation/day_digest_sheet.dart';
import '../../onboarding/domain/onboarding_profile_draft.dart';
import '../../onboarding/presentation/onboarding_profile_form.dart';
import '../data/user_profile_repository.dart';
import '../domain/profile_feed_item.dart';
import '../domain/user_profile.dart';
import 'profile_feed_providers.dart';
import 'profile_labels.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/glass_nav_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider);
    final feedAsync = ref.watch(profileFeedProvider);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(l10n.profileScreenTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsOpenTooltip,
            icon: const Icon(AppIcons.settings),
            onPressed: () => openSettingsScreen(context),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: feedAsync.when(
          loading: () => ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.screenV,
              AppSpacing.screenH,
              GlassNavBar.reservedBottom(context),
            ),
            children: [
              _ProfileHeaderCard(profile: profile),
              const SizedBox(height: 20),
              const SlotSkeleton(height: 72, bars: 2),
              const SizedBox(height: 16),
              const SlotSkeleton(height: 72, bars: 2),
            ],
          ),
          error: (err, _) => ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.screenV,
              AppSpacing.screenH,
              GlassNavBar.reservedBottom(context),
            ),
            children: [
              _ProfileHeaderCard(profile: profile),
              const SizedBox(height: 20),
              Text(l10n.errorWithDetails('$err')),
            ],
          ),
          data: (items) {
            return ListView.builder(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.screenV,
                AppSpacing.screenH,
                GlassNavBar.reservedBottom(context),
              ),
              itemCount: items.isEmpty ? 3 : items.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _ProfileHeaderCard(profile: profile);
                }
                if (index == 1) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
                    child: Text(
                      l10n.profileFeedTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }
                if (items.isEmpty) {
                  return Text(
                    l10n.profileFeedEmpty,
                    style: theme.textTheme.bodyMedium,
                  );
                }
                final item = items[index - 2];
                return _FeedTile(
                  item: item,
                  l10n: l10n,
                  onTap: () => showDayDigestSheet(context, item.civilDay),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends ConsumerWidget {
  const _ProfileHeaderCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = ref.watch(appLocalizationsProvider);
    final ink = isDark ? AppColors.textLight : AppColors.textDark;
    final muted = AppColors.mutedText(isDark);
    final displayName = profileDisplayName(profile, l10n.greetingName);

    final chips = <Widget>[];
    final age = profile.ageYears;
    if (age != null) {
      chips.add(_InfoChip(icon: AppIcons.person, label: l10n.profileAgeYears(age)));
    }
    final height = profile.heightCm;
    if (height != null) {
      chips.add(_InfoChip(
        icon: AppIcons.favoriteOutline,
        label: l10n.profileHeightChip(_metricText(height)),
      ));
    }
    final weight = profile.weightKg;
    if (weight != null) {
      chips.add(_InfoChip(
        icon: AppIcons.favoriteOutline,
        label: l10n.profileWeightChip(_metricText(weight)),
      ));
    }
    final sex = profile.biologicalSex;
    if (sex != null && sex.isNotEmpty) {
      chips.add(_InfoChip(
        icon: AppIcons.person,
        label: biologicalSexLabel(l10n, sex),
      ));
    }
    chips.add(_InfoChip(
      icon: AppIcons.chat,
      label: voiceToneLabel(l10n, profile.voiceToneProfile),
    ));

    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppIcons.personFilled,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  displayName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ink,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.profileEditButton,
                icon: Icon(AppIcons.edit, color: muted),
                onPressed: () => _openEditSheet(context, profile),
              ),
            ],
          ),
          if (profile.trimmedName == null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                l10n.profileNameEmpty,
                style: TextStyle(color: muted, fontSize: 13),
              ),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips,
          ),
          if (profile.importedFromHealth) ...[
            const SizedBox(height: 14),
            _HealthBadge(l10n: l10n),
          ],
        ],
      ),
    );
  }
}

Future<void> _openEditSheet(BuildContext context, UserProfile profile) {
  return showLumenSheet<void>(
    context: context,
    builder: (ctx) => _ProfileEditSheet(profile: profile),
  );
}

String _metricText(double value) {
  final rounded = (value * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
}

class _ProfileEditSheet extends ConsumerStatefulWidget {
  const _ProfileEditSheet({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<_ProfileEditSheet> {
  late OnboardingProfileDraft _draft;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _draft = OnboardingProfileDraft(
      name: profile.trimmedName,
      birthDate: profile.birthDate,
      voiceToneProfile: profile.voiceToneProfile,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      biologicalSex: profile.biologicalSex,
    );
  }

  Future<void> _save() async {
    final d = _draft;
    if (_saving || d.hasInvalidMetrics) return;
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    final base = widget.profile;
    final next = base.copyWith(
      name: d.trimmedName,
      clearName: d.trimmedName == null,
      birthDate: d.birthDate,
      clearBirthDate: d.birthDate == null,
      heightCm: d.heightCm,
      clearHeightCm: d.heightCm == null,
      weightKg: d.weightKg,
      clearWeightKg: d.weightKg == null,
      biologicalSex: d.biologicalSex,
      clearBiologicalSex: d.biologicalSex == null || d.biologicalSex!.isEmpty,
      voiceToneProfile: d.voiceToneProfile ?? base.voiceToneProfile,
    );
    try {
      await ref.read(userProfileProvider.notifier).updateProfile(next);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final theme = Theme.of(context);

    return GlassSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.profileEditSheetTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          OnboardingProfileForm(
            draft: _draft,
            l10n: l10n,
            onChanged: (next) => setState(() => _draft = next),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving || _draft.hasInvalidMetrics ? null : _save,
            child: BusyButtonChild(
              busy: _saving,
              label: Text(l10n.profileEditSave),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textLight : AppColors.textDark;
    final muted = AppColors.mutedText(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorderDark
              : AppColors.cardBorderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: muted),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.primaryLight : AppColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.favorite, size: 13, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            l10n.onboardingFromHealthTag,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({
    required this.item,
    required this.l10n,
    required this.onTap,
  });

  final ProfileFeedItem item;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = AppColors.mutedText(isDark);
    final when = DateFormat.MMMd(l10n.localeName).add_Hm().format(item.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.input),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_iconFor(item.kind), size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (item.isFromHealth) ...[
                          const SizedBox(width: 8),
                          Icon(
                            AppIcons.favorite,
                            size: 13,
                            color: isDark
                                ? AppColors.primaryLight
                                : AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    if (item.detail != null && item.detail!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.detail!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                    if (item.isFromHealth) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.onboardingFromHealthTag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                when,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(ProfileFeedKind kind) {
    switch (kind) {
      case ProfileFeedKind.checkIn:
        return AppIcons.checkin;
      case ProfileFeedKind.routine:
        return AppIcons.routine;
      case ProfileFeedKind.sleep:
        return AppIcons.sleep;
      case ProfileFeedKind.recovery:
        return AppIcons.favorite;
      case ProfileFeedKind.dose:
        return AppIcons.medication;
      case ProfileFeedKind.task:
        return AppIcons.tasks;
      case ProfileFeedKind.stateOfMind:
        return AppIcons.brain;
    }
  }
}
