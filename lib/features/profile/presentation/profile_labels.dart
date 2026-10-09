import 'package:noa/l10n/app_localizations.dart';

import '../domain/voice_tone_profile.dart';

/// Rótulo humanizado de cada perfil de tom de voz.
String voiceToneLabel(AppLocalizations l10n, VoiceToneProfile tone) {
  switch (tone) {
    case VoiceToneProfile.relaxed:
      return l10n.voiceToneRelaxed;
    case VoiceToneProfile.casual:
      return l10n.voiceToneCasual;
    case VoiceToneProfile.neutral:
      return l10n.voiceToneNeutral;
    case VoiceToneProfile.formal:
      return l10n.voiceToneFormal;
    case VoiceToneProfile.femaleAdult:
      return l10n.voiceToneFemaleAdult;
    case VoiceToneProfile.girlYouth:
      return l10n.voiceToneGirlYouth;
    case VoiceToneProfile.boyYouth:
      return l10n.voiceToneBoyYouth;
  }
}

/// Códigos estáveis de sexo biológico, os mesmos do app de saúde.
const List<String> biologicalSexCodes = ['female', 'male', 'other'];

/// Rótulo do código de sexo biológico; código desconhecido volta como está.
String biologicalSexLabel(AppLocalizations l10n, String code) {
  switch (code) {
    case 'male':
      return l10n.biologicalSexMale;
    case 'female':
      return l10n.biologicalSexFemale;
    case 'other':
      return l10n.biologicalSexOther;
    default:
      return code;
  }
}
