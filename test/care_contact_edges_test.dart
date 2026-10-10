import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/therapist_export/data/therapist_contact_repository.dart';
import 'package:noa/features/therapist_export/domain/care_contact.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('papel desconhecido vira other e data ausente fica no epoch', () {
    final contact = CareContact.fromMap({
      'id': 'c1',
      'role': 'coach',
      'phone': '5511',
    });

    expect(contact.role, CareContactRole.other);
    expect(contact.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
    expect(contact.phone, '5511');
    expect(CareContactRoleCodec.fromCode(null), CareContactRole.other);
    expect(
      CareContact.fromMap({
        'role': 'psychologist',
        'updatedAt': 'nope',
      }).id,
      isEmpty,
    );
  });

  test('copyWith limpa o nome de exibição', () {
    final contact = CareContact(
      id: 'c1',
      role: CareContactRole.therapist,
      displayName: 'Dra. Ana',
      phone: '5511',
      updatedAt: DateTime(2026, 10, 6),
    );

    expect(contact.copyWith(clearDisplayName: true).displayName, isNull);
    expect(contact.copyWith().displayName, 'Dra. Ana');
  });

  test('savePhone atualiza o terapeuta e deixa o psiquiatra quieto', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = TherapistContactRepository(prefs);
    await repo.upsert(
      CareContact(
        id: 'psi',
        role: CareContactRole.psychiatrist,
        phone: '5511700000000',
        updatedAt: DateTime(2026, 10, 1),
      ),
    );
    await repo.upsert(
      CareContact(
        id: 'ter',
        role: CareContactRole.therapist,
        phone: '5511800000000',
        updatedAt: DateTime(2026, 10, 1),
      ),
    );

    await repo.savePhone(' 5511999999999 ');

    final contacts = repo.listContacts();
    expect(contacts, hasLength(2));
    expect(
      contacts.firstWhere((item) => item.id == 'ter').phone,
      '5511999999999',
    );
    expect(
      contacts.firstWhere((item) => item.id == 'psi').phone,
      '5511700000000',
    );
  });

  test('lista só com psiquiatra não ganha um segundo contato', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = TherapistContactRepository(prefs);
    await repo.upsert(
      CareContact(
        id: 'psi',
        role: CareContactRole.psychiatrist,
        phone: '5511700000000',
        updatedAt: DateTime(2026, 10, 1),
      ),
    );

    await repo.savePhone('5511888888888');

    final contacts = repo.listContacts();
    expect(contacts, hasLength(1));
    expect(contacts.single.id, 'psi');
    expect(contacts.single.role, CareContactRole.psychiatrist);
    expect(contacts.single.phone, '5511888888888');
  });

  test('telefone em branco não vira o principal', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = TherapistContactRepository(prefs);
    await repo.upsert(
      CareContact(
        id: 'blank',
        role: CareContactRole.therapist,
        phone: '   ',
        updatedAt: DateTime(2026, 10, 1),
      ),
    );
    await repo.upsert(
      CareContact(
        id: 'psi',
        role: CareContactRole.psychiatrist,
        phone: '5511777777777',
        updatedAt: DateTime(2026, 10, 2),
      ),
    );

    expect(repo.readPrimaryPhone(), '5511777777777');
  });

  test('migração já feita não ressuscita o telefone legado', () async {
    SharedPreferences.setMockInitialValues({
      TherapistContactRepository.migratedKey: true,
      TherapistContactRepository.legacyPhoneKey: '5511999999999',
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = TherapistContactRepository(prefs);

    expect(repo.listContacts(), isEmpty);
    expect(repo.readPrimaryPhone(), isEmpty);
    expect(prefs.getString(TherapistContactRepository.contactsKey), isNull);
  });

  test('contato sem id sai da lista e o válido fica', () async {
    final raw = jsonEncode([
      {
        'id': '',
        'role': 'therapist',
        'phone': '5511000000000',
        'updatedAt': '2026-10-01T00:00:00.000',
      },
      {
        'id': 'c1',
        'role': 'psychologist',
        'phone': '5511777777777',
        'updatedAt': '2026-10-02T00:00:00.000',
      },
    ]);
    SharedPreferences.setMockInitialValues({
      TherapistContactRepository.contactsKey: raw,
      TherapistContactRepository.migratedKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = TherapistContactRepository(prefs);

    final contacts = repo.listContacts();
    expect(contacts.map((item) => item.id), ['c1']);
    expect(contacts.single.role, CareContactRole.psychologist);
    expect(prefs.getString(TherapistContactRepository.contactsKey), raw);
  });
}
