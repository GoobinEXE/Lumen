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
  Future<bool> requestAccess(SharedPreferences prefs) async {
    try {
      final already = await _channel<bool>('hasAccess');
      if (already == true) {
        await prefs.setBool(calendarAccessPromptedKey, true);
        return true;
      }
      await prefs.setBool(calendarAccessPromptedKey, true);
      return await _channel<bool>('requestAccess') ?? false;
    } catch (_) {
      await prefs.setBool(calendarAccessPromptedKey, true);
      return false;
    }
  }

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
        granted = await requestAccess(prefs);
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

/// Notas do evento no calendário do sistema — sem reflexão/pauta íntimas
/// (essas só saem no export clínico quando a pessoa libera o toggle).
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
  return lines.join('\n');
}
