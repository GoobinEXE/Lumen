import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/core/theme/lumen_glass_level.dart';
import 'package:noa/core/theme/lumen_glass_style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.prism.lumen/system_settings');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    debugLumenForceFakeGlass = false;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('fora do iOS a flag nativa não liga o vidro sólido', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      return {'reduceTransparency': true};
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final flags = await container.read(lumenGlassAccessibilityProvider.future);
    expect(flags.reduceTransparency, isFalse);
    expect(flags.highContrast, isFalse);
    expect(flags.resolvedLevel, LumenGlassLevel.clear);
    expect(calls, 0);
  });

  test('no iOS o refresh relê a flag e erro do canal fica false', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    var reduce = true;
    var fail = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'accessibilityFlags');
      if (fail) throw PlatformException(code: 'unavailable');
      return {'reduceTransparency': reduce};
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(lumenGlassAccessibilityProvider.notifier);

    final first = await container.read(lumenGlassAccessibilityProvider.future);
    expect(first.reduceTransparency, isTrue);
    expect(first.resolvedLevel, LumenGlassLevel.solid);

    reduce = false;
    await notifier.refresh();
    final second = container.read(lumenGlassAccessibilityProvider).requireValue;
    expect(second.reduceTransparency, isFalse);
    expect(second.resolvedLevel, LumenGlassLevel.clear);

    fail = true;
    await notifier.refresh();
    final third = container.read(lumenGlassAccessibilityProvider).requireValue;
    expect(third.reduceTransparency, isFalse);
    expect(container.read(lumenGlassAccessibilityProvider).hasError, isFalse);
  });

  testWidgets('contraste do sistema tinge; o scope explícito prevalece', (
    tester,
  ) async {
    late LumenGlassLevel fromMedia;
    late LumenGlassLevel fromScope;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(highContrast: true),
            child: child!,
          );
        },
        home: LumenGlassScope(
          level: LumenGlassLevel.clear,
          reduceTransparency: false,
          child: Builder(
            builder: (context) {
              fromScope = LumenGlassScope.levelOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final mediaContext = tester.element(find.byType(LumenGlassScope));
    fromMedia = lumenGlassLevelFromMedia(context: mediaContext);
    expect(fromMedia, LumenGlassLevel.tinted);
    expect(fromScope, LumenGlassLevel.clear);
  });

  testWidgets('sem scope, contraste alto tinge e o padrão fica clear', (
    tester,
  ) async {
    Future<LumenGlassLevel> read({required bool highContrast}) async {
      late LumenGlassLevel level;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(highContrast: highContrast),
              child: child!,
            );
          },
          home: Builder(
            builder: (context) {
              level = LumenGlassScope.levelOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return level;
    }

    expect(await read(highContrast: true), LumenGlassLevel.tinted);
    expect(await read(highContrast: false), LumenGlassLevel.clear);
  });

  testWidgets('flag nativa de contraste entra no nível efetivo', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lumenGlassAccessibilityProvider.overrideWith(
            () => _FixedGlassA11y(
              const LumenGlassAccessibility(highContrast: true),
            ),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(highContrast: false),
              child: child!,
            );
          },
          home: const _LevelLabel(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('tinted'), findsOneWidget);
  });

  testWidgets('preferência da pessoa vence contraste e transparência', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lumenGlassAccessibilityProvider.overrideWith(
            () => _FixedGlassA11y(
              const LumenGlassAccessibility(reduceTransparency: true),
            ),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(highContrast: true),
              child: child!,
            );
          },
          home: const _LevelLabel(preference: LumenGlassLevel.clear),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('clear'), findsOneWidget);
  });

  testWidgets('dependente atualiza quando o nível ou a flag muda', (
    tester,
  ) async {
    var level = LumenGlassLevel.clear;
    var reduce = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                LumenGlassScope(
                  level: level,
                  reduceTransparency: reduce,
                  child: Builder(
                    builder: (context) {
                      final scope = LumenGlassScope.maybeOf(context)!;
                      return Text(
                        '${scope.level.name}:${scope.reduceTransparency}',
                      );
                    },
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => reduce = true),
                  child: const Text('flag'),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => level = LumenGlassLevel.tinted),
                  child: const Text('nivel'),
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(find.text('clear:false'), findsOneWidget);
    await tester.tap(find.text('flag'));
    await tester.pump();
    expect(find.text('clear:true'), findsOneWidget);
    await tester.tap(find.text('nivel'));
    await tester.pump();
    expect(find.text('tinted:true'), findsOneWidget);
  });

  testWidgets(
    'reduzir movimento força FakeGlass e zera blur no chrome clear',
    (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: true, highContrast: false),
              child: child!,
            );
          },
          home: LumenGlassScope(
            level: LumenGlassLevel.clear,
            reduceTransparency: false,
            child: Builder(
              builder: (context) {
                captured = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(
        lumenGlassUseFake(context: captured, role: LumenGlassRole.navBar),
        isTrue,
      );
      expect(
        lumenGlassUseFake(context: captured, role: LumenGlassRole.appBar),
        isTrue,
      );
      final nav = lumenGlassSettings(
        context: captured,
        role: LumenGlassRole.navBar,
      );
      expect(nav.blur, 0);
      expect(nav.chromaticAberration, 0);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}

class _FixedGlassA11y extends LumenGlassAccessibilityNotifier {
  _FixedGlassA11y(this.value);

  final LumenGlassAccessibility value;

  @override
  Future<LumenGlassAccessibility> build() async => value;
}

class _LevelLabel extends ConsumerWidget {
  const _LevelLabel({this.preference});

  final LumenGlassLevel? preference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lumenGlassAccessibilityProvider);
    if (!async.hasValue) return const SizedBox.shrink();
    return Text(lumenGlassLevelOf(context, ref, preference: preference).name);
  }
}
