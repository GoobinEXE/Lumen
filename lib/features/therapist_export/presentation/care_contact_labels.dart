import 'package:noa/l10n/app_localizations.dart';

import '../domain/care_contact.dart';

/// Rótulo humanizado da função de cada profissional da rede de apoio.
String careContactRoleLabel(AppLocalizations l10n, CareContactRole role) {
  switch (role) {
    case CareContactRole.therapist:
      return l10n.careContactRoleTherapist;
    case CareContactRole.psychologist:
      return l10n.careContactRolePsychologist;
    case CareContactRole.psychiatrist:
      return l10n.careContactRolePsychiatrist;
    case CareContactRole.other:
      return l10n.careContactRoleOther;
  }
}

/// Nome para exibir: o apelido salvo ou, se não houver, a função.
String careContactDisplayName(AppLocalizations l10n, CareContact contact) {
  final name = contact.displayName?.trim();
  if (name != null && name.isNotEmpty) return name;
  return careContactRoleLabel(l10n, contact.role);
}
