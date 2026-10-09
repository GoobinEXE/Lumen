import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers.dart';
import '../domain/pdf_report_style.dart';

const pdfReportStyleKey = 'noa_pdf_style_v1';

PdfReportStyle getPdfReportStyle(SharedPreferences prefs) {
  return PdfReportStyleStorage.fromStorage(prefs.getString(pdfReportStyleKey));
}

Future<void> setPdfReportStyle(
  SharedPreferences prefs,
  PdfReportStyle style,
) {
  return prefs.setString(pdfReportStyleKey, style.storageValue);
}

class PdfReportStyleNotifier extends StateNotifier<PdfReportStyle> {
  PdfReportStyleNotifier(this._ref)
    : super(getPdfReportStyle(_ref.read(sharedPreferencesProvider)));

  final Ref _ref;

  Future<void> setStyle(PdfReportStyle style) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await setPdfReportStyle(prefs, style);
    state = style;
  }
}

final pdfReportStyleProvider =
    StateNotifierProvider<PdfReportStyleNotifier, PdfReportStyle>((ref) {
      return PdfReportStyleNotifier(ref);
    });
