import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// KPI / caixa de estatística do PDF clínico — extraído do generator monolítico.
class TherapistPdfKpi {
  const TherapistPdfKpi({
    required this.accent,
    required this.ink,
    required this.muted,
    required this.cardFill,
    required this.cardBorder,
    required this.kpiRadius,
    required this.fontRegular,
    required this.fontBold,
  });

  final PdfColor accent;
  final PdfColor ink;
  final PdfColor muted;
  final PdfColor cardFill;
  final PdfColor cardBorder;
  final double kpiRadius;
  final pw.Font fontRegular;
  final pw.Font fontBold;

  pw.Widget tile({
    required String title,
    required String value,
    required String subtitle,
    PdfColor? fill,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: fill ?? cardFill,
          borderRadius: pw.BorderRadius.circular(kpiRadius),
          border: pw.Border.all(color: cardBorder, width: 0.6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: muted,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: ink,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: 7.5,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget statBox(String title, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: accent, width: 0.7),
          borderRadius: pw.BorderRadius.circular(kpiRadius),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              title,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: accent,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: 9,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
