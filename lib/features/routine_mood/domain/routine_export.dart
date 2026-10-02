import 'routine_snapshot.dart';

/// Linha que PDF, WhatsApp e card descrevem do mesmo jeito.
class RoutineExportLine {
  const RoutineExportLine({
    required this.savedAt,
    required this.anchor,
    required this.waterGlasses,
    required this.completedHabits,
    required this.tookPrescribedMedication,
    this.eveningReflection,
    this.therapistNotes,
  });

  final DateTime savedAt;
  final String anchor;
  final int waterGlasses;
  final List<String> completedHabits;
  final bool tookPrescribedMedication;
  final String? eveningReflection;
  final String? therapistNotes;
}

List<RoutineExportLine> routineExportLines({
  required List<RoutineSnapshot> snapshots,
  required DateTime now,
  required int periodDays,
  required bool hideIntimateNotes,
}) {
  final start = now.subtract(Duration(days: periodDays));
  final filtered = snapshots
      .where((snapshot) => !snapshot.savedAt.isBefore(start))
      .toList()
    ..sort((a, b) => a.savedAt.compareTo(b.savedAt));

  return [
    for (final snapshot in filtered)
      RoutineExportLine(
        savedAt: snapshot.savedAt,
        anchor: snapshot.mainFocusAnchor.trim(),
        waterGlasses: snapshot.waterGlasses,
        completedHabits: snapshot.completedHabits.toList()..sort(),
        tookPrescribedMedication: snapshot.tookPrescribedMedication,
        eveningReflection: hideIntimateNotes
            ? null
            : _textOrNull(snapshot.eveningReflection),
        therapistNotes: hideIntimateNotes
            ? null
            : _textOrNull(snapshot.therapistNotes),
      ),
  ];
}

String? _textOrNull(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  return text;
}
