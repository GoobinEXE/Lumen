import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/localization/l10n_labels.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_surface.dart';
import '../../../core/theme/responsive.dart';
import '../../../core/widgets/async_placeholders.dart';
import '../../../core/widgets/lumen_shell.dart';
import '../../calendar/presentation/day_digest_sheet.dart';
import '../../medications/domain/medication_log.dart';
import '../../medications/presentation/providers/medication_providers.dart';
import '../../profile/data/user_profile_repository.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/presentation/profile_labels.dart';
import '../../routine_mood/presentation/daily_routine_screen.dart';
import '../../sleep_analytics/presentation/recovery_dashboard_card.dart';
import '../../sleep_analytics/presentation/sleep_dashboard_card.dart';
import '../../therapist_export/data/therapist_contact_repository.dart';
import '../../therapist_export/domain/care_contact.dart';
import '../../therapist_export/presentation/care_contact_editor_sheet.dart';
import '../../therapist_export/presentation/care_contact_labels.dart';
import '../../therapist_export/service/whatsapp_text_formatter.dart';
import '../../../core/widgets/glass_icon_button.dart';
import '../../../core/widgets/glass_nav_bar.dart';
import '../../../core/widgets/glass_toast.dart';

/// Início: ficha viva da pessoa (identidade, rede de apoio e visão do dia).
class HomeFichaScreen extends ConsumerWidget {
  const HomeFichaScreen({super.key});

