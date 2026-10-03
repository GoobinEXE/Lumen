import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:noa/features/therapist_export/service/whatsapp_text_formatter.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';
import 'package:noa/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('pt'));
  final day = DateTime(2026, 10, 1);

  SleepRecord night({required Duration total, required Duration rem}) {
    return SleepRecord(
      date: day,
      bedtime: day.subtract(const Duration(hours: 8)),
      wakeTime: day,
      totalSleep: total,
      remSleep: rem,
    );
  }

  String summary({
    List<SleepRecord> sleep = const [],
    List<MoodEntry> moods = const [],
    List<DailyRecoverySnapshot> recovery = const [],
    int appleHealthSomCount = 0,
  }) {
    return WhatsappTextFormatter.formatSummary(
      patientName: 'Ana',
      sleepRecords: sleep,
      moodEntries: moods,
      l10n: l10n,
      recoverySnapshots: recovery,
      appleHealthSomCount: appleHealthSomCount,
    );
  }

  MoodEntry mood({
    required String id,
    Set<String> labels = const {},
    String? note,
    bool sensoryOverload = false,
    StateOfMindSource source = StateOfMindSource.lumen,
  }) {
    return MoodEntry(
      id: id,
      timestamp: day.add(Duration(minutes: id.hashCode.abs() % 60)),
      valence: 3,
      energy: EnergyLevel.balanced,
      focus: FocusState.focused,
      note: note,
      emotionLabels: labels,
      sensoryOverload: sensoryOverload,
      emotionSource: source,
    );
  }

  test('1,25 h de REM fica adequado e um minuto a menos entra no alerta', () {
    final enough = summary(
      sleep: [
        night(
          total: const Duration(hours: 7),
          rem: const Duration(minutes: 75),
        ),
      ],
    );
    final short = summary(
      sleep: [
        night(
          total: const Duration(hours: 7),
          rem: const Duration(minutes: 74),
        ),
      ],
    );

    expect(enough, contains('*1.3h* (adequado)'));
    expect(enough, isNot(contains('alerta de deficit')));
    expect(short, contains('alerta de deficit'));
  });

  test('sem noites o resumo sai com zero e sem a seção de recuperação', () {
    final message = summary();

    expect(message, contains('*0.0h*'));
    expect(message, contains('*0* de 0 noites'));
    expect(message, contains('alerta de deficit'));
    expect(message, isNot(contains('SINAIS OBJETIVOS')));
  });

  test('média ignora nulo, corta a sexta palavra e a quarta nota', () {
    final labels = [
      ('overwhelmed', 6),
      ('stressed', 5),
      ('anxious', 4),
      ('sad', 3),
      ('calm', 2),
      ('happy', 1),
    ];
    final moods = <MoodEntry>[
      for (final (id, count) in labels)
        for (var i = 0; i < count; i++) mood(id: '$id-$i', labels: {id}),
      mood(id: 'blank', note: ''),
      mood(id: 'n1', note: 'nota-um'),
      mood(id: 'n2', note: 'nota-dois'),
      mood(id: 'n3', note: 'nota-tres'),
      mood(id: 'n4', note: 'nota-quatro'),
      mood(
        id: 'apple-words',
        labels: const {'calm'},
        source: StateOfMindSource.appleHealth,
      ),
      mood(id: 'apple-empty', source: StateOfMindSource.appleHealth),
    ];

    final message = summary(
      moods: moods,
      recovery: [
        DailyRecoverySnapshot(date: day, hrvMs: 30),
        DailyRecoverySnapshot(
          date: day.add(const Duration(days: 1)),
          steps: 4000,
        ),
      ],
      appleHealthSomCount: 2,
    );

    expect(message, contains('*30 ms*'));
    expect(message, contains('*4000*'));
    expect(message, isNot(contains('*15 ms*')));
    expect(message, isNot(contains('*2000*')));
    expect(message, contains('Sobrecarregado(a) (6x)'));
    expect(message, isNot(contains('Feliz (1x)')));
    expect(message, contains('nota-um'));
    expect(message, contains('nota-tres'));
    expect(message, isNot(contains('nota-quatro')));
    expect(message, isNot(contains('Sobrecarga Sensorial')));
    expect(message, contains('*3* dia(s) importados do Apple Health'));
    expect(message, contains('*0 de ${moods.length} registros*'));
  });

  test('sobrecarga sensorial só entra quando houve registro', () {
    final quiet = summary(moods: [mood(id: 'q')]);
    final loud = summary(moods: [mood(id: 's', sensoryOverload: true)]);

    expect(quiet, isNot(contains('Sobrecarga Sensorial')));
    expect(loud, contains('Sobrecarga Sensorial'));
  });
}
