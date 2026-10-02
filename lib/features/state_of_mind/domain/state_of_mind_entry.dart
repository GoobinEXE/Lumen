/// Clone in-app do State of Mind da Apple (HKStateOfMind).
enum StateOfMindKind {
  momentary,
  dailyMood,
}

enum StateOfMindSource {
  lumen,
  appleHealth,
}

class StateOfMindEntry {
  final StateOfMindKind kind;
  /// -1.0 (muito desagradável) … 1.0 (muito agradável)
  final double valence;
  final Set<String> labels;
  final Set<String> associations;
  final DateTime timestamp;
  final StateOfMindSource source;

  const StateOfMindEntry({
    this.kind = StateOfMindKind.dailyMood,
    this.valence = 0.0,
    this.labels = const {},
    this.associations = const {},
    required this.timestamp,
    this.source = StateOfMindSource.lumen,
  });

  StateOfMindEntry copyWith({
    StateOfMindKind? kind,
    double? valence,
    Set<String>? labels,
    Set<String>? associations,
    DateTime? timestamp,
    StateOfMindSource? source,
  }) {
    return StateOfMindEntry(
      kind: kind ?? this.kind,
      valence: valence ?? this.valence,
      labels: labels ?? this.labels,
      associations: associations ?? this.associations,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
    );
  }

  int get valenceAsCheckinScale {
    if (valence <= -0.6) return 1;
    if (valence <= -0.2) return 2;
    if (valence < 0.2) return 3;
    if (valence < 0.6) return 4;
    return 5;
  }

  static double checkinScaleToValence(int scale) {
    switch (scale) {
      case 1:
        return -1.0;
      case 2:
        return -0.5;
      case 3:
        return 0.0;
      case 4:
        return 0.5;
      case 5:
        return 1.0;
      default:
        return 0.0;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'kind': kind.name,
      'valence': valence,
      'labels': labels.toList(),
      'associations': associations.toList(),
      'timestamp': timestamp.toIso8601String(),
      'source': source.name,
    };
  }

  factory StateOfMindEntry.fromMap(Map<String, dynamic> map) {
    return StateOfMindEntry(
      kind: StateOfMindKind.values.firstWhere(
        (k) => k.name == map['kind'],
        orElse: () => StateOfMindKind.dailyMood,
      ),
      valence: (map['valence'] as num?)?.toDouble() ?? 0.0,
      labels: (map['labels'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ??
          const {},
      associations:
          (map['associations'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ??
              const {},
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
      source: StateOfMindSource.values.firstWhere(
        (s) => s.name == map['source'],
        orElse: () => StateOfMindSource.lumen,
      ),
    );
  }

  /// Preferência: o registro mais recente vence.
  static StateOfMindEntry? mergePreferNewest(
    StateOfMindEntry? local,
    StateOfMindEntry? fromApple,
  ) {
    if (local == null) return fromApple;
    if (fromApple == null) return local;
    return fromApple.timestamp.isAfter(local.timestamp) ? fromApple : local;
  }
}
