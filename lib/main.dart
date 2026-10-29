import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/localization/locale_provider.dart';
import 'core/providers.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/lumen_glass_style.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/widgets/lumen_shell.dart';
import 'core/notifications/local_notifications_background.dart';
import 'core/notifications/local_notifications_host.dart';
import 'features/medications/service/medication_reminder_service.dart';
import 'features/tasks/service/task_reminder_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa SharedPreferences para armazenamento local offline-first
  final sharedPreferences = await SharedPreferences.getInstance();
  LocalNotificationsHost.bindBackground(localNotificationsBackground);
  // Handlers antes do consumeLaunch — cold start aplica taken/complete.
  LocalNotificationsHost.medicationHandler =
      (response, {required notifyUi}) => MedicationReminderService.handleResponse(
            response,
            notifyUi: notifyUi,
          );
  LocalNotificationsHost.taskHandler =
      (response, {required notifyUi}) => TaskReminderService.handleResponse(
            response,
            notifyUi: notifyUi,
          );
  await LocalNotificationsHost.consumeLaunch();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const LumenApp(),
    ),
  );
}

class LumenApp extends ConsumerStatefulWidget {
  const LumenApp({super.key});

  @override
  ConsumerState<LumenApp> createState() => _LumenAppState();
}

class _LumenAppState extends ConsumerState<LumenApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    ref.invalidate(activeLocaleProvider);
    setState(() {});
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
  }

  Brightness _resolveBrightness(ThemeMode mode, Brightness platform) {
    return switch (mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platform,
    };
  }

  static const _localizationsDelegates = [
    AppLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  Locale? _resolveLocale(List<Locale>? locales, Iterable<Locale> supported) {
    if (locales == null || locales.isEmpty) {
      return resolveSupportedLocale();
    }
    return resolveSupportedLocale(locales.first);
  }

  @override
  Widget build(BuildContext context) {
    final activeLocale = ref.watch(activeLocaleProvider);
    final l10n = ref.watch(appLocalizationsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final brightness = _resolveBrightness(themeMode, platformBrightness);

    if (lumenUsesLiquidGlass()) {
      final materialTheme = AppTheme.iosEngineTheme(brightness: brightness);
      return CupertinoApp(
        title: l10n.appTitle,
        debugShowCheckedModeBanner: false,
        theme: CupertinoThemeData(
          brightness: brightness,
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: brightness == Brightness.dark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
          barBackgroundColor: Colors.transparent,
          textTheme: CupertinoTextThemeData(
            primaryColor: brightness == Brightness.dark
                ? AppColors.textLight
                : AppColors.textDark,
          ),
        ),
        locale: activeLocale,
        supportedLocales: AppLocalizations.supportedLocales,
        localeListResolutionCallback: _resolveLocale,
        localizationsDelegates: _localizationsDelegates,
        builder: (context, child) {
          return Theme(
            data: materialTheme,
            child: DefaultTextStyle(
              style: materialTheme.textTheme.bodyMedium!,
              child: Material(
                type: MaterialType.transparency,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
        home: const LumenShell(),
      );
    }

    return MaterialApp(
      title: l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.androidTheme(brightness: Brightness.light),
      darkTheme: AppTheme.androidTheme(brightness: Brightness.dark),
      themeMode: themeMode,
      locale: activeLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: _resolveLocale,
      localizationsDelegates: _localizationsDelegates,
      home: const LumenShell(),
    );
  }
}
