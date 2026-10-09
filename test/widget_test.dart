import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/core/localization/correlation_copy.dart';
import 'package:noa/core/localization/locale_provider.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:noa/features/medications/presentation/providers/medication_providers.dart';
import 'package:noa/features/routine_mood/data/micro_habits_prefs.dart';
import 'package:noa/features/routine_mood/domain/daily_routine_state.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/sleep_analytics/domain/correlation_engine.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_associations.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_labels.dart';
import 'package:noa/features/therapist_export/service/therapist_pdf_generator.dart';
import 'package:noa/features/therapist_export/service/whatsapp_text_formatter.dart';
import 'package:noa/integrations/health/models/daily_environment_snapshot.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';
import 'package:noa/integrations/healthkit_bridge/healthkit_bridge.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TDAH NeuroSync Logic Tests', () {
    test('SleepRecord detects sleep and REM deficit accurately', () {
      final deficitNight = SleepRecord(
        date: DateTime.now(),
        bedtime: DateTime.now().subtract(const Duration(hours: 6)),
        wakeTime: DateTime.now(),
        totalSleep: const Duration(hours: 5, minutes: 15),
        remSleep: const Duration(minutes: 40),
        deepSleep: const Duration(minutes: 35),
      );

      expect(deficitNight.hasSleepDeficit, isTrue);
      expect(deficitNight.hasRemDeficit, isTrue);
      expect(deficitNight.totalHours, closeTo(5.25, 0.01));
    });

    test('CorrelationEngine generates insights when REM deficit aligns with paralysis', () {
      final now = DateTime.now();
      final sleepRecords = [
        SleepRecord(
          date: now.subtract(const Duration(days: 1)),
          bedtime: now.subtract(const Duration(days: 1, hours: 7)),
          wakeTime: now.subtract(const Duration(days: 1)),
          totalSleep: const Duration(hours: 5),
          remSleep: const Duration(minutes: 45),
        ),
      ];

      final moodEntries = [
        MoodEntry(
          id: 'test-1',
          timestamp: now.subtract(const Duration(hours: 12)),
          valence: 2,
          energy: EnergyLevel.drained,
          focus: FocusState.paralyzed,
        ),
      ];

      final insights = CorrelationEngine.analyze(
        sleepRecords: sleepRecords,
        moodEntries: moodEntries,
        copy: L10nCorrelationCopy(lookupAppLocalizations(const Locale('pt'))),
      );

      expect(insights, isNotEmpty);
      expect(insights.first.title, contains('Sono REM & Paralisia'));
    });

    test('CorrelationEngine links low HRV with overwhelmed labels', () {
      final day = DateTime(2026, 9, 20);
      final recovery = [
        DailyRecoverySnapshot(
          date: day,
          hrvMs: 28,
          restingHeartRate: 72,
          steps: 2200,
        ),
      ];
      final moods = [
        MoodEntry(
          id: 'hrv-1',
          timestamp: day.add(const Duration(hours: 14)),
          valence: 2,
          energy: EnergyLevel.drained,
          focus: FocusState.paralyzed,
          emotionLabels: {'overwhelmed', 'stressed'},
        ),
      ];

      final insights = CorrelationEngine.analyze(
        sleepRecords: const [],
        moodEntries: moods,
        recoverySnapshots: recovery,
        copy: L10nCorrelationCopy(lookupAppLocalizations(const Locale('pt'))),
      );

      expect(
        insights.any((i) => i.title.contains('HRV')),
        isTrue,
      );
    });

    test('StateOfMindEntry and labels serialize correctly', () {
      final entry = StateOfMindEntry(
        kind: StateOfMindKind.dailyMood,
        valence: 0.4,
        labels: {'calm', 'hopeful'},
        associations: {'work', 'selfCare'},
        timestamp: DateTime(2026, 9, 24, 9),
      );
      final restored = StateOfMindEntry.fromMap(entry.toMap());
      expect(restored.valence, closeTo(0.4, 0.001));
      expect(restored.labels, containsAll(['calm', 'hopeful']));
      expect(restored.associations, contains('work'));
      expect(StateOfMindLabels.ids.length, equals(38));
      expect(StateOfMindLabels.label('calm', 'pt'), equals('Calmo(a)'));
    });

    test('StateOfMind label and association ids match Apple Health contract', () {
      // Conjunto oficial completo HKStateOfMind.Label (iOS 18) — 38 casos.
      const appleOfficialLabels = [
        'amazed',
        'amused',
        'angry',
        'annoyed',
        'anxious',
        'ashamed',
        'brave',
        'calm',
        'confident',
        'content',
        'disappointed',
        'discouraged',
        'disgusted',
        'drained',
        'embarrassed',
        'excited',
        'frustrated',
        'grateful',
        'guilty',
        'happy',
        'hopeful',
        'hopeless',
        'indifferent',
        'irritated',
        'jealous',
        'joyful',
        'lonely',
        'overwhelmed',
        'passionate',
        'peaceful',
        'proud',
        'relieved',
        'sad',
        'satisfied',
        'scared',
        'stressed',
        'surprised',
        'worried',
      ];
      expect(StateOfMindLabels.ids.length, equals(38));
      expect(StateOfMindLabels.ids.toSet(), equals(appleOfficialLabels.toSet()));
      expect(StateOfMindLabels.sortedIds('pt').length, equals(38));
      expect(StateOfMindAssociations.ids.length, equals(18));
      expect(StateOfMindAssociations.ids, containsAll(['work', 'selfCare', 'family']));
      expect(StateOfMindKind.values.map((k) => k.name).toSet(),
          containsAll(['dailyMood', 'momentary']));
    });

    test('StateOfMindEntry mergePreferNewest keeps the latest source', () {
      final older = StateOfMindEntry(
        valence: -0.2,
        labels: {'anxious'},
        timestamp: DateTime(2026, 9, 24, 8),
        source: StateOfMindSource.lumen,
      );
      final newer = StateOfMindEntry(
        valence: 0.5,
        labels: {'calm'},
        timestamp: DateTime(2026, 9, 24, 12),
        source: StateOfMindSource.appleHealth,
      );
      final merged = StateOfMindEntry.mergePreferNewest(older, newer);
      expect(merged?.source, StateOfMindSource.appleHealth);
      expect(merged?.labels, contains('calm'));
      expect(
        StateOfMindEntry.mergePreferNewest(newer, older)?.source,
        StateOfMindSource.appleHealth,
      );
    });

    test('DailyRecoverySnapshot tracks daylight and noise flags', () {
      final snap = DailyRecoverySnapshot(
        date: DateTime(2026, 9, 24),
        timeInDaylightMinutes: 10,
        avgEnvironmentalDb: 75,
      );
      expect(snap.hasLowDaylight, isTrue);
      expect(snap.hasHighNoise, isTrue);
      final restored = DailyRecoverySnapshot.fromMap(snap.toMap());
      expect(restored.timeInDaylightMinutes, 10);
      expect(restored.avgEnvironmentalDb, 75);
    });

    test('Medication serializes appleConceptId, source and log source', () {
      const med = Medication(
        id: 'm-hk',
        name: 'Venvanse',
        dosage: '30mg',
        scheduledTimes: ['08:00'],
        appleConceptId: 'concept-123',
        rxNormCode: 'rx-999',
        source: MedicationSource.appleHealth,
      );
      expect(med.isLinkedToAppleHealth, isTrue);
      expect(med.healthKitMedicationId, 'concept-123');
      final restored = Medication.fromMap(med.toMap());
      expect(restored.appleConceptId, 'concept-123');
      expect(restored.rxNormCode, 'rx-999');
      expect(restored.source, MedicationSource.appleHealth);

      // Legacy key still loads.
      final fromLegacy = Medication.fromMap({
        ...med.toMap(),
        'appleConceptId': null,
        'healthKitMedicationId': 'legacy-id',
        'source': null,
      });
      expect(fromLegacy.appleConceptId, 'legacy-id');

      final log = MedicationLog(
        id: 'l-1',
        medicationId: med.id,
        medicationName: med.name,
        scheduledTime: DateTime(2026, 9, 24, 8),
        takenAt: DateTime(2026, 9, 24, 8, 5),
        source: MedicationLogSource.appleHealth,
      );
      expect(MedicationLog.fromMap(log.toMap()).source,
          MedicationLogSource.appleHealth);
    });

    test('DailyEnvironmentSnapshot serializes daylight and audio', () {
      final snap = DailyEnvironmentSnapshot(
        date: DateTime(2026, 9, 24),
        daylightMinutes: 15,
        envAudioDb: 72,
        headphoneAudioDb: 85,
      );
      expect(snap.hasLowDaylight, isTrue);
      expect(snap.hasHighEnvNoise, isTrue);
      expect(snap.hasHighHeadphoneNoise, isTrue);
      final restored = DailyEnvironmentSnapshot.fromMap(snap.toMap());
      expect(restored.headphoneAudioDb, 85);
    });

    test('mergeDoseEventsIntoLogs dedupes Apple Health doses', () {
      final existing = [
        MedicationLog(
          id: 'local-1',
          medicationId: 'm1',
          medicationName: 'Med',
          scheduledTime: DateTime(2026, 9, 24, 8),
          takenAt: DateTime(2026, 9, 24, 8, 2),
        ),
      ];
      final when = DateTime(2026, 9, 24, 12);
      final events = [
        HealthKitDoseEvent(
          appleConceptId: 'c1',
          status: 'taken',
          loggedAt: when,
        ),
        HealthKitDoseEvent(
          appleConceptId: 'c1',
          status: 'taken',
          loggedAt: when,
        ),
      ];
      final merged = mergeDoseEventsIntoLogs(
        medicationId: 'm1',
        medicationName: 'Med',
        existing: existing,
        events: events,
      );
      expect(merged.length, 2);
      expect(
        merged.where((l) => l.source == MedicationLogSource.appleHealth).length,
        1,
      );
    });

    test('HealthKitBridge MethodChannel stubs return empty off-iOS', () async {
      // Em testes (não-iOS), a ponte é no-op e não deve lançar.
      expect(HealthKitBridge.isSupported, isFalse);
      expect(await HealthKitBridge.requestAuthorization(), isFalse);
      expect(
        await HealthKitBridge.writeStateOfMind(
          StateOfMindEntry(timestamp: DateTime(2026, 9, 24), valence: 0.2),
        ),
        isFalse,
      );
      expect(
        await HealthKitBridge.readStateOfMind(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 24),
        ),
        isEmpty,
      );
      expect(
        await HealthKitBridge.readTimeInDaylight(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 24),
        ),
        isEmpty,
      );
      expect(
        await HealthKitBridge.readHeadphoneAudio(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 24),
        ),
        isEmpty,
      );
      expect(await HealthKitBridge.readMedications(), isEmpty);
      expect(await HealthKitBridge.isMedicationsApiAvailable(), isFalse);
    });

    test('Micro habits template persists defaults and custom list', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final l10n = lookupAppLocalizations(const Locale('pt'));
      expect(getMicroHabitsTemplate(prefs, l10n), equals(defaultMicroHabits(l10n)));

      await setMicroHabitsTemplate(prefs, ['Caminhar', 'Hidratação']);
      expect(getMicroHabitsTemplate(prefs, l10n), equals(['Caminhar', 'Hidratação']));
    });

    test('TherapistPdfGenerator generates non-empty PDF bytes', () async {
      final now = DateTime.now();
      final sleepRecords = [
        SleepRecord(
          date: now,
          bedtime: now.subtract(const Duration(hours: 8)),
          wakeTime: now,
          totalSleep: const Duration(hours: 7, minutes: 30),
          remSleep: const Duration(hours: 1, minutes: 40),
          deepSleep: const Duration(hours: 1, minutes: 20),
          lightSleep: const Duration(hours: 4, minutes: 30),
        ),
      ];

      final moodEntries = [
        MoodEntry(
          id: 'test-1',
          timestamp: now,
          valence: 4,
          energy: EnergyLevel.balanced,
          focus: FocusState.focused,
          note: 'Dia focado e sem sobrecargas.',
          emotionLabels: {'content', 'calm'},
        ),
      ];

      final pdfBytes = await TherapistPdfGenerator.generateReport(
        patientName: 'Marcelo P.',
        sleepRecords: sleepRecords,
        moodEntries: moodEntries,
        l10n: lookupAppLocalizations(const Locale('pt')),
        recoverySnapshots: [
          DailyRecoverySnapshot(
            date: now,
            hrvMs: 55,
            restingHeartRate: 62,
            steps: 8000,
            exerciseMinutes: 25,
          ),
        ],
        periodDays: 7,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('WhatsappTextFormatter formats structured WhatsApp message', () {
      final now = DateTime.now();
      final sleepRecords = [
        SleepRecord(
          date: now,
          bedtime: now.subtract(const Duration(hours: 7)),
          wakeTime: now,
          totalSleep: const Duration(hours: 6, minutes: 30),
          remSleep: const Duration(minutes: 50),
        ),
      ];

      final moodEntries = [
        MoodEntry(
          id: 'w-1',
          timestamp: now,
          valence: 3,
          energy: EnergyLevel.low,
          focus: FocusState.paralyzed,
          note: 'Dificuldade de transição de tarefas.',
          emotionLabels: {'frustrated'},
        ),
      ];

      final message = WhatsappTextFormatter.formatSummary(
        patientName: 'Marcelo P.',
        sleepRecords: sleepRecords,
        moodEntries: moodEntries,
        l10n: lookupAppLocalizations(const Locale('pt')),
        periodDays: 7,
      );

      expect(message, contains('*RESUMO CLINICO SEMANAL - Marcelo P.*'));
      expect(message, contains('*BIOMETRIA DE SONO (Apple Health):*'));
      expect(message, contains('Paralisia/Travado:'));
      expect(message, contains('Dificuldade de transição'));
      expect(message, contains('Frustrado'));
    });

    test('DailyRoutineState serializes stateOfMind and microHabits', () {
      final today = DateTime(2026, 9, 23);
      final routine = DailyRoutineState(
        date: today,
        mainFocusAnchor: 'Escrever projeto Flutter',
        stateOfMind: StateOfMindEntry(
          kind: StateOfMindKind.momentary,
          valence: -0.2,
          labels: {'anxious'},
          associations: {'tasks'},
          timestamp: today,
        ),
        microHabits: const ['Caminhar', 'Água'],
        waterGlasses: 4,
        tookPrescribedMedication: true,
        therapistNotes: 'Conversar sobre manejo de estímulos',
      );

      final map = routine.toMap();
      final restored = DailyRoutineState.fromMap(map);

      expect(restored.mainFocusAnchor, equals('Escrever projeto Flutter'));
      expect(restored.waterGlasses, equals(4));
      expect(restored.tookPrescribedMedication, isTrue);
      expect(restored.therapistNotes, equals('Conversar sobre manejo de estímulos'));
      expect(restored.stateOfMind?.labels, contains('anxious'));
      expect(restored.microHabits, equals(['Caminhar', 'Água']));
      expect(map.containsKey('morningFeeling'), isFalse);
    });

    test('Legacy morningFeeling JSON loads without crashing', () {
      final restored = DailyRoutineState.fromMap({
        'date': '2026-09-20T00:00:00.000',
        'mainFocusAnchor': 'Legado',
        'morningFeeling': 'Calmo & Centrado',
        'microHabits': ['A', 'B'],
        'completedHabits': <String>[],
        'waterGlasses': 1,
        'tookPrescribedMedication': false,
      });
      expect(restored.mainFocusAnchor, 'Legado');
      expect(restored.stateOfMind, isNull);
      expect(restored.microHabits, equals(['A', 'B']));
    });

    test('Medication identifies low stock warning for controlled prescriptions', () {
      const medNormal = Medication(
        id: 'm-1',
        name: 'Venvanse',
        dosage: '30mg',
        scheduledTimes: ['08:00'],
        totalStock: 28,
        remainingStock: 15,
        refillWarningThreshold: 5,
      );
      expect(medNormal.needsRefillWarning, isFalse);

      const medLow = Medication(
        id: 'm-2',
        name: 'Venvanse',
        dosage: '30mg',
        scheduledTimes: ['08:00'],
        totalStock: 28,
        remainingStock: 4,
        refillWarningThreshold: 5,
      );
      expect(medLow.needsRefillWarning, isTrue);
    });

    test('MedicationLog correctly reflects taken and pending states', () {
      final scheduled = DateTime.now();
      final pendingLog = MedicationLog(
        id: 'log-1',
        medicationId: 'm-1',
        medicationName: 'Venvanse 30mg',
        scheduledTime: scheduled,
      );

      expect(pendingLog.isTaken, isFalse);
      expect(pendingLog.isPending, isTrue);

      final takenLog = pendingLog.copyWith(takenAt: DateTime.now());
      expect(takenLog.isTaken, isTrue);
      expect(takenLog.isPending, isFalse);
    });
  });

  group('TDAH Multilingual & System Synchronization Tests', () {
    test('All AppLocalizations locales provide complete key sets', () {
      final locales = [
        const Locale('pt'),
        const Locale('en'),
        const Locale('ja'),
        const Locale('es'),
      ];

      for (final locale in locales) {
        final l10n = lookupAppLocalizations(locale);
        expect(l10n.appTitle.isNotEmpty, isTrue);
        expect(l10n.quickCheckinTitle.isNotEmpty, isTrue);
        expect(l10n.medicationsCardTitle.isNotEmpty, isTrue);
        expect(l10n.focusParalyzed.isNotEmpty, isTrue);
        expect(
          l10n.healthSyncReadBody.contains('HRV') ||
              l10n.healthSyncReadBody.contains('心拍'),
          isTrue,
        );
      }
    });

    test('resolveSupportedLocale maps system language codes', () {
      expect(resolveSupportedLocale(const Locale('ja')).languageCode, 'ja');
      expect(resolveSupportedLocale(const Locale('es')).languageCode, 'es');
      expect(resolveSupportedLocale(const Locale('en')).languageCode, 'en');
      expect(resolveSupportedLocale(const Locale('pt')).languageCode, 'pt');
      expect(resolveSupportedLocale(const Locale('fr')).languageCode, 'pt');
    });
  });
}
