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
import '../../../core/widgets/glass_toast.dart';
import '../../../integrations/calendar/device_calendar.dart';
import '../../health_sync/presentation/health_sync_consent_sheet.dart';
import '../../medications/presentation/providers/medication_providers.dart';
import '../../profile/data/user_profile_repository.dart';
import '../../profile/domain/health_demographics_mapper.dart';
import '../../profile/domain/profile_demographics.dart';
import '../data/onboarding_prefs.dart';
import '../domain/onboarding_profile_draft.dart';
import 'onboarding_profile_form.dart';

enum _HealthChoice { pending, granted, denied, skipped }

enum _PermissionState { notAsked, on, off, requested }

/// Wizard local da 1ª abertura: apresenta o app, oferece a sincronização de
/// saúde, pede os acessos do sistema e cria o perfil. Tudo fica no aparelho.
class FirstLaunchOnboarding extends ConsumerStatefulWidget {
  const FirstLaunchOnboarding({super.key});

  static const int stepCount = 4;

  /// Abre o wizard em tela cheia quando ainda não houve primeira abertura.
  static Future<void> maybeShow(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (!shouldShowFirstLaunchOnboarding(prefs)) return;
    if (!context.mounted) return;
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const FirstLaunchOnboarding(),
      ),
    );
  }

  @override
  ConsumerState<FirstLaunchOnboarding> createState() =>
      _FirstLaunchOnboardingState();
}

class _FirstLaunchOnboardingState extends ConsumerState<FirstLaunchOnboarding> {
  var _step = 0;
  var _busy = false;

  var _health = _HealthChoice.pending;
  ProfileDemographics? _demographics;

  var _permissionsAsked = false;
  var _notifications = _PermissionState.notAsked;
  var _calendar = _PermissionState.notAsked;

  OnboardingProfileDraft? _draft;

  void _goTo(int step) {
    if (_busy) return;
    if (step == 3) {
      _draft ??= OnboardingProfileDraft.fromProfile(
        ref.read(userProfileProvider),
        demographics: _demographics,
      );
    }
    setState(() => _step = step.clamp(0, FirstLaunchOnboarding.stepCount - 1));
  }

  void _next() {
    HapticFeedback.lightImpact();
    _goTo(_step + 1);
  }

  void _back() {
    if (_step == 0) return;
    HapticFeedback.selectionClick();
    _goTo(_step - 1);
  }

