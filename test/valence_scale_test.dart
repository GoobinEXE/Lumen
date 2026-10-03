import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/core/localization/l10n_labels.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:noa/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('pt'));
  final when = DateTime(2026, 10, 1, 9);

  StateOfMindEntry som(double valence) {
    return StateOfMindEntry(valence: valence, timestamp: when);
  }

  test('os cortes de valência batem na escala do check-in e no rótulo', () {
    void band(double valence, int scale, String label) {
      final entry = som(valence);
      expect(entry.valenceAsCheckinScale, scale, reason: '$valence');
      expect(entry.valenceLabel(l10n), label, reason: '$valence');
    }

    band(-1, 1, 'Muito desagradável');
    band(-0.6, 1, 'Muito desagradável');
    band(-0.59, 2, 'Desagradável');
    band(-0.2, 2, 'Desagradável');
    band(-0.19, 3, 'Neutro');
    band(0, 3, 'Neutro');
    band(0.19, 3, 'Neutro');
    band(0.2, 4, 'Agradável');
    band(0.59, 4, 'Agradável');
    band(0.6, 5, 'Muito agradável');
    band(1, 5, 'Muito agradável');
  });

  test('a escala 1 a 5 volta para a mesma faixa e o resto fica neutro', () {
    for (var scale = 1; scale <= 5; scale++) {
      final valence = StateOfMindEntry.checkinScaleToValence(scale);
      expect(som(valence).valenceAsCheckinScale, scale);
    }

    for (final invalid in [0, 6, -1]) {
      final valence = StateOfMindEntry.checkinScaleToValence(invalid);
      expect(valence, 0);
      expect(som(valence).valenceAsCheckinScale, 3);
      expect(som(valence).valenceLabel(l10n), 'Neutro');
    }
  });

  test('valência fora de 1 a 5 no PDF do check-in continua neutra', () {
    String label(int valence) {
      return MoodEntry(
        id: 'm',
        timestamp: when,
        valence: valence,
        energy: EnergyLevel.balanced,
        focus: FocusState.focused,
      ).valenceLabel(l10n);
    }

    expect(label(1), 'Muito difícil');
    expect(label(2), 'Pesado');
    expect(label(3), 'Neutro');
    expect(label(4), 'Bom');
    expect(label(5), 'Excelente');
    expect(label(0), 'Neutro');
    expect(label(6), 'Neutro');
  });

  test('empate de horário mantém o State of Mind local', () {
    final local = StateOfMindEntry(
      valence: 0.2,
      labels: const {'calm'},
      timestamp: when,
      source: StateOfMindSource.lumen,
    );
    final fromApple = StateOfMindEntry(
      valence: -0.8,
      labels: const {'sad'},
      timestamp: when,
      source: StateOfMindSource.appleHealth,
    );

    final merged = StateOfMindEntry.mergePreferNewest(local, fromApple);

    expect(merged?.source, StateOfMindSource.lumen);
    expect(merged?.labels, contains('calm'));
    expect(StateOfMindEntry.mergePreferNewest(local, null), same(local));
    expect(StateOfMindEntry.mergePreferNewest(null, null), isNull);
  });

  test('kind desconhecido volta para o humor do dia', () {
    final restored = StateOfMindEntry.fromMap({
      'kind': 'watch',
      'valence': 1,
      'timestamp': when.toIso8601String(),
    });

    expect(restored.kind, StateOfMindKind.dailyMood);
    expect(restored.valence, 1);
    expect(restored.source, StateOfMindSource.lumen);
  });
}