  String _greeting(AppLocalizations l10n, String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.greetingMorning(name);
    if (hour < 18) return l10n.greetingAfternoon(name);
    return l10n.greetingEvening(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = ref.watch(appLocalizationsProvider);
    final profile = ref.watch(userProfileProvider);
    final displayName = profileDisplayName(profile, l10n.greetingName);

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(sleepHistoryProvider);
            ref.invalidate(recoveryHistoryProvider);
            ref.invalidate(todaySnapshotsProvider);
            await ref.read(moodEntriesProvider.notifier).loadEntries();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              12,
              AppSpacing.screenH,
              GlassNavBar.reservedBottom(context),
            ),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(l10n, displayName),
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.homeFichaSubtitle,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GlassIconButton(
                    tooltip: l10n.profileOpenTooltip,
                    icon: AppIcons.person,
                    onPressed: () => openProfileScreen(context),
                  ),
                  const SizedBox(width: 8),
                  GlassIconButton(
                    tooltip: l10n.settingsOpenTooltip,
                    icon: AppIcons.settings,
                    onPressed: () => openSettingsScreen(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              RepaintBoundary(
                child: _IdentityCard(
                  profile: profile,
                  displayName: displayName,
                  l10n: l10n,
                ),
              ),
              const SizedBox(height: 22),
              RepaintBoundary(child: _CareContactsSection(l10n: l10n)),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  l10n.homeOverviewTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Semantics(
                hint: l10n.navOpensTabHint(l10n.navMeds),
                child: RepaintBoundary(
                  child: _MedWindowCard(
                    l10n: l10n,
                    onOpen: () => openMedicationsScreen(context),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                hint: l10n.navOpensTabHint(l10n.navRoutine),
                child: RepaintBoundary(
                  child: _AnchorCard(
                    l10n: l10n,
                    onOpen: () => openRoutineScreen(context),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const RepaintBoundary(child: SleepDashboardCard()),
              const SizedBox(height: 12),
              const RepaintBoundary(child: RecoveryDashboardCard()),
              const SizedBox(height: 12),
              RepaintBoundary(
                child: _NavCard(
                  icon: AppIcons.calendar,
                  title: l10n.homeMyDaysTitle,
                  subtitle: l10n.homeMyDaysSubtitle,
                  onTap: () => openRoutineCalendarScreen(context),
                ),
              ),
              const SizedBox(height: 12),
              RepaintBoundary(
                child: _NavCard(
                  icon: AppIcons.tasks,
                  title: l10n.homeTasksTitle,
                  subtitle: l10n.homeTasksSubtitle,
                  onTap: () => openTasksHub(context),
                ),
              ),
              RepaintBoundary(child: _InsightsCard(l10n: l10n)),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  l10n.homeRecentEntriesTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              RepaintBoundary(child: _RecentEntries(l10n: l10n)),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.profile,
    required this.displayName,
    required this.l10n,
  });

  final UserProfile profile;
  final String displayName;
  final AppLocalizations l10n;

  static String _metricText(double value) {
    final rounded = (value * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = isDark ? AppColors.textLight : AppColors.textDark;
    final muted = AppColors.mutedText(isDark);
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final initial = displayName.trim().isEmpty
        ? '?'
        : displayName.trim().characters.first.toUpperCase();

    final chips = <Widget>[];
    final age = profile.ageYears;
    if (age != null) {
      chips.add(_InfoChip(icon: AppIcons.person, label: l10n.profileAgeYears(age)));
    }
    final height = profile.heightCm;
    if (height != null) {
      chips.add(
        _InfoChip(
          icon: AppIcons.favoriteOutline,
          label: l10n.profileHeightChip(_metricText(height)),
        ),
      );
    }
    final weight = profile.weightKg;
    if (weight != null) {
      chips.add(
        _InfoChip(
          icon: AppIcons.favoriteOutline,
          label: l10n.profileWeightChip(_metricText(weight)),
        ),
      );
    }
    chips.add(
      _InfoChip(
        icon: AppIcons.chat,
        label: voiceToneLabel(l10n, profile.voiceToneProfile),
        highlighted: true,
      ),
    );

    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.card),
      onTap: () => openProfileScreen(context),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.16),
                  ),
                  child: Text(
                    initial,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      Text(
                        profile.trimmedName == null
                            ? l10n.profileNameEmpty
                            : l10n.homeFichaIdentityHint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                          fontSize: kMinBodySecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.profileEditButton,
                  icon: Icon(AppIcons.edit, color: muted),
                  onPressed: () => openProfileScreen(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textLight : AppColors.textDark;
    final muted = AppColors.mutedText(isDark);
    final base = isDark ? AppColors.cardDark : AppColors.cardLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: highlighted
            ? Color.alphaBlend(
                AppColors.primary.withValues(alpha: 0.14),
                base,
              )
            : base,
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
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareContactsSection extends ConsumerWidget {
  const _CareContactsSection({required this.l10n});

  final AppLocalizations l10n;

  Future<void> _call(BuildContext context, CareContact contact) async {
    final number = contact.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.isEmpty) return;
    var opened = false;
    try {
      opened = await launchUrl(Uri(scheme: 'tel', path: number));
    } catch (_) {}
    if (!opened && context.mounted) _showLaunchFailed(context);
  }

  Future<void> _whatsApp(BuildContext context, CareContact contact) async {
    var opened = false;
    try {
      opened = await WhatsappTextFormatter.sendToWhatsApp(
        messageText: '',
        phoneNumber: contact.phone,
      );
    } catch (_) {}
    if (!opened && context.mounted) _showLaunchFailed(context);
  }

  void _showLaunchFailed(BuildContext context) {
    showGlassToast(context, l10n.careContactLaunchFailed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = AppColors.mutedText(isDark);
    final contactsAsync = ref.watch(careContactsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.careContactsSectionTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                l10n.careContactsSectionHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: muted,
                  fontSize: kMinBodySecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GlassSurface(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.card,
            vertical: 8,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                contactsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SlotSkeleton(height: 56, bars: 2),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(l10n.errorLoading('$err')),
                  ),
                  data: (contacts) {
                    if (contacts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          l10n.careContactsEmpty,
                          style: theme.textTheme.bodyMedium,
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final contact in contacts)
                          _ContactRow(
                            contact: contact,
                            l10n: l10n,
                            onEdit: () => CareContactEditorSheet.show(
                              context,
                              existing: contact,
                            ),
                            onCall: () => _call(context, contact),
                            onWhatsApp: () => _whatsApp(context, contact),
                          ),
                      ],
                    );
                  },
                ),
                TextButton.icon(
                  onPressed: () => CareContactEditorSheet.show(context),
                  icon: const Icon(AppIcons.add, size: 20),
                  label: Text(l10n.careContactAdd),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.contact,
    required this.l10n,
    required this.onEdit,
    required this.onCall,
    required this.onWhatsApp,
  });

  final CareContact contact;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = AppColors.mutedText(isDark);
    final hasPhone = contact.phone.trim().isNotEmpty;
    final name = careContactDisplayName(l10n, contact);
    final role = careContactRoleLabel(l10n, contact.role);
    final hasName = (contact.displayName?.trim() ?? '').isNotEmpty;

    return Semantics(
      container: true,
      label: '$role, $name',
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppRadii.input),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (hasName) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                            ),
                            child: Text(
                              role,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasPhone
                          ? contact.phone.trim()
                          : l10n.careContactPhoneEmpty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: muted,
                        fontSize: kMinBodySecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasPhone) ...[
                IconButton(
                  tooltip: l10n.careContactWhatsAppTooltip,
                  icon: const Icon(AppIcons.chat, size: 20),
                  color: AppColors.primary,
                  onPressed: onWhatsApp,
                ),
                IconButton(
                  tooltip: l10n.careContactCallTooltip,
                  icon: const Icon(Icons.call_outlined, size: 20),
                  color: AppColors.primary,
                  onPressed: onCall,
                ),
              ] else
                IconButton(
                  tooltip: l10n.careContactEditTooltip,
                  icon: Icon(AppIcons.edit, size: 20, color: muted),
                  onPressed: onEdit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedWindowCard extends ConsumerWidget {
  const _MedWindowCard({
    required this.l10n,
    required this.onOpen,
  });

  final AppLocalizations l10n;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(todayMedicationLogsProvider).value ?? const [];
    ref.watch(medicationsListProvider); // invalida card quando a lista muda
    final theme = Theme.of(context);
    final taken = logs.where((l) => l.isTaken).length;
    final pending = logs.where((l) => l.isPending).toList();
    final MedicationLog? next = pending.isEmpty ? null : pending.first;
    return _SurfaceCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                AppIcons.medication,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.medicationsCardTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (logs.isNotEmpty)
                Text(
                  l10n.homeTakenTodayCount(taken, logs.length),
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          if (logs.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: taken / logs.length,
                backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
          if (next != null) ...[
            const SizedBox(height: 8),
            Text(
              '${next.medicationName} · ${DateFormat.Hm(l10n.localeName).format(next.scheduledTime)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l10n.homeNoMedsToday, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _InsightsCard extends ConsumerWidget {
  const _InsightsCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(correlationInsightsProvider);
    if (insights.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GlassSurface(
        tint: AppColors.accent,
        padding: const EdgeInsets.all(AppSpacing.card),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeBrainPatternsTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                insights.first.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.textLight
                      : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentEntries extends ConsumerWidget {
  const _RecentEntries({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final moodAsync = ref.watch(moodEntriesProvider);
    return moodAsync.when(
      loading: () => const SlotSkeleton(height: 72, bars: 2),
      error: (err, _) => Text(l10n.errorLoading('$err')),
      data: (entries) {
        if (entries.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l10n.homeNoEntriesYet,
              style: theme.textTheme.bodyMedium,
            ),
          );
        }
        return Column(
          children: [
            for (final entry in entries.take(3))
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                onTap: () => showDayDigestSheet(context, entry.timestamp),
                leading: Icon(
                  AppIcons.forValence(entry.valence),
                  color: AppColors.primary,
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.focus.label(l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        entry.energy.label(l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  DateFormat.Hm(l10n.localeName).format(entry.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: kMinBodySecondary,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AnchorCard extends ConsumerWidget {
  const _AnchorCard({
    required this.l10n,
    required this.onOpen,
  });

  final AppLocalizations l10n;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshots = ref.watch(todaySnapshotsProvider).value ?? const [];
    final theme = Theme.of(context);
    final locale = l10n.localeName;
    final withAnchor = snapshots
        .where((s) => s.mainFocusAnchor.trim().isNotEmpty)
        .toList();
    return _SurfaceCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.anchor, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.homeDayAnchorTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (withAnchor.isEmpty)
            Text(
              l10n.homeDayAnchorEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? AppColors.textLight
                    : AppColors.textDark,
              ),
            )
          else
            for (final snapshot in withAnchor.take(3))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  l10n.homeRoutineSnapshotLine(
                    DateFormat('HH:mm', locale).format(snapshot.savedAt),
                    snapshot.mainFocusAnchor.trim(),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const Icon(AppIcons.forward, size: 18),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.card),
      onTap: onTap,
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

