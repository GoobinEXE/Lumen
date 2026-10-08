import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';

/// Níveis de foco específicos para a experiência com TDAH
enum FocusState { focused, hyperfocus, scattered, paralyzed }

/// Nível de energia vital
enum EnergyLevel { drained, low, balanced, energized, hyper }

/// Registro pontual (micro check-in de 3 segundos) do estado do usuário
class MoodEntry {
  final String id;
  final DateTime timestamp;
  final int valence; // 1 (Péssimo) a 5 (Excelente)
  final EnergyLevel energy;
  final FocusState focus;
  final bool tookMedication;
  final bool sensoryOverload;
  final String? note;
  /// IDs HKStateOfMind.Label (ex: calm, overwhelmed)
  final Set<String> emotionLabels;
  /// Origem das palavras emocionais / check-in (Lumen ou Apple Health).
  final StateOfMindSource emotionSource;

  const MoodEntry({
    required this.id,
    required this.timestamp,
    required this.valence,
    required this.energy,
    required this.focus,
    this.tookMedication = false,
    this.sensoryOverload = false,
    this.note,
    this.emotionLabels = const {},
    this.emotionSource = StateOfMindSource.lumen,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'valence': valence,
      'energy': energy.name,
      'focus': focus.name,
      'tookMedication': tookMedication,
      'sensoryOverload': sensoryOverload,
      'note': note,
      'emotionLabels': emotionLabels.toList(),
      'emotionSource': emotionSource.name,
    };
  }

  /// A nota livre sai do export quando a pessoa pede para ocultar o texto íntimo.
  MoodEntry withoutPrivateNote() {
    if (note == null) return this;
    return MoodEntry(
      id: id,
      timestamp: timestamp,
      valence: valence,
      energy: energy,
      focus: focus,
      tookMedication: tookMedication,
      sensoryOverload: sensoryOverload,
      emotionLabels: emotionLabels,
      emotionSource: emotionSource,
    );
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      valence: map['valence'] as int? ?? 3,
      energy: EnergyLevel.values.firstWhere(
        (e) => e.name == map['energy'],
        orElse: () => EnergyLevel.balanced,
      ),
      focus: FocusState.values.firstWhere(
        (f) => f.name == map['focus'],
        orElse: () => FocusState.focused,
      ),
      tookMedication: map['tookMedication'] as bool? ?? false,
      sensoryOverload: map['sensoryOverload'] as bool? ?? false,
      note: map['note'] as String?,
      emotionLabels:
          (map['emotionLabels'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ??
              const {},
      emotionSource: StateOfMindSource.values.firstWhere(
        (s) => s.name == map['emotionSource'],
        orElse: () => StateOfMindSource.lumen,
      ),
    );
  }
}
