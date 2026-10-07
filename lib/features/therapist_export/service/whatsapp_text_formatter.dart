import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:noa/core/localization/correlation_copy.dart';
import 'package:noa/core/localization/l10n_labels.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/sleep_analytics/domain/correlation_engine.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_labels.dart';
import 'package:noa/features/routine_mood/domain/routine_export.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';
import 'package:noa/features/therapist_export/domain/export_period.dart';
import 'package:noa/features/therapist_export/service/routine_export_copy.dart';
import 'package:noa/l10n/app_localizations.dart';

class WhatsappTextFormatter {
  /// Gera a mensagem estruturada pronta para envio no WhatsApp
  static String formatSummary({
    required String patientName,
    required List<SleepRecord> sleepRecords,
    required List<MoodEntry> moodEntries,
    required AppLocalizations l10n,
    List<DailyRecoverySnapshot> recoverySnapshots = const [],
    int periodDays = 7,
    int appleHealthSomCount = 0,
    List<RoutineExportLine> routineLines = const [],
  }) {
    final locale = l10n.localeName;
    final languageCode = locale.split('_').first;
    final dateFormat = _dateFormat('dd/MM', locale);
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: periodDays));
    final sleepInPeriod = [
      for (final record in sleepRecords)
        if (isWithinExportPeriod(
          instant: record.date,
          now: endDate,
          periodDays: periodDays,
        ))
          record,
    ];
    final moodInPeriod = [
      for (final entry in moodEntries)
        if (isWithinExportPeriod(
          instant: entry.timestamp,
          now: endDate,
          periodDays: periodDays,
        ))
          entry,
    ];
    final recoveryInPeriod = [
      for (final snapshot in recoverySnapshots)
        if (isWithinExportPeriod(
          instant: snapshot.date,
          now: endDate,
          periodDays: periodDays,
        ))
          snapshot,
    ];

    final totalSleepHours = sleepInPeriod.map((s) => s.totalHours).toList();
    final avgSleep = totalSleepHours.isNotEmpty
        ? totalSleepHours.reduce((a, b) => a + b) / totalSleepHours.length
        : 0.0;

    final remHours = sleepInPeriod.map((s) => s.remHours).toList();
    final avgRem = remHours.isNotEmpty
        ? remHours.reduce((a, b) => a + b) / remHours.length
        : 0.0;

    final deficitNights = sleepInPeriod.where((s) => s.hasSleepDeficit).length;

    final paralyzedCount = moodInPeriod.where((m) => m.focus == FocusState.paralyzed).length;
    final hyperfocusCount = moodInPeriod.where((m) => m.focus == FocusState.hyperfocus).length;
    final scatteredCount = moodInPeriod.where((m) => m.focus == FocusState.scattered).length;
    final focusedCount = moodInPeriod.where((m) => m.focus == FocusState.focused).length;
    final sensoryCount = moodInPeriod.where((m) => m.sensoryOverload).length;
    final medCount = moodInPeriod.where((m) => m.tookMedication).length;

    final insights = CorrelationEngine.analyze(
      sleepRecords: sleepInPeriod,
      moodEntries: moodInPeriod,
      recoverySnapshots: recoveryInPeriod,
      copy: L10nCorrelationCopy(l10n),
    );

    final labelCounts = <String, int>{};
    for (final m in moodInPeriod) {
      for (final id in m.emotionLabels) {
        labelCounts[id] = (labelCounts[id] ?? 0) + 1;
      }
    }
    final topLabels = labelCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final avgHrv = _avgNullable(recoveryInPeriod.map((r) => r.hrvMs));
    final avgResting =
        _avgNullable(recoveryInPeriod.map((r) => r.restingHeartRate));
    final avgSteps = _avgNullable(recoveryInPeriod.map((r) => r.steps?.toDouble()));
    final avgExercise =
        _avgNullable(recoveryInPeriod.map((r) => r.exerciseMinutes?.toDouble()));
    final avgDaylight =
        _avgNullable(recoveryInPeriod.map((r) => r.timeInDaylightMinutes));
    final avgNoise =
        _avgNullable(recoveryInPeriod.map((r) => r.avgEnvironmentalDb));
    final somFromApple = appleHealthSomCount +
        moodInPeriod
            .where((m) =>
                m.emotionSource.name == 'appleHealth' &&
                m.emotionLabels.isNotEmpty)
            .length;

    final buffer = StringBuffer();

    buffer.writeln(l10n.waWeeklyTitle(patientName));
    buffer.writeln(
      l10n.waPeriod(dateFormat.format(startDate), dateFormat.format(endDate)),
    );
    buffer.writeln(l10n.waGeneratedBy);
    buffer.writeln();

    buffer.writeln(l10n.waSectionSleep);
    buffer.writeln(l10n.waAvgSleep(avgSleep.toStringAsFixed(1)));
    buffer.writeln(l10n.waDeficitNights(deficitNights, sleepInPeriod.length));
    buffer.writeln(
      avgRem < 1.25
          ? l10n.waAvgRemAlert(avgRem.toStringAsFixed(1))
          : l10n.waAvgRemOk(avgRem.toStringAsFixed(1)),
    );
    buffer.writeln();

    if (recoveryInPeriod.isNotEmpty) {
      buffer.writeln(l10n.waSectionRecovery);
      if (avgHrv != null) {
        buffer.writeln(l10n.waHrvAvg(avgHrv.toStringAsFixed(0)));
      }
      if (avgResting != null) {
        buffer.writeln(l10n.waRestingHrAvg(avgResting.toStringAsFixed(0)));
      }
      if (avgSteps != null) {
        buffer.writeln(l10n.waStepsAvg(avgSteps.toStringAsFixed(0)));
      }
      if (avgExercise != null) {
        buffer.writeln(l10n.waExerciseAvg(avgExercise.toStringAsFixed(0)));
      }
      if (avgDaylight != null) {
        buffer.writeln(l10n.waDaylightAvg(avgDaylight.toStringAsFixed(0)));
      }
      if (avgNoise != null) {
        buffer.writeln(l10n.waNoiseAvg(avgNoise.toStringAsFixed(0)));
      }
      buffer.writeln();
    }

    buffer.writeln(l10n.waSectionExecutive);
    buffer.writeln(l10n.waParalysisCount(paralyzedCount));
    buffer.writeln(l10n.waScatteredCount(scatteredCount));
    buffer.writeln(l10n.waFocusedCount(focusedCount));
    buffer.writeln(l10n.waHyperfocusCount(hyperfocusCount));
    if (sensoryCount > 0) {
      buffer.writeln(l10n.waSensoryCount(sensoryCount));
    }
    buffer.writeln(l10n.waMedTaken(medCount, moodInPeriod.length));
    if (topLabels.isNotEmpty) {
      buffer.writeln(l10n.waTopWordsHeader);
      for (final e in topLabels.take(5)) {
        buffer.writeln(
          l10n.waWordCountLine(
            StateOfMindLabels.label(e.key, languageCode),
            e.value,
          ),
        );
      }
    }
    if (somFromApple > 0) {
      buffer.writeln(l10n.waSomFromAppleHealth(somFromApple));
    }
    buffer.writeln();

    if (insights.isNotEmpty) {
      buffer.writeln(l10n.waSectionPatterns);
      for (final insight in insights) {
        buffer.writeln(l10n.waInsightLine(insight.title, insight.description));
      }
      buffer.writeln();
    }

    final notes = moodInPeriod.where((m) => m.note != null && m.note!.isNotEmpty).take(3).toList();
    if (notes.isNotEmpty) {
      buffer.writeln(l10n.waSectionHighlights);
      for (final n in notes) {
        buffer.writeln(
          l10n.waNoteLine(
            n.note!,
            dateFormat.format(n.timestamp),
            n.focus.label(l10n),
          ),
        );
      }
      buffer.writeln();
    }

    if (routineLines.isNotEmpty) {
      buffer.writeln(l10n.exportRoutineHeading);
      buffer.writeln(l10n.exportRoutineCount(routineLines.length));
      for (final line in routineLines) {
        buffer.writeln();
        for (final row in describeRoutineExportLine(
          l10n: l10n,
          line: line,
          dateFormat: dateFormat,
          timeFormat: _dateFormat('HH:mm', locale),
        )) {
          buffer.writeln(row);
        }
      }
      buffer.writeln();
    }

    buffer.writeln(l10n.waFooter);

    return buffer.toString();
  }

  static Future<bool> sendToWhatsApp({
    required String messageText,
    String? phoneNumber,
  }) async {
    final cleanPhone = phoneNumber?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final encoded = Uri.encodeComponent(messageText);

    final nativeUri = cleanPhone.isNotEmpty
        ? Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encoded')
        : Uri.parse('whatsapp://send?text=$encoded');

    try {
      if (await canLaunchUrl(nativeUri)) {
        return await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    final webUri = cleanPhone.isNotEmpty
        ? Uri.parse('https://wa.me/$cleanPhone?text=$encoded')
        : Uri.parse('https://api.whatsapp.com/send?text=$encoded');

    if (await canLaunchUrl(webUri)) {
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }

    return false;
  }

  static double? _avgNullable(Iterable<double?> values) {
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
}
