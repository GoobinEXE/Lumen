import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:noa/features/medications/service/medication_reminder_service.dart';
import 'package:noa/features/medications/service/reminder_schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ensureDoseLog', () {
    late MedicationRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = MedicationRepository(prefs);
    });

    test('o mesmo minuto reaproveita o log e outro dia abre outro', () async {
      final first = await repo.ensureDoseLog(
        medicationId: 'med-1',
        medicationName: 'Lisdexanfetamina',
        scheduled: DateTime(2026, 10, 1, 8, 0, 1),
      );
      final sameMinute = await repo.ensureDoseLog(
        medicationId: 'med-1',
        medicationName: 'Lisdexanfetamina',
        scheduled: DateTime(2026, 10, 1, 8, 0, 59),
      );
      final nextDay = await repo.ensureDoseLog(
        medicationId: 'med-1',
        medicationName: 'Lisdexanfetamina',
        scheduled: DateTime(2026, 10, 2, 8, 0, 1),
      );

      expect(sameMinute.id, first.id);
      expect(nextDay.id, isNot(first.id));
      expect(await repo.logById(first.id), isNotNull);
      expect(await repo.logById(nextDay.id), isNotNull);
    });

    test('outro minuto ou outro remédio não grava em cima', () async {
      final eight = await repo.ensureDoseLog(
        medicationId: 'med-1',
        medicationName: 'Lisdexanfetamina',
        scheduled: DateTime(2026, 10, 1, 8),
      );
      final eightOne = await repo.ensureDoseLog(
        medicationId: 'med-1',
        medicationName: 'Lisdexanfetamina',
        scheduled: DateTime(2026, 10, 1, 8, 1),
      );
      final otherMed = await repo.ensureDoseLog(
        medicationId: 'med-2',
        medicationName: 'Metilfenidato',
        scheduled: DateTime(2026, 10, 1, 8),
      );

      expect({eight.id, eightOne.id, otherMed.id}, hasLength(3));
    });
  });

  group('estado da dose', () {
    test('adiamento vencido volta a ficar pendente e tomada não volta', () {
      final pending = MedicationLog(
        id: 'log',
        medicationId: 'med-1',
        medicationName: 'Lisdexanfetamina',
        scheduledTime: DateTime(2026, 10, 1, 8),
        snoozedUntil: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      final snoozed = pending.copyWith(
        snoozedUntil: DateTime.now().add(const Duration(minutes: 5)),
      );
      final taken = snoozed.copyWith(takenAt: DateTime(2026, 10, 1, 8, 5));
      final skipped = MedicationLog(
        id: 'skip',
        medicationId: 'med-1',
        medicationName: 'Lisdexanfetamina',
        scheduledTime: DateTime(2026, 10, 1, 8),
        skipped: true,
      );

      expect(pending.isSnoozed, isFalse);
      expect(pending.isPending, isTrue);
      expect(snoozed.isSnoozed, isTrue);
      expect(snoozed.isPending, isFalse);
      expect(taken.isTaken, isTrue);
      expect(taken.isPending, isFalse);
      expect(skipped.isPending, isFalse);
    });

    test('estoque no limite do aviso já pede reposição', () {
      const atLimit = Medication(
        id: 'm',
        name: 'Lisdexanfetamina',
        dosage: '30mg',
        scheduledTimes: ['08:00'],
        remainingStock: 5,
        refillWarningThreshold: 5,
      );
      const above = Medication(
        id: 'm2',
        name: 'Lisdexanfetamina',
        dosage: '30mg',
        scheduledTimes: ['08:00'],
        remainingStock: 6,
        refillWarningThreshold: 5,
      );

      expect(atLimit.needsRefillWarning, isTrue);
      expect(above.needsRefillWarning, isFalse);
    });
  });

  group('horário que a notificação usa hoje', () {
    test('hora sem minuto vale zero e texto ilegível cai nas 8', () {
      final now = DateTime.now();
      final evening = scheduledOnToday('22');
      final broken = scheduledOnToday('manha');

      expect(evening.year, now.year);
      expect(evening.month, now.month);
      expect(evening.day, now.day);
      expect(evening.hour, 22);
      expect(evening.minute, 0);
      expect(broken.hour, 8);
      expect(broken.minute, 0);
    });
  });

  test(
    'idioma salvo do lembrete vence o do aparelho e system segue o aparelho',
    () async {
      Locale deviceLocale() {
        final code = PlatformDispatcher.instance.locale.languageCode
            .toLowerCase();
        switch (code) {
          case 'en':
            return const Locale('en');
          case 'ja':
            return const Locale('ja');
          case 'es':
            return const Locale('es');
          default:
            return const Locale('pt');
        }
      }

      SharedPreferences.setMockInitialValues({
        'noa_preferred_locale_code': 'ja',
      });
      final saved = await SharedPreferences.getInstance();
      expect(localeFromReminderPrefs(saved), const Locale('ja'));

      await saved.setString('noa_preferred_locale_code', 'system');
      expect(localeFromReminderPrefs(saved), deviceLocale());

      await saved.remove('noa_preferred_locale_code');
      expect(localeFromReminderPrefs(saved), deviceLocale());
    },
  );
}
