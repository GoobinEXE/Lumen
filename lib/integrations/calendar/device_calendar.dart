import 'package:flutter/services.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/routine_mood/domain/routine_snapshot.dart';

const String calendarAccessPromptedKey = 'noa_calendar_access_prompted';

const MethodChannel _calendarChannel = MethodChannel(
  'dev.prism.lumen/calendar_bridge',
);

/// Ponte do calendário do aparelho. A tela não abre o canal.
class DeviceCalendar {
  Future<String?> createRoutineEvent({
    required SharedPreferences prefs,
    required String title,
    required DateTime start,
    required String notes,
  }) async {
    try {
      final already = await _channel<bool>('hasAccess');
      var granted = already ?? false;
      if (!granted) {
        if (prefs.getBool(calendarAccessPromptedKey) ?? false) {
          return null;
        }
        await prefs.setBool(calendarAccessPromptedKey, true);
        granted = await _channel<bool>('requestAccess') ?? false;
        if (!granted) return null;
      }

      return _channel<String>('createEvent', {
        'title': title,
        'startMs': start.millisecondsSinceEpoch,
        'endMs': start.add(const Duration(minutes: 30)).millisecondsSinceEpoch,
        'notes': notes,
      });
    } catch (_) {
      return null;
    }
  }

  Future<T?> _channel<T>(String method, [Object? arguments]) {
    return _calendarChannel.invokeMethod<T>(method, arguments);
  }
}

String routineCalendarTitle(AppLocalizations l10n, RoutineSnapshot snapshot) {
  final anchor = snapshot.mainFocusAnchor.trim();
  if (anchor.isEmpty) return l10n.routineCalendarEventTitle;
  return anchor;
}

String routineCalendarNotes(AppLocalizations l10n, RoutineSnapshot snapshot) {
  final lines = <String>[
    l10n.exportRoutineWater(snapshot.waterGlasses),
    if (snapshot.completedHabits.isEmpty)
      l10n.exportRoutineHabitsNone
    else
      l10n.exportRoutineHabits(snapshot.completedHabits.join(', ')),
    snapshot.tookPrescribedMedication
        ? l10n.exportRoutineMedYes
        : l10n.exportRoutineMedNo,
  ];
  final reflection = snapshot.eveningReflection.trim();
  if (reflection.isNotEmpty) {
    lines.add(l10n.exportRoutineReflection(reflection));
  }
  final notes = snapshot.therapistNotes?.trim() ?? '';
  if (notes.isNotEmpty) {
    lines.add(l10n.exportRoutineNotes(notes));
  }
  return lines.join('\n');
}