  Future<void> _connectHealth() async {
    if (_busy) return;
    HapticFeedback.lightImpact();
    setState(() => _busy = true);
    try {
      final granted = await HealthSyncConsentSheet.show(context);
      if (!mounted) return;
      if (granted == null) return; // "Agora não" no sheet: segue sem decidir.
      if (!granted) {
        setState(() => _health = _HealthChoice.denied);
        return;
      }
      ProfileDemographics demographics = const ProfileDemographics();
      try {
        final fromHealth =
            await ref.read(healthServiceProvider).readDemographics();
        demographics = fromHealth.toProfileDemographics();
      } catch (_) {
        // Sem dado demográfico, o formulário pede tudo à pessoa.
      }
      if (!mounted) return;
      setState(() {
        _health = _HealthChoice.granted;
        _demographics = demographics;
        _draft = null; // Rascunho recalculado com as lacunas preenchidas.
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _skipHealth() {
    HapticFeedback.selectionClick();
    setState(() => _health = _HealthChoice.skipped);
    _goTo(2);
  }

  Future<void> _requestPermissions() async {
    if (_busy) return;
    HapticFeedback.lightImpact();
    setState(() => _busy = true);
    final prefs = ref.read(sharedPreferencesProvider);
    var notifications = _PermissionState.requested;
    var calendar = _PermissionState.off;
    try {
      try {
        final granted = await ref
            .read(medicationReminderServiceProvider)
            .requestLaunchPermissions();
        notifications = switch (granted) {
          true => _PermissionState.on,
          false => _PermissionState.off,
          null => _PermissionState.requested,
        };
      } catch (_) {
        notifications = _PermissionState.requested;
      }
      try {
        final granted = await DeviceCalendar().requestAccess(prefs);
        calendar = granted ? _PermissionState.on : _PermissionState.off;
      } catch (_) {
        calendar = _PermissionState.off;
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _permissionsAsked = true;
          _notifications = notifications;
          _calendar = calendar;
        });
      }
    }
  }

  void _skipPermissions() {
    HapticFeedback.selectionClick();
    setState(() => _permissionsAsked = true);
    _goTo(3);
  }

  Future<void> _finish() async {
    final draft = _draft;
    if (_busy || draft == null || !draft.isComplete) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    final prefs = ref.read(sharedPreferencesProvider);
    final l10n = ref.read(appLocalizationsProvider);
    final navigator = Navigator.of(context);
    try {
      final notifier = ref.read(userProfileProvider.notifier);
      final profile = draft.applyTo(ref.read(userProfileProvider));
      await notifier.updateProfile(profile);
      await markOnboardingDone(prefs);
      if (!mounted) return;
      showGlassToast(
        context,
        l10n.onboardingDoneSnack(profile.trimmedName ?? ''),
      );
      navigator.pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = ref.watch(appLocalizationsProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final muted = AppColors.mutedText(isDark);

    final body = switch (_step) {
      0 => _WelcomeStep(l10n: l10n),
      1 => _HealthStep(
          l10n: l10n,
          choice: _health,
          importedCount: _importedCount,
        ),
      2 => _PermissionsStep(
          l10n: l10n,
          health: _health,
          notifications: _notifications,
          calendar: _calendar,
        ),
      _ => _ProfileStep(
          l10n: l10n,
          draft: _draft!,
          onChanged: (next) => setState(() => _draft = next),
        ),
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH - 8,
                  8,
                  AppSpacing.screenH,
                  0,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: _step > 0
                          ? IconButton(
                              tooltip: l10n.onboardingBack,
                              icon: const Icon(AppIcons.back, size: 20),
                              onPressed: _busy ? null : _back,
                            )
                          : null,
                    ),
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          l10n.onboardingStepLabel(
                            _step + 1,
                            FirstLaunchOnboarding.stepCount,
                          ),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  8,
                  AppSpacing.screenH,
                  0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: (_step + 1) / FirstLaunchOnboarding.stepCount,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.primarySoft,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_step),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenH,
                        AppSpacing.screenV,
                        AppSpacing.screenH,
                        AppSpacing.screenV,
                      ),
                      child: body,
                    ),
                  ),
                ),
              ),
              _Footer(
                busy: _busy,
                primaryLabel: _primaryLabel(l10n),
                onPrimary: _primaryAction,
                secondaryLabel: _secondaryLabel(l10n),
                onSecondary: _secondaryAction,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Enquanto ninguém concedeu nem recusou no sistema, o passo de saúde segue
  /// oferecendo a conexão — inclusive para quem voltou depois de pular.
  bool get _healthUndecided =>
      _health == _HealthChoice.pending || _health == _HealthChoice.skipped;

  int get _importedCount {
    final demographics = _demographics;
    if (demographics == null) return 0;
    return OnboardingProfileDraft.fromProfile(
      ref.read(userProfileProvider),
      demographics: demographics,
    ).healthFilled.length;
  }

  String _primaryLabel(AppLocalizations l10n) {
    switch (_step) {
      case 0:
        return l10n.onboardingNext;
      case 1:
        return _healthUndecided
            ? l10n.onboardingHealthYes
            : l10n.onboardingNext;
      case 2:
        return _permissionsAsked
            ? l10n.onboardingNext
            : l10n.onboardingContinue;
      default:
        return l10n.onboardingFinish;
    }
  }

  VoidCallback? get _primaryAction {
    if (_busy) return null;
    switch (_step) {
      case 0:
        return _next;
      case 1:
        return _healthUndecided ? _connectHealth : _next;
      case 2:
        return _permissionsAsked ? _next : _requestPermissions;
      default:
        return (_draft?.isComplete ?? false) ? _finish : null;
    }
  }

  String? _secondaryLabel(AppLocalizations l10n) {
    switch (_step) {
      case 1:
        return _healthUndecided ? l10n.onboardingSkip : null;
      case 2:
        return _permissionsAsked ? null : l10n.onboardingSkip;
      default:
        return null;
    }
  }

  VoidCallback? get _secondaryAction {
    if (_busy) return null;
    switch (_step) {
      case 1:
        return _healthUndecided ? _skipHealth : null;
      case 2:
        return _permissionsAsked ? null : _skipPermissions;
      default:
        return null;
    }
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.busy,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final bool busy;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        8,
        AppSpacing.screenH,
        AppSpacing.screenV,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: onPrimary,
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(primaryLabel),
          ),
          if (secondaryLabel != null) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: onSecondary,
              child: Text(secondaryLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = isDark ? AppColors.textLight : AppColors.textDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.16)
                : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadii.input),
          ),
          child: Icon(
            icon,
            size: 28,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: ink,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.icon,
    required this.text,
    this.title,
    this.tint,
  });

  final IconData icon;
  final String? title;
  final String text;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = tint ?? (isDark ? AppColors.primaryLight : AppColors.primary);
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.card),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          icon: AppIcons.sparkle,
          title: l10n.onboardingWelcomeTitle,
          body: l10n.onboardingWelcomeBody,
        ),
        const SizedBox(height: AppSpacing.section + 8),
        _NoteCard(
          icon: AppIcons.lock,
          title: l10n.onboardingPrivacyTitle,
          text: l10n.onboardingPrivacyBody,
        ),
      ],
    );
  }
}

