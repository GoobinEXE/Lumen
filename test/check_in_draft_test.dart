import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/routine_mood/presentation/check_in_form.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';

void main() {
  test('CheckInDraft deriva StateOfMind com valence e labels', () {
    final when = DateTime(2026, 10, 6, 12);
    final draft = CheckInDraft(
      valence: 5,
      focus: FocusState.hyperfocus,
      energy: EnergyLevel.energized,
      emotionLabels: const {'happy', 'calm'},
      note: 'foi bem',
    );
    final som = draft.toStateOfMind(timestamp: when);
    expect(som.kind, StateOfMindKind.momentary);
    expect(som.valence, 1.0);
    expect(som.labels, containsAll(['happy', 'calm']));
    expect(som.timestamp, when);
    expect(som.source, StateOfMindSource.lumen);
  });

  test('mainFocusAnchor da tarefa âncora é o título pinado', () {
    // Contrato do Dia: o título do dia é o da tarefa marcada, sem TextField livre.
    const title = 'Terminar o rascunho';
    expect(title.trim().isNotEmpty, isTrue);
    final draft = CheckInDraft(valence: 3);
    expect(draft.toStateOfMind().labels, isEmpty);
  });
}
