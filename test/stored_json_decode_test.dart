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
    expect(
      storedJsonListIsReadable('[{"id":"a"}]'),
      isTrue,
    );
  });

  test('JSON quebrado não é lista gravável e a decodificação não inventa item', () {
    expect(storedJsonListIsReadable('{'), isFalse);
    expect(storedJsonListIsReadable('[{"id":"a"}, 1]'), isFalse);

    final empty = decodeStoredJsonList<String>('', (map) => map['id'] as String);
    expect(empty.unreadable, isFalse);
    expect(empty.items, isEmpty);

    final broken = decodeStoredJsonList<String>('{', (map) => map['id'] as String);
    expect(broken.unreadable, isTrue);
    expect(broken.items, isEmpty);
  });

  test('parser que estoura pula o item e segura o irmão', () {
    final read = decodeStoredJsonList<String>(
      '[{"id":"a"}, {"id":1}, {"id":"b"}]',
      (map) => map['id'] as String,
    );
    expect(read.unreadable, isFalse);
    expect(read.hadCorruptItems, isTrue);
    expect(read.items, ['a', 'b']);
  });
}
