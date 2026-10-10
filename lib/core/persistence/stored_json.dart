import 'dart:convert';

/// Resultado de uma leitura de lista JSON persistida.
class StoredJsonListRead<T> {
  const StoredJsonListRead({
    required this.items,
    required this.unreadable,
    required this.hadCorruptItems,
  });

  final List<T> items;

  /// Blob inteiro ilegível (não é lista, JSON quebrado). Não sobrescrever.
  final bool unreadable;

  /// Alguns itens falharam no parse; [items] tem só os válidos.
  final bool hadCorruptItems;

  bool get isEmpty => items.isEmpty;
}

/// Diz se o texto salvo ainda é uma lista de mapas.
///
/// Chave ausente ou vazia pode ser gravada. Texto que não lê fica como está:
/// a atualização do app não pode trocar o JSON antigo por uma lista vazia.
bool storedJsonListIsReadable(String? raw) {
  if (raw == null || raw.isEmpty) return true;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return false;
    for (final item in decoded) {
      if (item is! Map) return false;
    }
    return true;
  } catch (_) {
    return false;
  }
}

/// Blob inteiro que não pode ser regravado.
///
/// Lista com um item podre continua gravável (o item é pulado na leitura).
/// JSON quebrado ou que não é lista fica intacto.
bool storedJsonListBlobIsUnreadable(String? raw) {
  if (raw == null || raw.isEmpty) return false;
  try {
    return jsonDecode(raw) is! List;
  } catch (_) {
    return true;
  }
}

/// Decodifica uma lista JSON numa passada: valida, parseia item a item.
///
/// - Blob ilegível → `unreadable: true`, `items: []` (não gravar por cima).
/// - Item podre → pulado (`hadCorruptItems: true`); os bons entram na lista.
StoredJsonListRead<T> decodeStoredJsonList<T>(
  String? raw,
  T? Function(Map<String, dynamic> map) parseItem,
) {
  if (raw == null || raw.isEmpty) {
    return const StoredJsonListRead(
      items: [],
      unreadable: false,
      hadCorruptItems: false,
    );
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const StoredJsonListRead(
        items: [],
        unreadable: true,
        hadCorruptItems: false,
      );
    }
    final items = <T>[];
    var hadCorrupt = false;
    for (final item in decoded) {
      if (item is! Map) {
        hadCorrupt = true;
        continue;
      }
      try {
        final parsed = parseItem(Map<String, dynamic>.from(item));
        if (parsed == null) {
          hadCorrupt = true;
          continue;
        }
        items.add(parsed);
      } catch (_) {
        hadCorrupt = true;
      }
    }
    return StoredJsonListRead(
      items: items,
      unreadable: false,
      hadCorruptItems: hadCorrupt,
    );
  } catch (_) {
    return const StoredJsonListRead(
      items: [],
      unreadable: true,
      hadCorruptItems: false,
    );
  }
}

String encodeStoredJsonList(Iterable<Map<String, dynamic>> maps) =>
    jsonEncode(maps.toList());
