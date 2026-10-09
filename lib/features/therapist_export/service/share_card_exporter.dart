import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareCardExporter {
  /// Captura a chave RepaintBoundary como imagem PNG e abre o menu de compartilhamento do iOS/Android
  static Future<bool> captureAndShare({
    required GlobalKey repaintKey,
    required String shareTitle,
    required String shareSubject,
  }) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return false;

      // Renderiza com densidade de pixels para alta resolução (3.0x para telas retina)
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return false;

      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/resumo_clinico_lumen.png');
      try {
        await file.writeAsBytes(pngBytes);

        final xFile = XFile(file.path, mimeType: 'image/png');
        await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            text: shareTitle,
            subject: shareSubject,
          ),
        );
        return true;
      } finally {
        try {
          await file.delete();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[ShareCardExporter] Erro ao exportar imagem do card: $e');
      return false;
    }
  }
}
