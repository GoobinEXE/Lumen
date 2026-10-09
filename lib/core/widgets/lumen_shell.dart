import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/calendar/presentation/routine_calendar_screen.dart';
import '../../features/home/presentation/home_ficha_screen.dart';
import '../../features/medications/presentation/medications_screen.dart';
import '../../features/medications/presentation/providers/medication_providers.dart';
import '../../features/medications/service/medication_notification_bus.dart';
import '../../features/onboarding/presentation/first_launch_onboarding.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/routine_mood/presentation/daily_routine_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/tasks/presentation/task_providers.dart';
import '../../features/tasks/service/task_notification_bus.dart';
import '../../features/tasks/presentation/tasks_hub_screen.dart';
import '../../features/therapist_export/presentation/clinical_folder_screen.dart';
import '../icons/app_icons.dart';
import '../localization/locale_provider.dart';
import 'glass_nav_bar.dart';

const _homeRoute = '/';
const _routineRoute = '/routine';
const _medsRoute = '/meds';
const _clinicalFolderRoute = '/clinical-folder';

enum _ShellTab { home, routine, meds, clinicFolder }

void openRoutineScreen(BuildContext context) {
  _LumenShellScope.of(context).showTab(_ShellTab.routine);
}

void openMedicationsScreen(BuildContext context) {
  _LumenShellScope.of(context).showTab(_ShellTab.meds);
}

/// Porta canônica da Pasta clínica. Troca para a aba e garante que ela
/// mostra a própria raiz (sem resquício de navegação anterior).
void openClinicalFolderScreen(BuildContext context) {
  _LumenShellScope.of(context).showTab(_ShellTab.clinicFolder);
}

/// Porta canônica de Tarefas: aba Início, raiz, com `TasksHubScreen`
/// empilhada por cima. Única pilha possível — reusada pela Home e pela Dia.
void openTasksHub(BuildContext context) {
  final scope = _LumenShellScope.of(context);
  scope.showTab(_ShellTab.home);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final nav = scope.navigatorFor(_ShellTab.home);
    if (nav == null) return;
    nav.push(MaterialPageRoute<void>(builder: (_) => const TasksHubScreen()));
  });
}

/// Porta canônica de "Meus dias": mesma política de pilha de [openTasksHub]
/// (aba Início, raiz, calendário empilhado por cima), reusada pela Home e
/// pela Dia.
void openRoutineCalendarScreen(BuildContext context) {
  final scope = _LumenShellScope.of(context);
  scope.showTab(_ShellTab.home);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final nav = scope.navigatorFor(_ShellTab.home);
    if (nav == null) return;
    nav.push(
      MaterialPageRoute<void>(builder: (_) => const RoutineCalendarScreen()),
    );
  });
}

/// Abre a tela de perfil (feed). Empilha no navegador da aba ativa quando o
/// shell existe; senão cai no [Navigator] do próprio contexto (ex.: testes).
void openProfileScreen(BuildContext context) {
  final scope = context.getInheritedWidgetOfExactType<_LumenShellScope>();
  final navigator = scope == null
      ? null
      : scope.navigatorFor(scope.activeTab());
  final target = navigator ?? Navigator.of(context);
  target.push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
}

/// Abre o hub de configurações (empilha no navegador ativo, tipicamente sobre o perfil).
void openSettingsScreen(BuildContext context) {
  final scope = context.getInheritedWidgetOfExactType<_LumenShellScope>();
  final navigator = scope == null
      ? null
      : scope.navigatorFor(scope.activeTab());
  final target = navigator ?? Navigator.of(context);
  target.push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
}

class _LumenShellScope extends InheritedWidget {
  const _LumenShellScope({
    required this.showTab,
    required this.navigatorFor,
    required this.activeTab,
    required super.child,
  });

  final ValueChanged<_ShellTab> showTab;
  final NavigatorState? Function(_ShellTab tab) navigatorFor;
  final _ShellTab Function() activeTab;

  static _LumenShellScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_LumenShellScope>();
    assert(scope != null, 'LumenShell scope missing');
    return scope!;
  }

  @override
  bool updateShouldNotify(_LumenShellScope oldWidget) =>
      showTab != oldWidget.showTab ||
      navigatorFor != oldWidget.navigatorFor ||
      activeTab != oldWidget.activeTab;
}

