import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/routine_mood/domain/routine_export.dart';
import 'package:noa/features/therapist_export/service/therapist_pdf_generator.dart';
import 'package:noa/features/therapist_export/service/whatsapp_text_formatter.dart';
import 'package:noa/l10n/app_localizations.dart';

void main() {
  const secret = 'briguei e nao consegui sair da cama';

  MoodEntry entry() {
    return MoodEntry(
      id: 'checkin-1',
      timestamp: DateTime(2026, 10, 8, 9, 30),
      valence: 2,
      energy: EnergyLevel.low,
      focus: FocusState.paralyzed,
      note: secret,
    );
  }

  test('ocultar notas íntimas tira a nota livre e mantém o resto do check-in', () {
    final hidden = redactIntimateMoodNotes(
      [entry()],
      hideIntimateNotes: true,
    );
    final shown = redactIntimateMoodNotes(
      [entry()],
      hideIntimateNotes: false,
    );

    expect(hidden.single.note, isNull);
    expect(hidden.single.focus, FocusState.paralyzed);
    expect(hidden.single.valence, 2);
    expect(shown.single.note, secret);
  });

  test('WhatsApp e PDF não levam a nota livre quando o toggle está ligado', () async {
    final l10n = lookupAppLocalizations(const Locale('pt'));
    final hidden = redactIntimateMoodNotes(
      [entry()],
      hideIntimateNotes: true,
    );
    final message = WhatsappTextFormatter.formatSummary(
      patientName: 'Marcelo P.',
      sleepRecords: const [],
      moodEntries: hidden,
      l10n: l10n,
    );
    final pdf = await TherapistPdfGenerator.generateReport(
      patientName: 'Marcelo P.',
      sleepRecords: const [],
      moodEntries: [entry()],
      hideIntimateNotes: true,
      l10n: l10n,
    );
    final visible = await TherapistPdfGenerator.generateReport(
      patientName: 'Marcelo P.',
      sleepRecords: const [],
      moodEntries: [entry()],
      hideIntimateNotes: false,
      l10n: l10n,
    );

    expect(message, isNot(contains(secret)));
    expect(_pdfPlainText(pdf), isNot(contains(secret)));
    expect(_pdfPlainText(visible), contains(secret));
  });
}

String _pdfPlainText(List<int> bytes) {
  final raw = latin1.decode(bytes, allowInvalid: true);
  final buffer = StringBuffer(raw);
  final stream = RegExp(r'stream\r?\n([\s\S]*?)\r?\nendstream');
  for (final match in stream.allMatches(raw)) {
    final chunk = latin1.encode(match.group(1)!);
    try {
      buffer.write(latin1.decode(zlib.decode(chunk), allowInvalid: true));
    } catch (_) {}
  }
  return buffer.toString();
}
