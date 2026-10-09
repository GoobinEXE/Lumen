/// Estilo visual do relatório PDF clínico.
enum PdfReportStyle {
  /// Branco, tipografia sóbria, acento #1FAF8A.
  clinicalCalm,

  /// Faixa de marca suave (primarySoft) + mesma hierarquia clínica.
  lumenSoft,
}

extension PdfReportStyleStorage on PdfReportStyle {
  String get storageValue => switch (this) {
    PdfReportStyle.clinicalCalm => 'clinical_calm',
    PdfReportStyle.lumenSoft => 'lumen_soft',
  };

  static PdfReportStyle fromStorage(String? raw) {
    switch (raw) {
      case 'lumen_soft':
        return PdfReportStyle.lumenSoft;
      case 'clinical_calm':
      default:
        return PdfReportStyle.clinicalCalm;
    }
  }
}