class LumenShell extends ConsumerStatefulWidget {
  const LumenShell({super.key});

  @override
  ConsumerState<LumenShell> createState() => _LumenShellState();
}

class _LumenShellState extends ConsumerState<LumenShell>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final List<GlobalKey<NavigatorState>> _navKeys =
      List<GlobalKey<NavigatorState>>.generate(
        _ShellTab.values.length,
        (_) => GlobalKey<NavigatorState>(),
      );
  late final List<_StackObserver> _observers;
  final List<int> _tabHistory = <int>[_ShellTab.home.index];
  final ValueNotifier<bool> _activeCanPopNotifier = ValueNotifier<bool>(false);
  int _index = _ShellTab.home.index;
  bool _nestedPopInProgress = false;
  bool _stackRefreshQueued = false;
  late final VoidCallback _onOpenMedications;
  late final VoidCallback _onOpenRoutine;
  late final VoidCallback _onOpenTasks;
  int _seenOpens = 0;
  int _seenRoutineOpens = 0;
  int _seenTasksOpens = 0;
  DateTime? _lastMedsNavigation;
  DateTime? _lastRoutineNavigation;
  DateTime? _lastTasksNavigation;

  @override
  void initState() {
    super.initState();
    _observers = List<_StackObserver>.generate(
      _ShellTab.values.length,
      (_) => _StackObserver(_onStackChanged),
    );
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
    _seenRoutineOpens = TaskNotificationBus.openRoutine.value;
    _onOpenRoutine = () {
      final next = TaskNotificationBus.openRoutine.value;
      if (next == _seenRoutineOpens) return;
      _seenRoutineOpens = next;
      _openRoutineFromAlarm();
    };
    TaskNotificationBus.openRoutine.addListener(_onOpenRoutine);
    if (_seenRoutineOpens > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openRoutineFromAlarm();
      });
    }
    _seenTasksOpens = TaskNotificationBus.openTasks.value;
    _onOpenTasks = () {
      final next = TaskNotificationBus.openTasks.value;
      if (next == _seenTasksOpens) return;
      _seenTasksOpens = next;
      _openTasksFromAlarm();
    };
    TaskNotificationBus.openTasks.addListener(_onOpenTasks);
    if (_seenTasksOpens > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openTasksFromAlarm();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FirstLaunchOnboarding.maybeShow(context, ref);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MedicationNotificationBus.openMedications.removeListener(
      _onOpenMedications,
    );
    TaskNotificationBus.openRoutine.removeListener(_onOpenRoutine);
    TaskNotificationBus.openTasks.removeListener(_onOpenTasks);
    _pageController.dispose();
    _activeCanPopNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref.invalidate(medicationsListProvider);
    ref.read(todayMedicationLogsProvider.notifier).loadTodayLogs();
    ref.read(tasksListProvider.notifier).load();
  }

  void _onStackChanged() {
    if (!mounted || _stackRefreshQueued) return;
    _stackRefreshQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stackRefreshQueued = false;
      if (mounted) _syncActiveCanPop();
    });
  }

  void _syncActiveCanPop() {
    final canPop = _navKeys[_index].currentState?.canPop() ?? false;
    if (_activeCanPopNotifier.value != canPop) {
      _activeCanPopNotifier.value = canPop;
    }
  }

  void _remember(int index) {
    if (_tabHistory.last == index) return;
    _tabHistory.remove(index);
    _tabHistory.add(index);
  }

  void _showTab(_ShellTab tab) {
    if (!mounted) return;
    final index = tab.index;
    if (index == _index) {
      _popToRoot(index);
      return;
    }
    // A aba de origem não pode ficar com uma tela empilhada escondida atrás
    // da troca de aba (ex.: Configurações aberta a partir da Home).
    _popToRoot(_index);
    // A aba de destino sempre mostra a própria raiz ao ser selecionada pela
    // tab bar ou por um atalho que troca de aba.
    _popToRoot(index);
    _remember(index);
    if (!MediaQuery.disableAnimationsOf(context)) {
      HapticFeedback.selectionClick();
    }
    setState(() => _index = index);
    _moveTo(index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncActiveCanPop();
    });
  }

  void _popToRoot(int index) {
    final navigator = _navKeys[index].currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  void _moveTo(int index) {
    if (!_pageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _index == index) _moveTo(index);
      });
      return;
    }
    // Android: jump evita ~280 ms de animatedBuilder + glass a cada frame
    // na troca de aba (principal fonte de travamento relatada nos testes).
    final skipPageAnim = MediaQuery.disableAnimationsOf(context) ||
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);
    if (skipPageAnim) {
      _pageController.jumpToPage(index);
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    _remember(index);
    if (!mounted || index == _index) return;
    setState(() => _index = index);
    _syncActiveCanPop();
  }

  void _popVisibleTab() {
    final navigator = _navKeys[_index].currentState;
    if (navigator == null || !navigator.canPop()) return;
    _nestedPopInProgress = true;
    navigator.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nestedPopInProgress = false;
    });
  }

  void _onSystemBack(bool didPop, Object? _) {
    if (didPop || _nestedPopInProgress) return;
    final navigator = _navKeys[_index].currentState;
    if (navigator != null && navigator.canPop()) return;
    if (_index == _ShellTab.home.index) return;
    _selectPreviousTab();
  }

  void _selectPreviousTab() {
    if (_tabHistory.length > 1 && _tabHistory.last == _index) {
      _tabHistory.removeLast();
    }
    final previous = _tabHistory.isEmpty
        ? _ShellTab.home.index
        : _tabHistory.last;
    if (previous == _index) return;
    setState(() => _index = previous);
    _moveTo(previous);
    _syncActiveCanPop();
  }

  void _openMedicationsFromAlarm() {
    if (!mounted) return;
    final now = DateTime.now();
    final last = _lastMedsNavigation;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      return;
    }
    _lastMedsNavigation = now;
    _showTab(_ShellTab.meds);
  }

  void _openRoutineFromAlarm() {
    if (!mounted) return;
    final now = DateTime.now();
    final last = _lastRoutineNavigation;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      return;
    }
    _lastRoutineNavigation = now;
    _showTab(_ShellTab.routine);
  }

  void _openTasksFromAlarm() {
    if (!mounted) return;
    final now = DateTime.now();
    final last = _lastTasksNavigation;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      return;
    }
    _lastTasksNavigation = now;
    _showTab(_ShellTab.home);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nav = _navKeys[_ShellTab.home.index].currentState;
      if (nav == null) return;
      nav.push(MaterialPageRoute<void>(builder: (_) => const TasksHubScreen()));
    });
  }

  ScrollPhysics _pagePhysics(BuildContext context, {required bool canPop}) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion || canPop) {
      return const NeverScrollableScrollPhysics();
    }
    return const PageScrollPhysics();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final media = MediaQuery.of(context);
    final indicator = media.viewPadding.bottom;
    final reservedBottom = GlassNavBar.reservedBottom(context);
    // Full-bleed: o PageView pinta atrás da cápsula. O inset vai só no
    // MediaQuery.padding (FAB / SafeArea / ensureVisible) — Padding físico
    // deixava o scaffold sólido atrás do vidro e matava a translucidez.
    //
    // Teclado: resizeToAvoidBottomInset false — o shell/tab bar NÃO sobe com
    // o teclado. Gavetas usam showLumenSheet / LumenKeyboardInset.

    return _LumenShellScope(
      showTab: _showTab,
      navigatorFor: (tab) => _navKeys[tab.index].currentState,
      activeTab: () => _ShellTab.values[_index],
      child: Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          fit: StackFit.expand,
          children: [
            MediaQuery(
              data: media.copyWith(
                padding: media.padding.copyWith(bottom: reservedBottom),
              ),
              // canPop/physics: ValueNotifier — push/pop não rebuilda a nav.
              child: ValueListenableBuilder<bool>(
                valueListenable: _activeCanPopNotifier,
                builder: (context, activeCanPop, _) {
                  final shellCanPop =
                      _index == _ShellTab.home.index || activeCanPop;
                  return PopScope<Object?>(
                    canPop: shellCanPop,
                    onPopInvokedWithResult: _onSystemBack,
                    child: PageView(
                      controller: _pageController,
                      physics: _pagePhysics(context, canPop: activeCanPop),
                      onPageChanged: _onPageChanged,
                      children: [
                        for (final tab in _ShellTab.values)
                          _ShellPage(
                            key: ValueKey<String>(tab.name),
                            navigatorKey: _navKeys[tab.index],
                            observer: _observers[tab.index],
                            enabled: _index == tab.index,
                            routeName: _routeName(tab),
                            onPopNested: _popVisibleTab,
                            child: _rootFor(tab),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: GlassNavBar.horizontalInset,
              right: GlassNavBar.horizontalInset,
              bottom: indicator + GlassNavBar.bottomGap,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, _) {
                    final page = _pageController.hasClients
                        ? (_pageController.page ?? _index.toDouble())
                        : _index.toDouble();
                    return GlassNavBar(
                      position: page,
                      onSelected: (i) => _showTab(_ShellTab.values[i]),
                      destinations: [
                        GlassNavDestination(
                          icon: AppIcons.home,
                          selectedIcon: AppIcons.homeFilled,
                          label: l10n.navHome,
                          hint: l10n.navOpensTabHint(l10n.navHome),
                        ),
                        GlassNavDestination(
                          icon: AppIcons.routine,
                          selectedIcon: AppIcons.routineFilled,
                          label: l10n.navRoutine,
                          hint: l10n.navOpensTabHint(l10n.navRoutine),
                        ),
                        GlassNavDestination(
                          icon: AppIcons.medication,
                          selectedIcon: AppIcons.medicationFilled,
                          label: l10n.navMeds,
                          hint: l10n.navOpensTabHint(l10n.navMeds),
                        ),
                        GlassNavDestination(
                          icon: AppIcons.clinic,
                          selectedIcon: AppIcons.clinicFilled,
                          label: l10n.navClinicalFolder,
                          hint: l10n.navOpensTabHint(l10n.navClinicalFolder),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _routeName(_ShellTab tab) {
  return switch (tab) {
    _ShellTab.home => _homeRoute,
    _ShellTab.routine => _routineRoute,
    _ShellTab.meds => _medsRoute,
    _ShellTab.clinicFolder => _clinicalFolderRoute,
  };
}

Widget _rootFor(_ShellTab tab) {
  return switch (tab) {
    _ShellTab.home => const HomeFichaScreen(),
    _ShellTab.routine => const DailyRoutineScreen(),
    _ShellTab.meds => const MedicationsScreen(),
    _ShellTab.clinicFolder => const ClinicalFolderScreen(),
  };
}

class _ShellPage extends StatefulWidget {
  const _ShellPage({
    super.key,
    required this.navigatorKey,
    required this.observer,
    required this.enabled,
    required this.routeName,
    required this.onPopNested,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final NavigatorObserver observer;
  final bool enabled;
  final String routeName;
  final VoidCallback onPopNested;
  final Widget child;

  @override
  State<_ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<_ShellPage>
    with AutomaticKeepAliveClientMixin {
  /// Monta o Navigator só na primeira visita; depois mantém vivo.
  bool _visited = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _visited = true;
  }

  @override
  void didUpdateWidget(covariant _ShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_visited) {
      _visited = true;
      updateKeepAlive();
    }
  }

  @override
  bool get wantKeepAlive => _visited;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_visited) {
      return const SizedBox.shrink();
    }
    return NavigatorPopHandler<void>(
      enabled: widget.enabled,
      onPopWithResult: (_) {
        if (!widget.enabled) return;
        widget.onPopNested();
      },
      child: Navigator(
        key: widget.navigatorKey,
        observers: [widget.observer],
        onGenerateRoute: (_) {
          return MaterialPageRoute<void>(
            settings: RouteSettings(name: widget.routeName),
            builder: (_) => widget.child,
          );
        },
      ),
    );
  }
}

class _StackObserver extends NavigatorObserver {
  _StackObserver(this.onChanged);

  final VoidCallback onChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onChanged();
  }
}

