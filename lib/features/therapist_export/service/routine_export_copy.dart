import 'package:intl/intl.dart';
import 'package:noa/features/routine_mood/domain/routine_export.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_labels.dart';
import 'package:noa/l10n/app_localizations.dart';

List<String> describeRoutineExportLine({
  required AppLocalizations l10n,
  required RoutineExportLine line,
  required DateFormat dateFormat,
  required DateFormat timeFormat,
  String languageCode = 'pt',
}) {
  final anchor =
      line.anchor.isEmpty ? l10n.exportRoutineAnchorEmpty : line.anchor;
  final when =
      '${dateFormat.format(line.savedAt)} ${timeFormat.format(line.savedAt)}';
  final som = line.stateOfMind;
  final somLabels = som == null
      ? ''
      : som.labels
          .map((id) => StateOfMindLabels.label(id, languageCode))
          .where((t) => t.isNotEmpty)
          .join(', ');
  return [
    l10n.homeRoutineSnapshotLine(when, anchor),
    l10n.exportRoutineWater(line.waterGlasses),
    line.completedHabits.isEmpty
        ? l10n.exportRoutineHabitsNone
        : l10n.exportRoutineHabits(line.completedHabits.join(', ')),
    line.tookPrescribedMedication
        ? l10n.exportRoutineMedYes
        : l10n.exportRoutineMedNo,
    if (somLabels.isNotEmpty) l10n.exportRoutineSom(somLabels),
    if (line.eveningReflection != null)
      l10n.exportRoutineReflection(line.eveningReflection!),
    if (line.therapistNotes != null)
      l10n.exportRoutineNotes(line.therapistNotes!),
  ];
}
