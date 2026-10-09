import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/therapist_export/data/therapist_contact_repository.dart';
import 'package:noa/features/therapist_export/domain/care_contact.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('migra telefone legado para lista de contatos', () async {
    SharedPreferences.setMockInitialValues({
      TherapistContactRepository.legacyPhoneKey: '5511999999999',
    });
    final repo = TherapistContactRepository(
      await SharedPreferences.getInstance(),
    );

    final contacts = repo.listContacts();
    expect(contacts, hasLength(1));
    expect(contacts.single.role, CareContactRole.therapist);
    expect(contacts.single.phone, '5511999999999');
    expect(repo.readPrimaryPhone(), '5511999999999');

    final persisted = (await SharedPreferences.getInstance()).getString(
      TherapistContactRepository.contactsKey,
    );
    expect(persisted, isNotNull);
  });

  test('upsert e delete mantem múltiplos contatos', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = TherapistContactRepository(
      await SharedPreferences.getInstance(),
    );

    final therapist = CareContact(
      id: 'c1',
      role: CareContactRole.therapist,
      displayName: 'Dra. Ana',
      phone: '5511888888888',
      updatedAt: DateTime(2026, 10, 6, 9),
    );
    final psychiatrist = CareContact(
      id: 'c2',
      role: CareContactRole.psychiatrist,
      displayName: 'Dr. Beto',
      phone: '5511777777777',
      updatedAt: DateTime(2026, 10, 6, 10),
    );

    await repo.upsert(therapist);
    await repo.upsert(psychiatrist);

    final loaded = repo.listContacts();
    expect(loaded, hasLength(2));
    expect(repo.readPrimaryPhone(), '5511888888888');

    await repo.delete('c1');
    final afterDelete = repo.listContacts();
    expect(afterDelete, hasLength(1));
    expect(afterDelete.single.id, 'c2');
    expect(repo.readPrimaryPhone(), '5511777777777');
  });

  test('savePhone mantém compatibilidade com fluxo antigo', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = TherapistContactRepository(
      await SharedPreferences.getInstance(),
    );

    await repo.savePhone(' 5511999999999 ');
    final contacts = repo.listContacts();
    expect(contacts, hasLength(1));
    expect(contacts.single.role, CareContactRole.therapist);
    expect(contacts.single.phone, '5511999999999');
    expect(repo.readPhone(), '5511999999999');
  });
}
