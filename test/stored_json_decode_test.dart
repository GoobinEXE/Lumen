import 'package:flutter_test/flutter_test.dart';
import 'package:noa/core/persistence/stored_json.dart';

void main() {
  test('decodeStoredJsonList pula item podre e mantém os bons', () {
    final raw = '''
    [
      {"id": "a", "n": 1},
      "broken",
      {"id": "b", "n": 2}
    ]
    ''';
    final read = decodeStoredJsonList<Map<String, dynamic>>(raw, (map) {
      final id = map['id'] as String?;
      if (id == null) return null;
      return map;
    });
    expect(read.unreadable, isFalse);
    expect(read.hadCorruptItems, isTrue);
    expect(read.items.map((e) => e['id']), ['a', 'b']);
  });

  test('decodeStoredJsonList marca blob ilegível', () {
    final read = decodeStoredJsonList<Map<String, dynamic>>(
      '{"not":"a list"}',
      (map) => map,
    );
    expect(read.unreadable, isTrue);
    expect(read.items, isEmpty);
  });

  test('lista vazia ou nula é gravável', () {
    expect(storedJsonListIsReadable(null), isTrue);
    expect(storedJsonListIsReadable(''), isTrue);
    expect(storedJsonListIsReadable('[]'), isTrue);
    expect(storedJsonListBlobIsUnreadable(null), isFalse);
    expect(storedJsonListBlobIsUnreadable(''), isFalse);
    expect(storedJsonListBlobIsUnreadable('[]'), isFalse);
  });

  test('blob ilegível bloqueia gravação e item podre não', () {
    expect(storedJsonListBlobIsUnreadable('{not-json'), isTrue);
    expect(storedJsonListBlobIsUnreadable('{"not":"a list"}'), isTrue);
    expect(storedJsonListBlobIsUnreadable('[{"id":"a"},"broken"]'), isFalse);
  });
}
