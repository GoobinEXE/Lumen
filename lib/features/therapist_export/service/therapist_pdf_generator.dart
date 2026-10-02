import 'dart:typed_data';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:noa/core/localization/correlation_copy.dart';
import 'package:noa/core/localization/l10n_labels.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/routine_mood/domain/routine_export.dart';
import 'package:noa/features/sleep_analytics/domain/correlation_engine.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_labels.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';
import 'package:noa/features/therapist_export/service/routine_export_copy.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class TherapistPdfGenerator {
  static Future<Uint8List> generateReport({
    required String patientName,
    required List<SleepRecord> sleepRecords,
    required List<MoodEntry> moodEntries,
    required AppLocalizations l10n,
    List<DailyRecoverySnapshot> recoverySnapshots = const [],
    int periodDays = 7,
    int appleHealthSomCount = 0,
    List<RoutineExportLine> routineLines = const [],
  }) async {
    final pdf = pw.Document();
    final locale = l10n.localeName;
    final languageCode = locale.split('_').first;
    try {
      await initializeDateFormatting(locale);
    } catch (_) {}
    final dateFormat = _dateFormat('dd/MM/yyyy', locale);
    final timeFormat = _dateFormat('HH:mm', locale);

    final totalSleepHoursList = sleepRecords.map((s) => s.totalHours).toList();
    final avgSleepHours = totalSleepHoursList.isNotEmpty
        ? totalSleepHoursList.reduce((a, b) => a + b) / totalSleepHoursList.length
        : 0.0;

    final remHoursList = sleepRecords.map((s) => s.remHours).toList();
    final avgRemHours = remHoursList.isNotEmpty
        ? remHoursList.reduce((a, b) => a + b) / remHoursList.length
        : 0.0;

    final deficitNightsCount = sleepRecords.where((s) => s.hasSleepDeficit).length;

    final paralyzedCount =
        moodEntries.where((m) => m.focus == FocusState.paralyzed).length;
    final hyperfocusCount =
        moodEntries.where((m) => m.focus == FocusState.hyperfocus).length;
    final scatteredCount =
        moodEntries.where((m) => m.focus == FocusState.scattered).length;
    final focusedCount =
        moodEntries.where((m) => m.focus == FocusState.focused).length;
    final sensoryCount = moodEntries.where((m) => m.sensoryOverload).length;
    final medCount = moodEntries.where((m) => m.tookMedication).length;

    final labelCounts = <String, int>{};
    for (final m in moodEntries) {
      for (final id in m.emotionLabels) {
        labelCounts[id] = (labelCounts[id] ?? 0) + 1;
      }
    }
    final topLabels = labelCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final avgHrv = _avg(recoverySnapshots.map((r) => r.hrvMs));
    final avgResting = _avg(recoverySnapshots.map((r) => r.restingHeartRate));
    final avgSteps = _avg(recoverySnapshots.map((r) => r.steps?.toDouble()));
    final avgExercise = _avg(recoverySnapshots.map((r) => r.exerciseMinutes));
    final avgDaylight =
        _avg(recoverySnapshots.map((r) => r.timeInDaylightMinutes));
    final avgNoise =
        _avg(recoverySnapshots.map((r) => r.avgEnvironmentalDb));
    final somFromApple = appleHealthSomCount +
        moodEntries
            .where((m) =>
                m.emotionSource == StateOfMindSource.appleHealth &&
                m.emotionLabels.isNotEmpty)
            .length;

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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 16),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.teal700, width: 2),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        l10n.pdfHeaderTitle,
                        style: pw.TextStyle(
                          color: PdfColors.teal800,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        l10n.pdfHeaderSubtitle,
                        style: pw.TextStyle(
                          color: PdfColors.blueGrey900,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        l10n.pdfPatientPeriod(patientName, periodDays),
                        style: const pw.TextStyle(
                          color: PdfColors.blueGrey700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        l10n.pdfIssuedAt(dateFormat.format(DateTime.now())),
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        l10n.pdfSourceLine,
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.teal700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Text(
              l10n.pdfSection1Sleep,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal900,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _buildMetricCard(
                  title: l10n.pdfAvgSleepTitle,
                  value: l10n.pdfAvgSleepValue(avgSleepHours.toStringAsFixed(1)),
                  subtitle: l10n.pdfDeficitNights(deficitNightsCount, sleepRecords.length),
                  color: avgSleepHours < 6.5 ? PdfColors.red100 : PdfColors.teal50,
                  textColor:
                      avgSleepHours < 6.5 ? PdfColors.red900 : PdfColors.teal900,
                ),
                pw.SizedBox(width: 10),
                _buildMetricCard(
                  title: l10n.pdfAvgRemTitle,
                  value: '${avgRemHours.toStringAsFixed(1)}h',
                  subtitle: avgRemHours < 1.25
                      ? l10n.pdfRemDeficitAlert
                      : l10n.pdfRemWithinExpected,
                  color: avgRemHours < 1.25 ? PdfColors.orange100 : PdfColors.teal50,
                  textColor:
                      avgRemHours < 1.25 ? PdfColors.orange900 : PdfColors.teal900,
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            if (tableData.isNotEmpty)
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
              ),
            if (recoverySnapshots.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              pw.Text(
                l10n.pdfSection1bRecovery,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal900,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  if (avgHrv != null)
                    _buildMetricCard(
                      title: l10n.pdfHrvAvgTitle,
                      value: '${avgHrv.toStringAsFixed(0)} ms',
                      subtitle: l10n.pdfHrvSubtitle,
                      color: PdfColors.teal50,
                      textColor: PdfColors.teal900,
                    ),
                  if (avgResting != null) ...[
                    pw.SizedBox(width: 10),
                    _buildMetricCard(
                      title: l10n.pdfRestingHrTitle,
                      value: '${avgResting.toStringAsFixed(0)} bpm',
                      subtitle: l10n.pdfPeriodAverage,
                      color: PdfColors.teal50,
                      textColor: PdfColors.teal900,
                    ),
                  ],
                  if (avgSteps != null) ...[
                    pw.SizedBox(width: 10),
                    _buildMetricCard(
                      title: l10n.pdfStepsPerDayTitle,
                      value: avgSteps.toStringAsFixed(0),
                      subtitle: l10n.pdfPeriodAverage,
                      color: PdfColors.teal50,
                      textColor: PdfColors.teal900,
                    ),
                  ],
                  if (avgExercise != null) ...[
                    pw.SizedBox(width: 10),
                    _buildMetricCard(
                      title: l10n.pdfExerciseTitle,
                      value: '${avgExercise.toStringAsFixed(0)} min',
                      subtitle: l10n.pdfDailyAverage,
                      color: PdfColors.teal50,
                      textColor: PdfColors.teal900,
                    ),
                  ],
                  if (avgDaylight != null) ...[
                    pw.SizedBox(width: 10),
                    _buildMetricCard(
                      title: l10n.pdfDaylightTitle,
                      value: '${avgDaylight.toStringAsFixed(0)} min',
                      subtitle: l10n.pdfDailyAverage,
                      color: PdfColors.amber50,
                      textColor: PdfColors.amber900,
                    ),
                  ],
                  if (avgNoise != null) ...[
                    pw.SizedBox(width: 10),
                    _buildMetricCard(
                      title: l10n.pdfNoiseTitle,
                      value: '${avgNoise.toStringAsFixed(0)} dB',
                      subtitle: l10n.pdfPeriodAverage,
                      color: PdfColors.blueGrey50,
                      textColor: PdfColors.blueGrey900,
                    ),
                  ],
                ],
              ),
            ],
            pw.SizedBox(height: 20),
            pw.Text(
              l10n.pdfSection2Executive,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal900,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _buildStatBox(
                  l10n.pdfStatParalyzed,
                  l10n.pdfReportsLabel(paralyzedCount),
                  PdfColors.red700,
                ),
                pw.SizedBox(width: 10),
                _buildStatBox(
                  l10n.pdfStatScattered,
                  l10n.pdfReportsLabel(scatteredCount),
                  PdfColors.orange700,
                ),
                pw.SizedBox(width: 10),
                _buildStatBox(
                  l10n.pdfStatFocused,
                  l10n.pdfReportsLabel(focusedCount),
                  PdfColors.teal700,
                ),
                pw.SizedBox(width: 10),
                _buildStatBox(
                  l10n.pdfStatHyperfocus,
                  l10n.pdfReportsLabel(hyperfocusCount),
                  PdfColors.purple700,
                ),
                pw.SizedBox(width: 10),
                _buildStatBox(
                  l10n.pdfStatSensory,
                  l10n.pdfTimesLabel(sensoryCount),
                  PdfColors.blueGrey800,
                ),
              ],
            ),
            if (topLabels.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Text(
                l10n.pdfTopEmotionWords,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
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
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
              ),
              if (somFromApple > 0) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  l10n.pdfSomFromAppleHealth(somFromApple),
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColors.blueGrey700,
                  ),
                ),
              ],
              pw.SizedBox(height: 4),
              pw.Text(
                l10n.pdfMedicationTaken(medCount, moodEntries.length),
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
              ),
            ],
            pw.SizedBox(height: 18),
            pw.Text(
              l10n.pdfSection3Correlations,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal900,
              ),
            ),
            pw.SizedBox(height: 6),
            ...insights.map((insight) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      insight.title,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10.5,
                        color: PdfColors.teal800,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      insight.description,
                      style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.black),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      l10n.pdfClinicalSuggestion(insight.actionableAdvice),
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        color: PdfColors.blueGrey700,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 14),
            pw.Text(
              l10n.pdfSection4Triggers,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal900,
              ),
            ),
            pw.SizedBox(height: 6),
            ...moodEntries
                .where((m) => m.note != null && m.note!.isNotEmpty)
                .take(5)
                .map((entry) {
              final labels = entry.emotionLabels
                  .map((id) => StateOfMindLabels.label(id, languageCode))
                  .join(', ');
              final labelsSuffix = labels.isNotEmpty ? ' | $labels' : '';
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.teal600, width: 3),
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
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '"${entry.note}"',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                    ),
                  ],
                ),
              );
            }),
            if (routineLines.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              pw.Text(
                l10n.exportRoutineHeading,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal900,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                l10n.exportRoutineCount(routineLines.length),
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
              ),
              pw.SizedBox(height: 8),
              ...routineLines.map((line) {
                final rows = describeRoutineExportLine(
                  l10n: l10n,
                  line: line,
                  dateFormat: dateFormat,
                  timeFormat: timeFormat,
                );
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      for (final row in rows)
                        pw.Text(
                          row,
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.black,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Text(
                l10n.pdfFooterDisclaimer,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static double? _avg(Iterable<double?> values) {
    final nums = values.whereType<double>().toList();
    if (nums.isEmpty) return null;
    return nums.reduce((a, b) => a + b) / nums.length;
  }

  static DateFormat _dateFormat(String pattern, String locale) {
    try {
      return DateFormat(pattern, locale);
    } catch (_) {
      return DateFormat(pattern);
    }
  }

  static pw.Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required PdfColor color,
    required PdfColor textColor,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: textColor,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: textColor,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              subtitle,
              style: pw.TextStyle(fontSize: 7.5, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildStatBox(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 0.8),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              title,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
            ),
          ],
        ),
      ),
    );
  }
}
