import 'package:noa/core/time/civil_day.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';

/// Textos já resolvidos. O domínio não lê o catálogo de tradução.
abstract class CorrelationCopy {
  String get insightCollectingTitle;
  String get insightCollectingDescHealth;
  String get insightCollectingAdvice;
  String get insightRemParalysisTitle;
  String insightRemParalysisDesc(String percent);
  String get insightRemParalysisAdvice;
  String get insightMentalFlowTitle;
  String get insightMentalFlowDesc;
  String get insightMentalFlowAdvice;
  String get insightSensoryTitle;
  String insightSensoryDesc(int count);
  String get insightSensoryAdvice;
  String get insightHrvTitle;
  String insightHrvDesc(String percent);
  String get insightHrvAdvice;
  String get insightMovementTitle;
  String insightMovementDesc(String percent);
  String get insightMovementAdvice;
  String get insightDaylightTitle;
  String insightDaylightDesc(String percent);
  String get insightDaylightAdvice;
  String get insightNoiseTitle;
  String insightNoiseDesc(String percent);
  String get insightNoiseAdvice;
  String get insightCollectingDescGeneric;
}

class CorrelationInsight {
  final String title;
  final String description;
  final String actionableAdvice;
  final double correlationPercentage;
  /// Chave de ícone Material (ver [AppIcons.forInsight])
  final String iconKey;

  const CorrelationInsight({
    required this.title,
    required this.description,
    required this.actionableAdvice,
    this.correlationPercentage = 0.0,
    required this.iconKey,
  });
}

