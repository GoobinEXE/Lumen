import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_surface.dart';
import '../../../core/widgets/glass_toast.dart';
import '../../../integrations/system/system_settings.dart';
import '../data/health_sync_prefs.dart';

/// Bottom sheet que explica a sincronização com o app de saúde do aparelho
/// antes de disparar o diálogo nativo de permissões.
class HealthSyncConsentSheet extends ConsumerStatefulWidget {
  const HealthSyncConsentSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showLumenSheet<bool>(
      context: context,
      builder: (ctx) => const HealthSyncConsentSheet(),
    );
  }

  @override
  ConsumerState<HealthSyncConsentSheet> createState() =>
      _HealthSyncConsentSheetState();
}

class _HealthSyncConsentSheetState
    extends ConsumerState<HealthSyncConsentSheet> {
  bool _isConnecting = false;
  bool _ready = false;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(healthServiceProvider).initialize();
      if (mounted) setState(() => _ready = true);
    });
  }

  Future<void> _confirm() async {
    if (_isConnecting) return;
    HapticFeedback.lightImpact();
    setState(() => _isConnecting = true);

    final healthService = ref.read(healthServiceProvider);
    await healthService.initialize();
    final granted = await healthService.requestPermissions();

    if (granted) {
      await ref.read(healthSyncEnabledProvider.notifier).setEnabled(true);
      ref.invalidate(sleepHistoryProvider);
      ref.invalidate(recoveryHistoryProvider);
    }

    if (!mounted) return;
    Navigator.of(context).pop(granted);
  }

  Future<void> _openHealthConnect() async {
    HapticFeedback.selectionClick();
    final ok = await SystemSettings().open(SystemSettingsTarget.healthConnect);
    if (!mounted || ok) return;
    final l10n = ref.read(appLocalizationsProvider);
    showGlassToast(context, l10n.settingsOpenSystemFailed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = ref.watch(appLocalizationsProvider);
    final health = ref.watch(healthServiceProvider);
    final showOemGuide =
        _ready && _isAndroid && health.shouldGuideToHealthConnect;

    final title =
        _isAndroid ? l10n.healthSyncSheetTitleAndroid : l10n.healthSyncSheetTitle;
    final subtitle = _isAndroid
        ? l10n.healthSyncSheetSubtitleAndroid
        : l10n.healthSyncSheetSubtitle;
    final readTitle =
        _isAndroid ? l10n.healthSyncReadTitleAndroid : l10n.healthSyncReadTitle;
    final readBody =
        _isAndroid ? l10n.healthSyncReadBodyAndroid : l10n.healthSyncReadBody;
    final writeTitle = _isAndroid
        ? l10n.healthSyncWriteTitleAndroid
        : l10n.healthSyncWriteTitle;
    final writeBody = _isAndroid
        ? l10n.healthSyncWriteBodyAndroid
        : l10n.healthSyncWriteBody;
    final medsNote =
        _isAndroid ? l10n.healthSyncMedsNoteAndroid : l10n.healthSyncMedsNote;
    final systemNote = _isAndroid
        ? l10n.healthSyncSystemNoteAndroid
        : l10n.healthSyncSystemNote;

    return GlassSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft.withValues(
                    alpha: isDark ? 0.2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.input),
                ),
                child: Icon(
                  AppIcons.favorite,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText(isDark),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _InfoBlock(
            icon: AppIcons.download,
            title: readTitle,
            body: readBody,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _InfoBlock(
            icon: AppIcons.upload,
            title: writeTitle,
            body: writeBody,
            isDark: isDark,
          ),
          if (showOemGuide) ...[
            const SizedBox(height: 12),
            _InfoBlock(
              icon: AppIcons.health,
              title: l10n.healthSyncOemGuideTitle,
              body: l10n.healthSyncOemGuideBody,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isConnecting ? null : _openHealthConnect,
                child: Text(l10n.healthSyncOpenHealthConnectButton),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            medsNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText(isDark),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            systemNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText(isDark),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isConnecting ? () {} : _confirm,
              child: _isConnecting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context)
                                .elevatedButtonTheme
                                .style
                                ?.foregroundColor
                                ?.resolve({}) ??
                            Colors.white,
                      ),
                    )
                  : Text(l10n.healthSyncConfirmButton),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isConnecting
                  ? null
                  : () => Navigator.of(context).pop(null),
              child: Text(l10n.healthSyncLaterButton),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.icon,
    required this.title,
    required this.body,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.primarySoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadii.input),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
