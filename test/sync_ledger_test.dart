import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/core/persistence/sync_ledger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('id vazio já conta como marcado e não é gravado', () async {
    const key = 'test_ledger_empty_id';
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    expect(SyncLedger.contains(prefs, key, ''), isTrue);
    await SyncLedger.remember(prefs, key, '');

    expect(prefs.getString(key), isNull);
  });

  test('JSON ilegível não é reescrito e bloqueia uma marca nova', () async {
    const key = 'test_ledger_bad_json';
    const raw = '{not-a-list';
    SharedPreferences.setMockInitialValues({key: raw});
    final prefs = await SharedPreferences.getInstance();

    expect(SyncLedger.contains(prefs, key, 'snap-1'), isTrue);
    await SyncLedger.remember(prefs, key, 'snap-1');

    expect(prefs.getString(key), raw);
  });

  test('objeto JSON também fica ilegível', () async {
    const key = 'test_ledger_object';
    const raw = '{"a":1}';
    SharedPreferences.setMockInitialValues({key: raw});
    final prefs = await SharedPreferences.getInstance();

    expect(SyncLedger.contains(prefs, key, 'a'), isTrue);
    await SyncLedger.remember(prefs, key, 'a');

    expect(prefs.getString(key), raw);
  });

  test('número vira texto e id ausente ainda pode ser marcado', () async {
    const key = 'test_ledger_nums';
    SharedPreferences.setMockInitialValues({
      key: jsonEncode([1, 'b']),
    });
    final prefs = await SharedPreferences.getInstance();

    expect(SyncLedger.contains(prefs, key, '1'), isTrue);
    expect(SyncLedger.contains(prefs, key, 'b'), isTrue);
    expect(SyncLedger.contains(prefs, key, 'c'), isFalse);
  });

  test('marca repetida não duplica o JSON', () async {
    const key = 'test_ledger_dedupe';
    const raw = '["keep","me"]';
    SharedPreferences.setMockInitialValues({key: raw});
    final prefs = await SharedPreferences.getInstance();

    await SyncLedger.remember(prefs, key, 'keep');

    expect(prefs.getString(key), raw);
    expect(SyncLedger.contains(prefs, key, 'me'), isTrue);
  });

  test('passar de 400 solta os mais antigos', () async {
    const key = 'test_ledger_cap';
    final stored = [for (var i = 0; i < 401; i++) 'id-$i'];
    SharedPreferences.setMockInitialValues({key: jsonEncode(stored)});
    final prefs = await SharedPreferences.getInstance();

    await SyncLedger.remember(prefs, key, 'id-new');

    final saved = (jsonDecode(prefs.getString(key)!) as List).cast<String>();
    expect(saved, hasLength(SyncLedger.maxIds));
    expect(saved.first, 'id-2');
    expect(saved.last, 'id-new');
    expect(saved, isNot(contains('id-0')));
    expect(saved, isNot(contains('id-1')));
  });

  test('dois remembers ao mesmo tempo não se apagam', () async {
    const key = 'test_ledger_concurrent';
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      SyncLedger.remember(prefs, key, 'a'),
      SyncLedger.remember(prefs, key, 'b'),
    ]);

    final saved = (jsonDecode(prefs.getString(key)!) as List).cast<String>();
    expect(saved.toSet(), {'a', 'b'});
  });
}
