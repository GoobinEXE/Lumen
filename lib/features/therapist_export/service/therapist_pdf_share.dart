import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

/// Abre o share sheet do sistema com o PDF clínico.
Future<bool> shareTherapistPdf({
  required Uint8List bytes,
  required String filename,
  String? subject,
  String? body,
}) async {
  try {
    return await Printing.sharePdf(
      bytes: bytes,
      filename: filename,
      subject: subject,
      body: body,
    );
  } catch (error, stack) {
    debugPrint('[shareTherapistPdf] $error\n$stack');
    return false;
  }
}
