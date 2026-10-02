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

    if (sleepRecords.isNotEmpty && moodEntries.isNotEmpty) {
      int remDeficitAndParalyzedCount = 0;
      int totalParalyzedCount = 0;

      for (final mood in moodEntries) {
        if (mood.focus == FocusState.paralyzed ||
            mood.energy == EnergyLevel.drained) {
          totalParalyzedCount++;
          final matchingSleep = sleepRecords.where((s) {
            final diff = mood.timestamp.difference(s.date).inHours;
            return diff >= 0 && diff <= 30;
          }).firstOrNull;

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

      final goodDays = moodEntries
          .where((m) => m.focus == FocusState.focused || m.valence >= 4)
          .toList();
      if (goodDays.isNotEmpty) {
        insights.add(
          CorrelationInsight(
            title: copy.insightMentalFlowTitle,
            description: copy.insightMentalFlowDesc,
            actionableAdvice: copy.insightMentalFlowAdvice,
            correlationPercentage: 85.0,
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

    // HRV baixa × travamento / esgotamento / overwhelmed / stressed
    if (recoverySnapshots.isNotEmpty && moodEntries.isNotEmpty) {
      int lowHrvHardDays = 0;
      int hardDays = 0;
      for (final mood in moodEntries) {
        final hard = mood.focus == FocusState.paralyzed ||
            mood.energy == EnergyLevel.drained ||
            mood.emotionLabels.contains('overwhelmed') ||
            mood.emotionLabels.contains('stressed');
        if (!hard) continue;
        hardDays++;
        final day = DateTime(
          mood.timestamp.year,
          mood.timestamp.month,
          mood.timestamp.day,
        );
        final snap = recoverySnapshots.where((r) {
          return r.date.year == day.year &&
              r.date.month == day.month &&
              r.date.day == day.day;
        }).firstOrNull;
        if (snap != null && snap.hasLowHrv) {
          lowHrvHardDays++;
        }
      }

      if (hardDays > 0 && lowHrvHardDays > 0) {
        final pct = (lowHrvHardDays / hardDays) * 100;
        final percent = pct.toStringAsFixed(0);
        insights.add(
          CorrelationInsight(
            title: copy.insightHrvTitle,
            description: copy.insightHrvDesc(percent),
            actionableAdvice: copy.insightHrvAdvice,
            correlationPercentage: pct,
            iconKey: 'brain',
          ),
        );
      }

      int lowStepsHard = 0;
      int movementHardDays = 0;
      for (final mood in moodEntries) {
        final hard = mood.focus == FocusState.paralyzed ||
            mood.focus == FocusState.scattered ||
            mood.energy == EnergyLevel.drained;
        if (!hard) continue;
        movementHardDays++;
        final day = DateTime(
          mood.timestamp.year,
          mood.timestamp.month,
          mood.timestamp.day,
        );
        final snap = recoverySnapshots.where((r) {
          return r.date.year == day.year &&
              r.date.month == day.month &&
              r.date.day == day.day;
        }).firstOrNull;
        if (snap != null && snap.hasLowSteps) {
          lowStepsHard++;
        }
      }

      if (movementHardDays > 0 && lowStepsHard > 0) {
        final pct = (lowStepsHard / movementHardDays) * 100;
        final percent = pct.toStringAsFixed(0);
        insights.add(
          CorrelationInsight(
            title: copy.insightMovementTitle,
            description: copy.insightMovementDesc(percent),
            actionableAdvice: copy.insightMovementAdvice,
            correlationPercentage: pct,
            iconKey: 'sparkle',
          ),
        );
      }

      int lowLightHard = 0;
      int lightHardDays = 0;
      int noiseSensory = 0;
      int sensoryDaysWithEnv = 0;

      for (final mood in moodEntries) {
        final day = DateTime(
          mood.timestamp.year,
          mood.timestamp.month,
          mood.timestamp.day,
        );
        final snap = recoverySnapshots.where((r) {
          return r.date.year == day.year &&
              r.date.month == day.month &&
              r.date.day == day.day;
        }).firstOrNull;

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

      if (lightHardDays > 0 && lowLightHard > 0) {
        final pct = (lowLightHard / lightHardDays) * 100;
        final percent = pct.toStringAsFixed(0);
        insights.add(
          CorrelationInsight(
            title: copy.insightDaylightTitle,
            description: copy.insightDaylightDesc(percent),
            actionableAdvice: copy.insightDaylightAdvice,
            correlationPercentage: pct,
            iconKey: 'sparkle',
          ),
        );
      }

      if (sensoryDaysWithEnv > 0 && noiseSensory > 0) {
        final pct = (noiseSensory / sensoryDaysWithEnv) * 100;
        final percent = pct.toStringAsFixed(0);
        insights.add(
          CorrelationInsight(
            title: copy.insightNoiseTitle,
            description: copy.insightNoiseDesc(percent),
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
}
