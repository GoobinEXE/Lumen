import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/system/system_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.prism.lumen/system_settings');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  SystemSettings settings() => SystemSettings(channel: channel);

  test('open manda o nome do destino e trata nulo como falha', () async {
    final seen = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'open');
      final args = call.arguments as Map;
      seen.add(args['target'] as String);
      if (args['target'] == 'locale') return null;
      if (args['target'] == 'notifications') return false;
      return true;
    });

    final api = settings();
    expect(await api.open(SystemSettingsTarget.app), isTrue);
    expect(await api.open(SystemSettingsTarget.healthConnect), isTrue);
    expect(await api.open(SystemSettingsTarget.locale), isFalse);
    expect(await api.open(SystemSettingsTarget.notifications), isFalse);
    expect(seen, ['app', 'healthConnect', 'locale', 'notifications']);
  });

  test('open engole falha de plataforma e plugin ausente', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'unavailable');
    });
    expect(await settings().open(SystemSettingsTarget.app), isFalse);

    messenger.setMockMethodCallHandler(channel, null);
    expect(await settings().open(SystemSettingsTarget.notifications), isFalse);
  });

  test('reduceTransparency só aceita bool', () async {
    Future<bool> read(Object? payload) {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'accessibilityFlags');
        return payload;
      });
      return settings().isReduceTransparencyEnabled();
    }

    expect(await read({'reduceTransparency': true}), isTrue);
    expect(await read({'reduceTransparency': false}), isFalse);
    expect(await read(<String, Object>{}), isFalse);
    expect(await read({'reduceTransparency': 1}), isFalse);
    expect(await read({'reduceTransparency': 'true'}), isFalse);
    expect(await read('true'), isFalse);
    expect(await read(<Object>['reduceTransparency']), isFalse);
    expect(await read(null), isFalse);
  });

  test('flag de acessibilidade ausente fica desligada', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'unavailable');
    });
    expect(await settings().isReduceTransparencyEnabled(), isFalse);

    messenger.setMockMethodCallHandler(channel, null);
    expect(await settings().isReduceTransparencyEnabled(), isFalse);
  });
}
