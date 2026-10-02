import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/medications/presentation/medications_screen.dart';
import '../../features/medications/presentation/providers/medication_providers.dart';
import '../../features/medications/service/medication_notification_bus.dart';
import '../../features/routine_mood/presentation/daily_routine_screen.dart';
import '../../features/therapist_export/presentation/therapist_export_hub_screen.dart';
import '../icons/app_icons.dart';
import '../localization/locale_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

const _homeRoute = '/';
const _routineRoute = '/routine';
const _medsRoute = '/meds';
const _clinicRoute = '/clinic';

void openRoutineScreen(BuildContext context) {
  Navigator.of(context).push(_routinePage());
}

void openMedicationsScreen(BuildContext context) {
  Navigator.of(context).push(_medsPage());
}

void openTherapistHub(BuildContext context) {
  Navigator.of(context).push(_clinicPage());
}

MaterialPageRoute<void> _routinePage() {
  return MaterialPageRoute<void>(
    settings: const RouteSettings(name: _routineRoute),
    builder: (_) => const DailyRoutineScreen(),
  );
}

MaterialPageRoute<void> _medsPage() {
  return MaterialPageRoute<void>(
    settings: const RouteSettings(name: _medsRoute),
    builder: (_) => const MedicationsScreen(),
  );
}

MaterialPageRoute<void> _clinicPage() {
  return MaterialPageRoute<void>(
    settings: const RouteSettings(name: _clinicRoute),
    builder: (_) => const TherapistExportHubScreen(),
  );
}

enum _ShellTab { home, routine, meds, clinic }

class LumenShell extends ConsumerStatefulWidget {
  const LumenShell({super.key});

  @override
  ConsumerState<LumenShell> createState() => _LumenShellState();
}

class _LumenShellState extends ConsumerState<LumenShell>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _shellNav = GlobalKey<NavigatorState>();
  late final _ShellTabObserver _tabObserver;
  late final VoidCallback _onOpenMedications;
  _ShellTab _tab = _ShellTab.home;
  int _seenOpens = 0;
  DateTime? _lastMedsNavigation;

  @override
  void initState() {
    super.initState();
    _tabObserver = _ShellTabObserver(_onShellTop);
    WidgetsBinding.instance.addObserver(this);
    _seenOpens = MedicationNotificationBus.openMedications.value;
    _onOpenMedications = () {
      final next = MedicationNotificationBus.openMedications.value;
      if (next == _seenOpens) return;
      _seenOpens = next;
      _openMedicationsFromAlarm();
    };
    MedicationNotificationBus.openMedications.addListener(_onOpenMedications);
    if (_seenOpens > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openMedicationsFromAlarm();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MedicationNotificationBus.openMedications.removeListener(
      _onOpenMedications,
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref.invalidate(medicationsListProvider);
    ref.read(todayMedicationLogsProvider.notifier).loadTodayLogs();
  }

  void _onShellTop(Route<dynamic>? route) {
    final next = _tabFrom(route);
    if (next == null || next == _tab || !mounted) return;
    setState(() => _tab = next);
  }

  void _goHome() {
    final navigator = _shellNav.currentState;
    if (navigator == null) return;
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  void _openMedicationsFromAlarm() {
    if (!mounted) return;
    final now = DateTime.now();
    final last = _lastMedsNavigation;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      return;
    }
    _lastMedsNavigation = now;
    final navigator = _shellNav.currentState;
    if (navigator == null) return;
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
    navigator.push(_medsPage());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final indicator = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      body: NavigatorPopHandler<void>(
        onPopWithResult: (_) {
          final navigator = _shellNav.currentState;
          if (navigator == null) return;
          navigator.pop();
        },
        child: Navigator(
          key: _shellNav,
          observers: [_tabObserver],
          onGenerateRoute: (_) {
            return MaterialPageRoute<void>(
              settings: const RouteSettings(name: _homeRoute),
              builder: (_) => const HomeScreen(),
            );
          },
        ),
      ),
      bottomNavigationBar: Material(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        child: Padding(
          padding: EdgeInsets.only(bottom: indicator),
          child: SizedBox(
            height: AppSpacing.navBar,
            child: Row(
              children: [
                _NavItem(
                  selected: _tab == _ShellTab.home,
                  icon: AppIcons.home,
                  selectedIcon: AppIcons.homeFilled,
                  label: l10n.navHome,
                  onTap: _goHome,
                ),
                _NavItem(
                  selected: _tab == _ShellTab.routine,
                  icon: AppIcons.routine,
                  selectedIcon: AppIcons.routineFilled,
                  label: l10n.navRoutine,
                  onTap: () => _shellNav.currentState?.push(_routinePage()),
                ),
                _NavItem(
                  selected: _tab == _ShellTab.meds,
                  icon: AppIcons.medication,
                  selectedIcon: AppIcons.medicationFilled,
                  label: l10n.navMeds,
                  onTap: () => _shellNav.currentState?.push(_medsPage()),
                ),
                _NavItem(
                  selected: _tab == _ShellTab.clinic,
                  icon: AppIcons.clinic,
                  selectedIcon: AppIcons.clinicFilled,
                  label: l10n.navClinic,
                  onTap: () => _shellNav.currentState?.push(_clinicPage()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

_ShellTab? _tabFrom(Route<dynamic>? route) {
  switch (route?.settings.name) {
    case _routineRoute:
      return _ShellTab.routine;
    case _medsRoute:
      return _ShellTab.meds;
    case _clinicRoute:
      return _ShellTab.clinic;
    case _homeRoute:
      return _ShellTab.home;
    default:
      if (route?.isFirst ?? false) return _ShellTab.home;
      return null;
  }
}

class _ShellTabObserver extends NavigatorObserver {
  _ShellTabObserver(this.onTop);

  final void Function(Route<dynamic>? route) onTop;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onTop(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onTop(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onTop(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onTop(newRoute);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.mutedText(
      Theme.of(context).brightness == Brightness.dark,
    );
    final primary = Theme.of(context).colorScheme.primary;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final labelStyle =
        Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NavGlyph(
              icon: selected ? selectedIcon : icon,
              color: selected ? primary : muted,
              duration: duration,
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: duration,
              curve: Curves.easeOut,
              style: labelStyle.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? primary : muted,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavGlyph extends ImplicitlyAnimatedWidget {
  const _NavGlyph({
    required this.icon,
    required this.color,
    required super.duration,
  }) : super(curve: Curves.easeOut);

  final IconData icon;
  final Color color;

  @override
  ImplicitlyAnimatedWidgetState<_NavGlyph> createState() => _NavGlyphState();
}

class _NavGlyphState extends AnimatedWidgetBaseState<_NavGlyph> {
  ColorTween? _color;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _color =
        visitor(
              _color,
              widget.color,
              (dynamic value) => ColorTween(begin: value as Color),
            )
            as ColorTween?;
  }

  @override
  Widget build(BuildContext context) {
    return Icon(widget.icon, size: 24, color: _color?.evaluate(animation));
  }
}