class _HealthStep extends StatelessWidget {
  const _HealthStep({
    required this.l10n,
    required this.choice,
    required this.importedCount,
  });

  final AppLocalizations l10n;
  final _HealthChoice choice;
  final int importedCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          icon: AppIcons.favorite,
          title: l10n.onboardingHealthTitle,
          body: l10n.onboardingHealthBody,
        ),
        const SizedBox(height: AppSpacing.section + 8),
        _NoteCard(
          icon: AppIcons.phone,
          text: l10n.onboardingHealthNote,
        ),
        if (choice == _HealthChoice.granted) ...[
          const SizedBox(height: 12),
          _NoteCard(
            icon: AppIcons.check,
            tint: isDark ? AppColors.primaryLight : AppColors.success,
            text: l10n.onboardingHealthImported(importedCount),
          ),
        ] else if (choice == _HealthChoice.denied) ...[
          const SizedBox(height: 12),
          _NoteCard(
            icon: AppIcons.warning,
            tint: AppColors.warning,
            text: l10n.onboardingHealthDenied,
          ),
        ],
      ],
    );
  }
}

class _PermissionsStep extends StatelessWidget {
  const _PermissionsStep({
    required this.l10n,
    required this.health,
    required this.notifications,
    required this.calendar,
  });

  final AppLocalizations l10n;
  final _HealthChoice health;
  final _PermissionState notifications;
  final _PermissionState calendar;

  _PermissionState get _healthState {
    switch (health) {
      case _HealthChoice.granted:
        return _PermissionState.on;
      case _HealthChoice.denied:
        return _PermissionState.off;
      case _HealthChoice.pending:
      case _HealthChoice.skipped:
        return _PermissionState.notAsked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          icon: AppIcons.notifications,
          title: l10n.onboardingPermissionsTitle,
          body: l10n.onboardingPermissionsBody,
        ),
        const SizedBox(height: AppSpacing.section + 8),
        GlassSurface(
          padding: const EdgeInsets.all(AppSpacing.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.onboardingStatusTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _StatusRow(
                icon: AppIcons.favorite,
                label: l10n.onboardingStatusHealth,
                state: _healthState,
                l10n: l10n,
              ),
              const SizedBox(height: 10),
              _StatusRow(
                icon: AppIcons.medication,
                label: l10n.onboardingStatusNotifications,
                state: notifications,
                l10n: l10n,
              ),
              const SizedBox(height: 10),
              _StatusRow(
                icon: AppIcons.calendar,
                label: l10n.onboardingStatusCalendar,
                state: calendar,
                l10n: l10n,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.onboardingPermissionsNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.mutedText(theme.brightness == Brightness.dark),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.state,
    required this.l10n,
  });

  final IconData icon;
  final String label;
  final _PermissionState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = AppColors.mutedText(isDark);
    final (String text, Color color) = switch (state) {
      _PermissionState.on => (
          l10n.onboardingStatusOn,
          isDark ? AppColors.primaryLight : AppColors.success,
        ),
      _PermissionState.off => (
          l10n.onboardingStatusOff,
          AppColors.warning,
        ),
      _PermissionState.requested => (
          l10n.onboardingStatusRequested,
          muted,
        ),
      _PermissionState.notAsked => (
          l10n.onboardingStatusSkipped,
          muted,
        ),
    };
    return Semantics(
      label: '$label: $text',
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(icon, size: 20, color: muted),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.l10n,
    required this.draft,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final OnboardingProfileDraft draft;
  final ValueChanged<OnboardingProfileDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          icon: AppIcons.person,
          title: l10n.onboardingProfileTitle,
          body: draft.importedFromHealth
              ? l10n.onboardingProfileBodyHealth
              : l10n.onboardingProfileBody,
        ),
        const SizedBox(height: AppSpacing.section + 8),
        OnboardingProfileForm(
          draft: draft,
          onChanged: onChanged,
          l10n: l10n,
        ),
      ],
    );
  }
}
