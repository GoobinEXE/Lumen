import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noa/l10n/app_localizations.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_surface.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/lumen_shell.dart';
import '../../../integrations/system/system_settings.dart';
import '../../health_sync/data/health_sync_prefs.dart';
import '../../health_sync/presentation/health_sync_consent_sheet.dart';
import '../../routine_mood/presentation/routine_providers.dart';
import '../../tasks/presentation/task_editor_sheet.dart';
import '../service/feedback_form_launcher.dart';
import '../service/local_data_export.dart';
import '../service/privacy_policy_launcher.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/glass_chip.dart';
import '../../../core/widgets/glass_nav_bar.dart';
import '../../../core/widgets/glass_toast.dart';

final systemSettingsProvider = Provider<SystemSettings>((ref) {
  return SystemSettings();
});

final localDataExportProvider = Provider<LocalDataExport>((ref) {
  return const LocalDataExport();
});

final feedbackFormLauncherProvider = Provider<FeedbackFormLauncher>((ref) {
  return const FeedbackFormLauncher();
});

final privacyPolicyLauncherProvider = Provider<PrivacyPolicyLauncher>((ref) {
  return const PrivacyPolicyLauncher();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final healthSync = ref.watch(healthSyncEnabledProvider);
    final locale = ref.watch(activeLocaleProvider);
    final muted = AppColors.mutedText(isDark);

    return GlassScaffold(
      appBar: GlassAppBar(title: Text(l10n.settingsScreenTitle)),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.screenV,
            AppSpacing.screenH,
            GlassNavBar.reservedBottom(context),
          ),
          children: [
            _SectionLabel(text: l10n.settingsAppearanceSection),
            GlassSurface(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.settingsThemeTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.settingsThemeSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      GlassChip(
                        label: l10n.themeLight,
                        selected: themeMode == ThemeMode.light,
                        avatar: const Icon(AppIcons.lightMode, size: 16),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.light);
                        },
                      ),
                      GlassChip(
                        label: l10n.themeDark,
                        selected: themeMode == ThemeMode.dark,
                        avatar: const Icon(AppIcons.darkMode, size: 16),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.dark);
                        },
                      ),
                      GlassChip(
                        label: l10n.themeSystem,
                        selected: themeMode == ThemeMode.system,
                        avatar: const Icon(AppIcons.systemMode, size: 16),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.system);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel(text: l10n.settingsLanguageSection),
            GlassSurface(
              child: _SettingsTile(
                icon: AppIcons.language,
                title: l10n.settingsLanguageTitle,
                subtitle: l10n.settingsLanguageSubtitle(
                  _localeLabel(l10n, locale.languageCode),
                ),
                trailing: Icon(AppIcons.forward, size: 16, color: muted),
                onTap: () => _openSystem(
                  context,
                  ref,
                  SystemSettingsTarget.locale,
                  l10n,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel(text: l10n.settingsAccessSection),
            GlassSurface(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: AppIcons.notifications,
                    title: l10n.settingsNotificationsTitle,
                    subtitle: l10n.settingsNotificationsSubtitle,
                    trailing: Icon(AppIcons.forward, size: 16, color: muted),
                    onTap: () => _openSystem(
                      context,
                      ref,
                      SystemSettingsTarget.notifications,
                      l10n,
                    ),
                  ),
                  Divider(height: 1, color: AppColors.glassBorder(isDark)),
                  _SettingsTile(
                    icon: AppIcons.health,
                    title: l10n.settingsHealthTitle,
                    subtitle: healthSync
                        ? l10n.settingsHealthConnected
                        : l10n.settingsHealthDisconnected,
                    trailing: Switch.adaptive(
                      value: healthSync,
                      onChanged: (value) => _toggleHealth(context, ref, value),
                    ),
                    onTap: () => _toggleHealth(context, ref, !healthSync),
                  ),
                  Divider(height: 1, color: AppColors.glassBorder(isDark)),
                  _SettingsTile(
                    icon: AppIcons.calendar,
                    title: l10n.settingsCalendarTitle,
                    subtitle: l10n.settingsCalendarSubtitle,
                    trailing: Icon(AppIcons.forward, size: 16, color: muted),
                    onTap: () => _requestCalendar(context, ref, l10n),
                  ),
                  Divider(height: 1, color: AppColors.glassBorder(isDark)),
                  _SettingsTile(
                    icon: AppIcons.settings,
                    title: l10n.settingsSystemPermissionsTitle,
                    subtitle: l10n.settingsSystemPermissionsSubtitle,
                    trailing: Icon(AppIcons.forward, size: 16, color: muted),
                    onTap: () => _openSystem(
                      context,
                      ref,
                      SystemSettingsTarget.app,
                      l10n,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel(text: l10n.settingsDataSection),
            GlassSurface(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.bedtime_outlined,
                    title: l10n.settingsQuietHoursTitle,
                    subtitle: l10n.settingsQuietHoursSubtitle,
                    trailing: Icon(AppIcons.forward, size: 16, color: muted),
                    onTap: () => TaskQuietHoursSheet.show(context),
                  ),
                  Divider(height: 1, color: AppColors.glassBorder(isDark)),
                  _SettingsTile(
                    icon: AppIcons.upload,
                    title: l10n.settingsExportLocalTitle,
                    subtitle: l10n.settingsExportLocalSubtitle,
                    trailing: Icon(AppIcons.forward, size: 16, color: muted),
                    onTap: () => _exportLocal(context, ref, l10n),
                  ),
                  Divider(height: 1, color: AppColors.glassBorder(isDark)),
                  Semantics(
                    hint: l10n.navOpensTabHint(l10n.navClinicalFolder),
                    child: _SettingsTile(
                      icon: AppIcons.therapist,
                      title: l10n.settingsClinicalExportTitle,
                      subtitle: l10n.settingsClinicalExportSubtitle,
                      trailing: Icon(
                        AppIcons.forward,
                        size: 16,
                        color: muted,
                      ),
                      onTap: () => openClinicalFolderScreen(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel(text: l10n.settingsAboutSection),
            GlassSurface(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: AppIcons.lock,
                    title: l10n.settingsPrivacyTitle,
                    subtitle: l10n.settingsPrivacySubtitle,
                    trailing: Icon(AppIcons.forward, size: 16, color: muted),
                    onTap: () => _openPrivacyPolicy(context, ref, l10n),
                  ),
                  Divider(height: 1, color: AppColors.glassBorder(isDark)),
                  _SettingsTile(
                    icon: AppIcons.chat,
                    title: l10n.settingsFeedbackTile,
                    subtitle: l10n.settingsFeedbackSubtitle,
                    trailing: Icon(AppIcons.forward, size: 16, color: muted),
                    onTap: () => _sendFeedback(context, ref, l10n),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _localeLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case 'en':
        return l10n.english;
      case 'ja':
        return l10n.japanese;
      case 'es':
        return l10n.spanish;
      case 'pt':
      default:
        return l10n.portuguese;
    }
  }

  Future<void> _openSystem(
    BuildContext context,
    WidgetRef ref,
    SystemSettingsTarget target,
    AppLocalizations l10n,
  ) async {
    HapticFeedback.selectionClick();
    final ok = await ref.read(systemSettingsProvider).open(target);
    if (!context.mounted || ok) return;
    showGlassToast(context, l10n.settingsOpenSystemFailed);
  }

  Future<void> _toggleHealth(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    HapticFeedback.selectionClick();
    if (!enable) {
      await ref.read(healthSyncEnabledProvider.notifier).setEnabled(false);
      return;
    }
    final granted = await HealthSyncConsentSheet.show(context);
    if (!context.mounted) return;
    final l10n = ref.read(appLocalizationsProvider);
    final android = !kIsWeb && Platform.isAndroid;
    final message = granted == true
        ? (android
              ? l10n.healthSyncSuccessMessageAndroid
              : l10n.healthSyncSuccessMessage)
        : (android
              ? l10n.healthSyncDeniedMessageAndroid
              : l10n.healthSyncDeniedMessage);
    showGlassToast(context, message);
  }

  Future<void> _requestCalendar(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    HapticFeedback.selectionClick();
    final prefs = ref.read(sharedPreferencesProvider);
    final granted =
        await ref.read(deviceCalendarProvider).requestAccess(prefs);
    if (!context.mounted) return;
    if (granted) {
      showGlassToast(context, l10n.settingsCalendarGranted);
      return;
    }
    final opened = await ref
        .read(systemSettingsProvider)
        .open(SystemSettingsTarget.app);
    if (!context.mounted) return;
    if (!opened) {
      showGlassToast(context, l10n.settingsCalendarDenied);
    }
  }

  Future<void> _exportLocal(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    HapticFeedback.mediumImpact();
    final prefs = ref.read(sharedPreferencesProvider);
    final ok = await ref.read(localDataExportProvider).shareBackup(
          prefs,
          shareSubject: l10n.settingsExportLocalShareSubject,
        );
    if (!context.mounted) return;
    showGlassToast(context, 
          ok ? l10n.settingsExportLocalDone : l10n.settingsExportLocalFailed,
        );
  }

  Future<void> _openPrivacyPolicy(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    HapticFeedback.selectionClick();
    final ok = await ref.read(privacyPolicyLauncherProvider).open();
    if (!context.mounted || ok) return;
    showGlassToast(context, l10n.settingsPrivacyOpenFailed);
  }

  Future<void> _sendFeedback(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    HapticFeedback.selectionClick();
    final ok = await ref.read(feedbackFormLauncherProvider).open();
    if (!context.mounted || ok) return;
    showGlassToast(context, l10n.settingsFeedbackOpenFailed);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.mutedText(isDark),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = AppColors.mutedText(isDark);
    final ink = isDark ? AppColors.textLight : AppColors.textDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        overlayColor: glassInkOverlay,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
