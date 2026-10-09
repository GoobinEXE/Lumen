import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/therapist_export/data/pdf_style_prefs.dart';
import 'package:noa/features/therapist_export/domain/pdf_report_style.dart';
import 'package:noa/features/therapist_export/service/therapist_pdf_generator.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfReportStyle prefs', () {
    test('default é clinicalCalm', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(getPdfReportStyle(prefs), PdfReportStyle.clinicalCalm);
    });

    test('persiste lumenSoft e lê de volta', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await setPdfReportStyle(prefs, PdfReportStyle.lumenSoft);
      expect(prefs.getString(pdfReportStyleKey), 'lumen_soft');
      expect(getPdfReportStyle(prefs), PdfReportStyle.lumenSoft);
    });

    test('fromStorage ignora valor desconhecido', () {
      expect(
        PdfReportStyleStorage.fromStorage('nope'),
        PdfReportStyle.clinicalCalm,
      );
    });
  });

  group('TherapistPdfGenerator', () {
    late AppLocalizations l10n;

    setUp(() {
      l10n = lookupAppLocalizations(const Locale('pt'));
    });

    SleepRecord night() => SleepRecord(
      date: DateTime(2026, 10, 7),
      bedtime: DateTime(2026, 10, 6, 23, 30),
      wakeTime: DateTime(2026, 10, 7, 7),
      totalSleep: const Duration(hours: 7, minutes: 15),
      remSleep: const Duration(hours: 1, minutes: 30),
      deepSleep: const Duration(hours: 1, minutes: 10),
    );

    MoodEntry mood() => MoodEntry(
      id: 'm1',
      timestamp: DateTime(2026, 10, 7, 10),
      valence: 3,
      energy: EnergyLevel.balanced,
      focus: FocusState.focused,
      tookMedication: true,
      note: 'Dia ok',
    );

    test('gera bytes nos dois estilos', () async {
      for (final style in PdfReportStyle.values) {
        final bytes = await TherapistPdfGenerator.generateReport(
          patientName: 'Ana',
          sleepRecords: [night()],
          moodEntries: [mood()],
          periodDays: 7,
          style: style,
          l10n: l10n,
        );
        expect(bytes, isNotEmpty, reason: 'estilo $style');
        // Assinatura PDF
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      }
    });
  });
}