class CorrelationEngine {
  /// Analisa a relação entre sono, recuperação e estados de humor/foco.
  static List<CorrelationInsight> analyze({
    required List<SleepRecord> sleepRecords,
    required List<MoodEntry> moodEntries,
    required CorrelationCopy copy,
    List<DailyRecoverySnapshot> recoverySnapshots = const [],
  }) {
    final insights = <CorrelationInsight>[];

    if (sleepRecords.isEmpty && moodEntries.isEmpty) {
      insights.add(
        CorrelationInsight(
          title: copy.insightCollectingTitle,
          description: copy.insightCollectingDescHealth,
          actionableAdvice: copy.insightCollectingAdvice,
          iconKey: 'sprout',
        ),
      );
      return insights;
    }

    final recoveryByDay = <String, DailyRecoverySnapshot>{
      for (final snap in recoverySnapshots) civilDayKey(snap.date): snap,
    };

    if (sleepRecords.isNotEmpty && moodEntries.isNotEmpty) {
      final sleepSorted = List<SleepRecord>.from(sleepRecords)
        ..sort((a, b) => a.date.compareTo(b.date));

      var remDeficitAndParalyzedCount = 0;
      var totalParalyzedCount = 0;

      for (final mood in moodEntries) {
        if (mood.focus == FocusState.paralyzed ||
            mood.energy == EnergyLevel.drained) {
          totalParalyzedCount++;
          final matchingSleep = _sleepWithinHours(sleepSorted, mood.timestamp);
          if (matchingSleep != null && matchingSleep.hasRemDeficit) {
            remDeficitAndParalyzedCount++;
          }
        }
      }

      if (totalParalyzedCount > 0 && remDeficitAndParalyzedCount > 0) {
        final percentage =
            (remDeficitAndParalyzedCount / totalParalyzedCount) * 100;
        final percent = percentage.toStringAsFixed(0);
        insights.add(
          CorrelationInsight(
            title: copy.insightRemParalysisTitle,
            description: copy.insightRemParalysisDesc(percent),
            actionableAdvice: copy.insightRemParalysisAdvice,
            correlationPercentage: percentage,
            iconKey: 'brain',
          ),
        );
      }

      final hasGoodDay = moodEntries.any(
        (m) => m.focus == FocusState.focused || m.valence >= 4,
      );
      if (hasGoodDay) {
        insights.add(
          CorrelationInsight(
            title: copy.insightMentalFlowTitle,
            description: copy.insightMentalFlowDesc,
            actionableAdvice: copy.insightMentalFlowAdvice,
            // Percentual omitido de propósito — não inventamos correlação.
            correlationPercentage: 0.0,
            iconKey: 'sparkle',
          ),
        );
      }
    }

    final sensoryDays = moodEntries.where((m) => m.sensoryOverload).length;
    if (sensoryDays > 0) {
      insights.add(
        CorrelationInsight(
          title: copy.insightSensoryTitle,
          description: copy.insightSensoryDesc(sensoryDays),
          actionableAdvice: copy.insightSensoryAdvice,
          iconKey: 'headphones',
        ),
      );
    }

    if (recoverySnapshots.isNotEmpty && moodEntries.isNotEmpty) {
      var lowHrvHardDays = 0;
      var hardDays = 0;
      var lowStepsHard = 0;
      var movementHardDays = 0;
      var lowLightHard = 0;
      var lightHardDays = 0;
      var noiseSensory = 0;
      var sensoryDaysWithEnv = 0;

      for (final mood in moodEntries) {
        final snap = recoveryByDay[civilDayKey(mood.timestamp)];

        final hardHrv = mood.focus == FocusState.paralyzed ||
            mood.energy == EnergyLevel.drained ||
            mood.emotionLabels.contains('overwhelmed') ||
            mood.emotionLabels.contains('stressed');
        if (hardHrv) {
          hardDays++;
          if (snap != null && snap.hasLowHrv) lowHrvHardDays++;
        }

        final hardMove = mood.focus == FocusState.paralyzed ||
            mood.focus == FocusState.scattered ||
            mood.energy == EnergyLevel.drained;
        if (hardMove) {
          movementHardDays++;
          if (snap != null && snap.hasLowSteps) lowStepsHard++;
        }

        final lowMood = mood.valence <= 2 ||
            mood.emotionLabels.contains('sad') ||
            mood.emotionLabels.contains('drained');
        if (lowMood && snap != null) {
          lightHardDays++;
          if (snap.hasLowDaylight) lowLightHard++;
        }
        if (mood.sensoryOverload && snap != null) {
          sensoryDaysWithEnv++;
          if (snap.hasHighNoise) noiseSensory++;
        }
      }

      if (hardDays > 0 && lowHrvHardDays > 0) {
        final pct = (lowHrvHardDays / hardDays) * 100;
        insights.add(
          CorrelationInsight(
            title: copy.insightHrvTitle,
            description: copy.insightHrvDesc(pct.toStringAsFixed(0)),
            actionableAdvice: copy.insightHrvAdvice,
            correlationPercentage: pct,
            iconKey: 'brain',
          ),
        );
      }

      if (movementHardDays > 0 && lowStepsHard > 0) {
        final pct = (lowStepsHard / movementHardDays) * 100;
        insights.add(
          CorrelationInsight(
            title: copy.insightMovementTitle,
            description: copy.insightMovementDesc(pct.toStringAsFixed(0)),
            actionableAdvice: copy.insightMovementAdvice,
            correlationPercentage: pct,
            iconKey: 'sparkle',
          ),
        );
      }

      if (lightHardDays > 0 && lowLightHard > 0) {
        final pct = (lowLightHard / lightHardDays) * 100;
        insights.add(
          CorrelationInsight(
            title: copy.insightDaylightTitle,
            description: copy.insightDaylightDesc(pct.toStringAsFixed(0)),
            actionableAdvice: copy.insightDaylightAdvice,
            correlationPercentage: pct,
            iconKey: 'sparkle',
          ),
        );
      }

      if (sensoryDaysWithEnv > 0 && noiseSensory > 0) {
        final pct = (noiseSensory / sensoryDaysWithEnv) * 100;
        insights.add(
          CorrelationInsight(
            title: copy.insightNoiseTitle,
            description: copy.insightNoiseDesc(pct.toStringAsFixed(0)),
            actionableAdvice: copy.insightNoiseAdvice,
            correlationPercentage: pct,
            iconKey: 'headphones',
          ),
        );
      }
    }

    if (insights.isEmpty) {
      insights.add(
        CorrelationInsight(
          title: copy.insightCollectingTitle,
          description: copy.insightCollectingDescGeneric,
          actionableAdvice: copy.insightCollectingAdvice,
          iconKey: 'sprout',
        ),
      );
    }

    return insights;
  }

  /// Sono cuja data está entre 0 e 30h antes do humor (lista já ordenada).
  static SleepRecord? _sleepWithinHours(
    List<SleepRecord> sleepSorted,
    DateTime moodTime,
  ) {
    SleepRecord? match;
    for (final sleep in sleepSorted) {
      final diff = moodTime.difference(sleep.date).inHours;
      if (diff < 0) break;
      if (diff <= 30) match = sleep;
    }
    return match;
  }
}
