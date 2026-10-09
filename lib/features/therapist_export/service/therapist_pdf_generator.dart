import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:noa/core/localization/correlation_copy.dart';
import 'package:noa/core/localization/l10n_labels.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/routine_mood/domain/routine_export.dart';
import 'package:noa/features/therapist_export/domain/export_tasks.dart';
import 'package:noa/features/therapist_export/domain/period_export_stats.dart';
import 'package:noa/features/therapist_export/domain/pdf_report_style.dart';
import 'package:noa/features/sleep_analytics/domain/correlation_engine.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_labels.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';
import 'package:noa/features/therapist_export/service/routine_export_copy.dart';
import 'package:noa/features/therapist_export/service/therapist_pdf_kpi.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class _PdfPalette {
  const _PdfPalette({
    required this.accent,
    required this.accentSoft,
    required this.ink,
    required this.muted,
    required this.cardFill,
    required this.cardBorder,
    required this.headerFill,
    required this.dangerSoft,
    required this.warningSoft,
    required this.lavenderSoft,
    required this.kpiRadius,
  });

  final PdfColor accent;
  final PdfColor accentSoft;
  final PdfColor ink;
  final PdfColor muted;
  final PdfColor cardFill;
  final PdfColor cardBorder;
  final PdfColor? headerFill;
  final PdfColor dangerSoft;
  final PdfColor warningSoft;
  final PdfColor lavenderSoft;
  final double kpiRadius;

  static _PdfPalette forStyle(PdfReportStyle style) {
    const accent = PdfColor.fromInt(0xFF1FAF8A);
    const accentSoft = PdfColor.fromInt(0xFFE0F7EF);
    const ink = PdfColor.fromInt(0xFF1A1A1E);
    const muted = PdfColor.fromInt(0xFF6B6560);
    const border = PdfColor.fromInt(0xFFE8E4DF);
    const dangerSoft = PdfColor.fromInt(0xFFFDECEA);
    const warningSoft = PdfColor.fromInt(0xFFFFF4E5);
    const lavender = PdfColor.fromInt(0xFFF0EDF9);

    return switch (style) {
      PdfReportStyle.clinicalCalm => const _PdfPalette(
        accent: accent,
        accentSoft: PdfColor.fromInt(0xFFF7FBFA),
        ink: ink,
        muted: muted,
        cardFill: PdfColors.white,
        cardBorder: border,
        headerFill: null,
        dangerSoft: dangerSoft,
        warningSoft: warningSoft,
        lavenderSoft: lavender,
        kpiRadius: 6,
      ),
      PdfReportStyle.lumenSoft => const _PdfPalette(
        accent: accent,
        accentSoft: accentSoft,
        ink: ink,
        muted: muted,
        cardFill: accentSoft,
        cardBorder: border,
        headerFill: accentSoft,
        dangerSoft: dangerSoft,
        warningSoft: warningSoft,
        lavenderSoft: lavender,
        kpiRadius: 10,
      ),
    };
  }
}

class TherapistPdfGenerator {
  static pw.Font? _fontRegular;
  static pw.Font? _fontBold;
  static ByteData? _fontRegularData;
  static ByteData? _fontBoldData;

  static Future<void> _ensureFonts() async {
    if (_fontRegular != null && _fontBold != null) return;
    _fontRegularData ??=
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    _fontBoldData ??= await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    _fontRegular = pw.Font.ttf(_fontRegularData!);
    _fontBold = pw.Font.ttf(_fontBoldData!);
  }

