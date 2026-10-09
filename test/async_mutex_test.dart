import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/core/persistence/async_mutex.dart';

void main() {
  test('ações concorrentes rodam uma depois da outra', () async {
    final mutex = AsyncMutex();
    final order = <int>[];
    final gate = Completer<void>();

    final first = mutex.synchronized(() async {
      order.add(1);
      await gate.future;
      order.add(2);
      return 'a';
    });
    final second = mutex.synchronized(() async {
      order.add(3);
      return 'b';
    });

    await Future<void>.delayed(Duration.zero);
    expect(order, [1]);

    gate.complete();
    expect(await first, 'a');
    expect(await second, 'b');
    expect(order, [1, 2, 3]);
  });

  test('erro numa ação não trava a fila', () async {
    final mutex = AsyncMutex();

    await expectLater(
      mutex.synchronized<int>(() async => throw StateError('falhou')),
      throwsA(isA<StateError>()),
    );

    expect(await mutex.synchronized(() async => 7), 7);
  });
}
