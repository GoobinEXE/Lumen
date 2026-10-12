import '../../../integrations/healthkit_bridge/healthkit_bridge.dart';
import '../domain/medication.dart';

/// Resultado de cruzar um remédio do Saúde com a lista local.
class AppleMedicationLink {
  const AppleMedicationLink({
    required this.medication,
    required this.countsAsImported,
  });

  final Medication medication;

  /// Conceito já vinculado não conta de novo. Nome novo ou cadastro novo conta.
  final bool countsAsImported;
}

/// Decide o vínculo sem gravar.
///
/// Inativo sai fora. O mesmo concept id vence o nome. Nome e apelido ignoram
/// maiúsculas. Apelido vazio não substitui o nome oficial.
AppleMedicationLink? linkAppleMedication({
  required HealthKitMedicationInfo info,
  required List<Medication> existing,
  required String Function() newId,
  required String fallbackDosage,
  required String fallbackInstructions,
}) {
  if (!info.isActive) return null;

  final byConcept = existing.where(
    (med) => med.appleConceptId == info.appleConceptId,
  );
  final byName = existing.where(
    (med) =>
        med.name.toLowerCase() == info.name.toLowerCase() ||
        (info.nickname != null &&
            med.name.toLowerCase() == info.nickname!.toLowerCase()),
  );

  if (byConcept.isNotEmpty) {
    final current = byConcept.first;
    return AppleMedicationLink(
      countsAsImported: false,
      medication: current.copyWith(
        rxNormCode: info.rxNormCode ?? current.rxNormCode,
        source: MedicationSource.linked,
      ),
    );
  }

  if (byName.isNotEmpty) {
    final current = byName.first;
    return AppleMedicationLink(
      countsAsImported: true,
      medication: current.copyWith(
        appleConceptId: info.appleConceptId,
        rxNormCode: info.rxNormCode,
        source: MedicationSource.linked,
      ),
    );
  }

  final nickname = info.nickname;
  return AppleMedicationLink(
    countsAsImported: true,
    medication: Medication(
      id: newId(),
      name: nickname != null && nickname.isNotEmpty ? nickname : info.name,
      dosage: info.form ?? fallbackDosage,
      scheduledTimes: const ['08:00'],
      instructions: fallbackInstructions,
      appleConceptId: info.appleConceptId,
      rxNormCode: info.rxNormCode,
      source: MedicationSource.appleHealth,
    ),
  );
}