  static Future<Uint8List> generateReport({
    required String patientName,
    required List<SleepRecord> sleepRecords,
    required List<MoodEntry> moodEntries,
    required AppLocalizations l10n,
    List<DailyRecoverySnapshot> recoverySnapshots = const [],
    int periodDays = 7,
    int appleHealthSomCount = 0,
    List<RoutineExportLine> routineLines = const [],
    List<TaskExportLine> taskLines = const [],
    String? tasksHeading,
    String? tasksNone,
    String? tasksCompletedMarker,
    String? tasksOpenMarker,
    PdfReportStyle style = PdfReportStyle.clinicalCalm,
  }) async {
    await _ensureFonts();
    final pdf = pw.Document();
    final palette = _PdfPalette.forStyle(style);
    final base = _fontRegular!;
    final bold = _fontBold!;
    final theme = pw.ThemeData.withFont(base: base, bold: bold);

    final locale = l10n.localeName;
    final languageCode = locale.split('_').first;
    try {
      await initializeDateFormatting(locale);
    } catch (_) {}
    final dateFormat = _dateFormat('dd/MM/yyyy', locale);
    final timeFormat = _dateFormat('HH:mm', locale);

    final stats = PeriodExportStats.from(
      sleepRecords: sleepRecords,
      moodEntries: moodEntries,
      recoverySnapshots: recoverySnapshots,
      routineLines: routineLines,
      appleHealthSomCount: appleHealthSomCount,
    );
    final avgSleepHours = stats.avgSleepHours;
    final avgRemHours = stats.avgRemHours;
    final deficitNightsCount = stats.deficitNights;
    final paralyzedCount = stats.paralyzedCount;
    final hyperfocusCount = stats.hyperfocusCount;
    final scatteredCount = stats.scatteredCount;
    final focusedCount = stats.focusedCount;
    final sensoryCount = stats.sensoryCount;
    final medCount = stats.medCount;
    final topLabels = stats.topEmotionLabels;
    final avgHrv = stats.avgHrv;
    final avgResting = stats.avgRestingHeartRate;
    final avgSteps = stats.avgSteps;
    final avgExercise = stats.avgExerciseMinutes;
    final avgDaylight = stats.avgDaylightMinutes;
    final avgNoise = stats.avgNoiseDb;
    final somFromApple = stats.somFromAppleCount;

    final insights = CorrelationEngine.analyze(
      sleepRecords: sleepRecords,
      moodEntries: moodEntries,
      recoverySnapshots: recoverySnapshots,
      copy: L10nCorrelationCopy(l10n),
    );

    final List<List<dynamic>> tableData = sleepRecords.take(7).map((s) {
      return <dynamic>[
        dateFormat.format(s.date),
        timeFormat.format(s.bedtime),
        timeFormat.format(s.wakeTime),
        '${s.totalHours.toStringAsFixed(1)}h',
        '${s.remHours.toStringAsFixed(1)}h',
        '${s.deepHours.toStringAsFixed(1)}h',
        '${s.qualityScore}/100',
      ];
    }).toList();

    final recoveryCards = <pw.Widget>[
      if (avgHrv != null)
        _kpiTile(
          palette: palette,
          title: l10n.pdfHrvAvgTitle,
          value: '${avgHrv.toStringAsFixed(0)} ms',
          subtitle: l10n.pdfHrvSubtitle,
        ),
      if (avgResting != null)
        _kpiTile(
          palette: palette,
          title: l10n.pdfRestingHrTitle,
          value: '${avgResting.toStringAsFixed(0)} bpm',
          subtitle: l10n.pdfPeriodAverage,
        ),
      if (avgSteps != null)
        _kpiTile(
          palette: palette,
          title: l10n.pdfStepsPerDayTitle,
          value: avgSteps.toStringAsFixed(0),
          subtitle: l10n.pdfPeriodAverage,
        ),
      if (avgExercise != null)
        _kpiTile(
          palette: palette,
          title: l10n.pdfExerciseTitle,
          value: '${avgExercise.toStringAsFixed(0)} min',
          subtitle: l10n.pdfDailyAverage,
        ),
      if (avgDaylight != null)
        _kpiTile(
          palette: palette,
          title: l10n.pdfDaylightTitle,
          value: '${avgDaylight.toStringAsFixed(0)} min',
          subtitle: l10n.pdfDailyAverage,
          fill: palette.warningSoft,
        ),
      if (avgNoise != null)
        _kpiTile(
          palette: palette,
          title: l10n.pdfNoiseTitle,
          value: '${avgNoise.toStringAsFixed(0)} dB',
          subtitle: l10n.pdfPeriodAverage,
        ),
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: theme,
        build: (pw.Context context) {
          return [
            _buildHeader(
              palette: palette,
              l10n: l10n,
              patientName: patientName,
              periodDays: periodDays,
              issuedAt: dateFormat.format(DateTime.now()),
            ),
            pw.SizedBox(height: 16),
            _sectionTitle(l10n.pdfAtAGlanceTitle, palette),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _kpiTile(
                  palette: palette,
                  title: l10n.pdfAvgSleepTitle,
                  value: l10n.pdfAvgSleepValue(
                    avgSleepHours.toStringAsFixed(1),
                  ),
                  subtitle: l10n.pdfDeficitNights(
                    deficitNightsCount,
                    sleepRecords.length,
                  ),
                  fill: avgSleepHours < 6.5
                      ? palette.dangerSoft
                      : palette.cardFill,
                ),
                pw.SizedBox(width: 8),
                _kpiTile(
                  palette: palette,
                  title: l10n.pdfKpiParalysisTitle,
                  value: l10n.pdfReportsLabel(paralyzedCount),
                  subtitle: l10n.pdfStatParalyzed,
                  fill: paralyzedCount > 0
                      ? palette.dangerSoft
                      : palette.cardFill,
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _kpiTile(
                  palette: palette,
                  title: l10n.pdfAvgRemTitle,
                  value: '${avgRemHours.toStringAsFixed(1)}h',
                  subtitle: avgRemHours < 1.25
                      ? l10n.pdfRemDeficitAlert
                      : l10n.pdfRemWithinExpected,
                  fill: avgRemHours < 1.25
                      ? palette.warningSoft
                      : palette.cardFill,
                ),
                pw.SizedBox(width: 8),
                _kpiTile(
                  palette: palette,
                  title: l10n.pdfKpiMedicationTitle,
                  value: '$medCount / ${moodEntries.length}',
                  subtitle: l10n.pdfMedicationTaken(
                    medCount,
                    moodEntries.length,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            _sectionTitle(l10n.pdfSection1Sleep, palette),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _kpiTile(
                  palette: palette,
                  title: l10n.pdfAvgSleepTitle,
                  value: l10n.pdfAvgSleepValue(
                    avgSleepHours.toStringAsFixed(1),
                  ),
                  subtitle: l10n.pdfDeficitNights(
                    deficitNightsCount,
                    sleepRecords.length,
                  ),
                  fill: avgSleepHours < 6.5
                      ? palette.dangerSoft
                      : palette.accentSoft,
                ),
                pw.SizedBox(width: 8),
                _kpiTile(
                  palette: palette,
                  title: l10n.pdfAvgRemTitle,
                  value: '${avgRemHours.toStringAsFixed(1)}h',
                  subtitle: avgRemHours < 1.25
                      ? l10n.pdfRemDeficitAlert
                      : l10n.pdfRemWithinExpected,
                  fill: avgRemHours < 1.25
                      ? palette.warningSoft
                      : palette.accentSoft,
                ),
              ],
            ),
            if (tableData.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: [
                  l10n.pdfColDate,
                  l10n.pdfColBedtime,
                  l10n.pdfColWake,
                  l10n.pdfColTotal,
                  l10n.pdfColRem,
                  l10n.pdfColDeep,
                  l10n.pdfColScore,
                ],
                data: tableData,
                headerStyle: pw.TextStyle(
                  font: bold,
                  fontSize: 8,
                  color: palette.ink,
                ),
                cellStyle: pw.TextStyle(
                  font: base,
                  fontSize: 8,
                  color: palette.ink,
                ),
                headerDecoration: pw.BoxDecoration(color: palette.accentSoft),
                border: pw.TableBorder.all(
                  color: palette.cardBorder,
                  width: 0.4,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 5,
                ),
              ),
            ],
            if (recoveryCards.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              _sectionTitle(l10n.pdfSection1bRecovery, palette),
              pw.SizedBox(height: 8),
              ..._chunkRows(recoveryCards, perRow: 3),
            ],
            pw.SizedBox(height: 18),
            _sectionTitle(l10n.pdfSection2Executive, palette),
            pw.SizedBox(height: 8),
            ..._chunkRows([
              _statBox(palette, l10n.pdfStatParalyzed, l10n.pdfReportsLabel(paralyzedCount)),
              _statBox(palette, l10n.pdfStatScattered, l10n.pdfReportsLabel(scatteredCount)),
              _statBox(palette, l10n.pdfStatFocused, l10n.pdfReportsLabel(focusedCount)),
              _statBox(palette, l10n.pdfStatHyperfocus, l10n.pdfReportsLabel(hyperfocusCount)),
              _statBox(palette, l10n.pdfStatSensory, l10n.pdfTimesLabel(sensoryCount)),
            ], perRow: 3),
            if (topLabels.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: style == PdfReportStyle.lumenSoft
                      ? palette.lavenderSoft
                      : palette.accentSoft,
                  borderRadius: pw.BorderRadius.circular(palette.kpiRadius),
                  border: pw.Border.all(color: palette.cardBorder, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      l10n.pdfTopEmotionWords,
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 9,
                        color: palette.ink,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      topLabels
                          .take(8)
                          .map(
                            (e) =>
                                '${StateOfMindLabels.label(e.key, languageCode)} (${e.value}x)',
                          )
                          .join(' · '),
                      style: pw.TextStyle(
                        font: base,
                        fontSize: 9,
                        color: palette.ink,
                      ),
                    ),
                    if (somFromApple > 0) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        l10n.pdfSomFromAppleHealth(somFromApple),
                        style: pw.TextStyle(
                          font: base,
                          fontSize: 8,
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (insights.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              _sectionTitle(l10n.pdfSection3Correlations, palette),
              pw.SizedBox(height: 6),
              ...insights.map((insight) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(
                      color: palette.cardBorder,
                      width: 0.5,
                    ),
                    borderRadius: pw.BorderRadius.circular(palette.kpiRadius),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        insight.title,
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 10.5,
                          color: palette.accent,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        insight.description,
                        style: pw.TextStyle(
                          font: base,
                          fontSize: 9.5,
                          color: palette.ink,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        l10n.pdfClinicalSuggestion(insight.actionableAdvice),
                        style: pw.TextStyle(
                          font: base,
                          fontSize: 8.5,
                          color: palette.muted,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            pw.SizedBox(height: 14),
            _sectionTitle(l10n.pdfSection4Triggers, palette),
            pw.SizedBox(height: 6),
            ...moodEntries
                .where((m) => m.note != null && m.note!.isNotEmpty)
                .take(5)
                .map((entry) {
                  final labels = entry.emotionLabels
                      .map((id) => StateOfMindLabels.label(id, languageCode))
                      .join(', ');
                  final labelsSuffix = labels.isNotEmpty ? ' · $labels' : '';
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 6),
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        left: pw.BorderSide(color: palette.accent, width: 3),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          l10n.pdfEntryLine(
                            dateFormat.format(entry.timestamp),
                            timeFormat.format(entry.timestamp),
                            entry.focus.label(l10n),
                            entry.valenceLabel(l10n),
                            labelsSuffix,
                          ),
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 8.5,
                            color: palette.muted,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '"${entry.note}"',
                          style: pw.TextStyle(
                            font: base,
                            fontSize: 9,
                            color: palette.ink,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            if (routineLines.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              _sectionTitle(l10n.exportRoutineHeading, palette),
              pw.SizedBox(height: 4),
              pw.Text(
                l10n.exportRoutineCount(routineLines.length),
                style: pw.TextStyle(
                  font: base,
                  fontSize: 9,
                  color: palette.muted,
                ),
              ),
              pw.SizedBox(height: 8),
              ...routineLines.map((line) {
                final rows = describeRoutineExportLine(
                  l10n: l10n,
                  line: line,
                  dateFormat: dateFormat,
                  timeFormat: timeFormat,
                  languageCode: languageCode,
                );
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      for (final row in rows)
                        pw.Text(
                          row,
                          style: pw.TextStyle(
                            font: base,
                            fontSize: 9,
                            color: palette.ink,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
            if (tasksHeading != null) ...[
              pw.SizedBox(height: 18),
              _sectionTitle(tasksHeading, palette),
              pw.SizedBox(height: 6),
              ...() {
                final rows = describeTaskExportLines(
                  lines: taskLines,
                  heading: tasksHeading,
                  none: tasksNone ?? '',
                  completedMarker: tasksCompletedMarker ?? 'Feita:',
                  openMarker: tasksOpenMarker ?? 'Aberta:',
                ).skip(1);
                return rows.map(
                  (row) => pw.Text(
                    row,
                    style: pw.TextStyle(
                      font: base,
                      fontSize: 9,
                      color: palette.ink,
                    ),
                  ),
                );
              }(),
            ],
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Text(
                l10n.pdfFooterDisclaimer,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: base,
                  fontSize: 7.5,
                  color: palette.muted,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                l10n.pdfDeviceFooter,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 8,
                  color: palette.accent,
                ),
              ),
            ),
          ];
        },
      ),
    );

    // save() é async e faz a serialização/deflate; layout usa l10n e fica na UI.
    return pdf.save();
  }

  static pw.Widget _buildHeader({
    required _PdfPalette palette,
    required AppLocalizations l10n,
    required String patientName,
    required int periodDays,
    required String issuedAt,
  }) {
    final content = pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                l10n.pdfHeaderTitle,
                style: pw.TextStyle(
                  font: _fontBold,
                  color: palette.accent,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                l10n.pdfHeaderSubtitle,
                style: pw.TextStyle(
                  font: _fontBold,
                  color: palette.ink,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                l10n.pdfPatientPeriod(patientName, periodDays),
                style: pw.TextStyle(
                  font: _fontRegular,
                  color: palette.muted,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              l10n.pdfIssuedAt(issuedAt),
              style: pw.TextStyle(
                font: _fontRegular,
                fontSize: 9,
                color: palette.muted,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              l10n.pdfSourceLine,
              style: pw.TextStyle(
                font: _fontRegular,
                fontSize: 8.5,
                color: palette.accent,
              ),
            ),
          ],
        ),
      ],
    );

    if (palette.headerFill != null) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: palette.headerFill,
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: content,
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: palette.accent, width: 2),
        ),
      ),
      child: content,
    );
  }

  static pw.Widget _sectionTitle(String title, _PdfPalette palette) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        font: _fontBold,
        fontSize: 12.5,
        fontWeight: pw.FontWeight.bold,
        color: palette.ink,
      ),
    );
  }

  static TherapistPdfKpi _kpi(_PdfPalette palette) => TherapistPdfKpi(
        accent: palette.accent,
        ink: palette.ink,
        muted: palette.muted,
        cardFill: palette.cardFill,
        cardBorder: palette.cardBorder,
        kpiRadius: palette.kpiRadius,
        fontRegular: _fontRegular!,
        fontBold: _fontBold!,
      );

  static pw.Widget _kpiTile({
    required _PdfPalette palette,
    required String title,
    required String value,
    required String subtitle,
    PdfColor? fill,
  }) {
    return _kpi(palette).tile(
      title: title,
      value: value,
      subtitle: subtitle,
      fill: fill,
    );
  }

  static pw.Widget _statBox(_PdfPalette palette, String title, String value) {
    return _kpi(palette).statBox(title, value);
  }

  static List<pw.Widget> _chunkRows(
    List<pw.Widget> items, {
    required int perRow,
  }) {
    if (items.isEmpty) return const [];
    final rows = <pw.Widget>[];
    for (var i = 0; i < items.length; i += perRow) {
      final chunk = items.sublist(
        i,
        i + perRow > items.length ? items.length : i + perRow,
      );
      while (chunk.length < perRow) {
        chunk.add(pw.Expanded(child: pw.SizedBox()));
      }
      rows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            children: [
              for (var j = 0; j < chunk.length; j++) ...[
                if (j > 0) pw.SizedBox(width: 8),
                chunk[j],
              ],
            ],
          ),
        ),
      );
    }
    return rows;
  }

  static DateFormat _dateFormat(String pattern, String locale) {
    try {
      return DateFormat(pattern, locale);
    } catch (_) {
      return DateFormat(pattern);
    }
  }
}
