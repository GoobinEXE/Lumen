import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/therapist_export/data/therapist_contact_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('telefone do terapeuta migra da chave antiga sem perder o valor', () async {
    SharedPreferences.setMockInitialValues({
      TherapistContactRepository.legacyKey: '5511999999999',
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = TherapistContactRepository(prefs);

    expect(repo.readPhone(), '5511999999999');
    expect(
      prefs.getString(TherapistContactRepository.currentKey),
      '5511999999999',
    );

    await repo.savePhone('5511888888888');
    expect(repo.readPhone(), '5511888888888');
  });
}
