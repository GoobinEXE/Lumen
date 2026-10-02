import 'daily_routine_state.dart';
import '../../state_of_mind/domain/state_of_mind_entry.dart';

/// Um clique em Salvar. O dia pode ter vários, cada um com a hora.
class RoutineSnapshot {
  const RoutineSnapshot({
    required this.id,
    required this.savedAt,
    this.mainFocusAnchor = '',
    this.stateOfMind,
    this.eveningReflection = '',
    this.microHabits = const [],
    this.completedHabits = const {},
    this.waterGlasses = 0,
    this.tookPrescribedMedication = false,
    this.therapistNotes,
    this.calendarEventId,
  });

  final String id;
  final DateTime savedAt;
  final String mainFocusAnchor;
  final StateOfMindEntry? stateOfMind;
  final String eveningReflection;
  final List<String> microHabits;
  final Set<String> completedHabits;
  final int waterGlasses;
  final bool tookPrescribedMedication;
  final String? therapistNotes;
  final String? calendarEventId;

  DateTime get day => DateTime(savedAt.year, savedAt.month, savedAt.day);

  RoutineSnapshot copyWith({
    String? calendarEventId,
  }) {
    return RoutineSnapshot(
      id: id,
      savedAt: savedAt,
      mainFocusAnchor: mainFocusAnchor,
      stateOfMind: stateOfMind,
      eveningReflection: eveningReflection,
      microHabits: microHabits,
      completedHabits: completedHabits,
      waterGlasses: waterGlasses,
      tookPrescribedMedication: tookPrescribedMedication,
      therapistNotes: therapistNotes,
      calendarEventId: calendarEventId ?? this.calendarEventId,
    );
  }

  factory RoutineSnapshot.capture({
    required String id,
    required DateTime savedAt,
    required DailyRoutineState draft,
  }) {
    final notes = draft.therapistNotes?.trim();
    return RoutineSnapshot(
      id: id,
      savedAt: savedAt,
      mainFocusAnchor: draft.mainFocusAnchor.trim(),
      stateOfMind: draft.stateOfMind,
      eveningReflection: draft.eveningReflection.trim(),
      microHabits: List<String>.from(draft.microHabits),
      completedHabits: Set<String>.from(draft.completedHabits),
      waterGlasses: draft.waterGlasses,
      tookPrescribedMedication: draft.tookPrescribedMedication,
      therapistNotes: (notes == null || notes.isEmpty) ? null : notes,
    );
  }

  /// Registro único antigo, gravado sem hora de salvamento.
  factory RoutineSnapshot.fromLegacy(DailyRoutineState state) {
    return RoutineSnapshot(
      id: 'legacy_${state.date.millisecondsSinceEpoch}',
      savedAt: state.date,
      mainFocusAnchor: state.mainFocusAnchor,
      stateOfMind: state.stateOfMind,
      eveningReflection: state.eveningReflection,
      microHabits: state.microHabits,
      completedHabits: state.completedHabits,
      waterGlasses: state.waterGlasses,
      tookPrescribedMedication: state.tookPrescribedMedication,
      therapistNotes: state.therapistNotes,
    );
  }

  DailyRoutineState toRoutineState() {
    return DailyRoutineState(
      date: day,
      mainFocusAnchor: mainFocusAnchor,
      stateOfMind: stateOfMind,
      eveningReflection: eveningReflection,
      microHabits: microHabits,
      completedHabits: completedHabits,
      waterGlasses: waterGlasses,
      tookPrescribedMedication: tookPrescribedMedication,
      therapistNotes: therapistNotes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'savedAt': savedAt.toIso8601String(),
      'mainFocusAnchor': mainFocusAnchor,
      if (stateOfMind != null) 'stateOfMind': stateOfMind!.toMap(),
      'eveningReflection': eveningReflection,
      'microHabits': microHabits,
      'completedHabits': completedHabits.toList(),
      'waterGlasses': waterGlasses,
      'tookPrescribedMedication': tookPrescribedMedication,
      'therapistNotes': therapistNotes,
      if (calendarEventId != null) 'calendarEventId': calendarEventId,
    };
  }

  factory RoutineSnapshot.fromMap(Map<String, dynamic> map) {
    StateOfMindEntry? som;
    if (map['stateOfMind'] is Map) {
      som = StateOfMindEntry.fromMap(
        Map<String, dynamic>.from(map['stateOfMind'] as Map),
      );
    }

    return RoutineSnapshot(
      id: map['id'] as String? ?? '',
      savedAt: DateTime.parse(map['savedAt'] as String),
      mainFocusAnchor: map['mainFocusAnchor'] as String? ?? '',
      stateOfMind: som,
      eveningReflection: map['eveningReflection'] as String? ?? '',
      microHabits: (map['microHabits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      completedHabits: (map['completedHabits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          const {},
      waterGlasses: map['waterGlasses'] as int? ?? 0,
      tookPrescribedMedication:
          map['tookPrescribedMedication'] as bool? ?? false,
      therapistNotes: map['therapistNotes'] as String?,
      calendarEventId: map['calendarEventId'] as String?,
    );
  }
}
