import '../../state_of_mind/domain/state_of_mind_entry.dart';

/// Representa o estado completo da rotina diária e reflexões emocionais in-app.
/// Projetado para funcionar com 100% de autonomia e completude tanto no iPhone quanto no Android.
class DailyRoutineState {
  final DateTime date;
  final String mainFocusAnchor;
  final StateOfMindEntry? stateOfMind;
  final String eveningReflection;
  final List<String> microHabits;
  final Set<String> completedHabits;
  final int waterGlasses;
  final bool tookPrescribedMedication;
  final String? therapistNotes;

  const DailyRoutineState({
    required this.date,
    this.mainFocusAnchor = '',
    this.stateOfMind,
    this.eveningReflection = '',
    this.microHabits = const [],
    this.completedHabits = const {},
    this.waterGlasses = 0,
    this.tookPrescribedMedication = false,
    this.therapistNotes,
  });

  DailyRoutineState copyWith({
    DateTime? date,
    String? mainFocusAnchor,
    StateOfMindEntry? stateOfMind,
    bool clearStateOfMind = false,
    String? eveningReflection,
    List<String>? microHabits,
    Set<String>? completedHabits,
    int? waterGlasses,
    bool? tookPrescribedMedication,
    String? therapistNotes,
  }) {
    return DailyRoutineState(
      date: date ?? this.date,
      mainFocusAnchor: mainFocusAnchor ?? this.mainFocusAnchor,
      stateOfMind: clearStateOfMind ? null : (stateOfMind ?? this.stateOfMind),
      eveningReflection: eveningReflection ?? this.eveningReflection,
      microHabits: microHabits ?? this.microHabits,
      completedHabits: completedHabits ?? this.completedHabits,
      waterGlasses: waterGlasses ?? this.waterGlasses,
      tookPrescribedMedication:
          tookPrescribedMedication ?? this.tookPrescribedMedication,
      therapistNotes: therapistNotes ?? this.therapistNotes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'mainFocusAnchor': mainFocusAnchor,
      if (stateOfMind != null) 'stateOfMind': stateOfMind!.toMap(),
      'eveningReflection': eveningReflection,
      'microHabits': microHabits,
      'completedHabits': completedHabits.toList(),
      'waterGlasses': waterGlasses,
      'tookPrescribedMedication': tookPrescribedMedication,
      'therapistNotes': therapistNotes,
    };
  }

  factory DailyRoutineState.fromMap(Map<String, dynamic> map) {
    StateOfMindEntry? som;
    if (map['stateOfMind'] is Map<String, dynamic>) {
      som = StateOfMindEntry.fromMap(map['stateOfMind'] as Map<String, dynamic>);
    }

    return DailyRoutineState(
      date: DateTime.parse(map['date'] as String),
      mainFocusAnchor: map['mainFocusAnchor'] as String? ?? '',
      stateOfMind: som,
      eveningReflection: map['eveningReflection'] as String? ?? '',
      microHabits: (map['microHabits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      completedHabits:
          (map['completedHabits'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ??
              const {},
      waterGlasses: map['waterGlasses'] as int? ?? 0,
      tookPrescribedMedication: map['tookPrescribedMedication'] as bool? ?? false,
      therapistNotes: map['therapistNotes'] as String?,
    );
  }
}
