import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Empacota as chaves `noa_*` do aparelho num JSON e abre o share do sistema.
class LocalDataExport {
  const LocalDataExport();

  /// Só chaves do Lumen — sem inventar dado e sem tocar no que não é `noa_*`.
  Map<String, Object?> collectKeys(SharedPreferences prefs) {
    final keys = <String, Object?>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith('noa_')) continue;
      keys[key] = prefs.get(key);
    }
    return keys;
  }

  Map<String, Object?> buildPayload(
    SharedPreferences prefs, {
    DateTime? exportedAt,
  }) {
    return {
      'exportedAt': (exportedAt ?? DateTime.now()).toIso8601String(),
      'app': 'lumen',
      'keys': collectKeys(prefs),
    };
  }

  Future<bool> shareBackup(
    SharedPreferences prefs, {
    required String shareSubject,
  }) async {
    File? file;
    try {
      final payload = buildPayload(prefs);
      final encoded = await Isolate.run(() => jsonEncode(payload));
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      file = File('${dir.path}/lumen_backup_$stamp.json');
      await file.writeAsString(encoded);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: shareSubject,
        ),
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      try {
        await file?.delete();
      } catch (_) {}
    }
  }
}
