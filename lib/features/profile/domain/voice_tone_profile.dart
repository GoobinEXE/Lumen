/// Perfis de tom de voz humanizado (GDD §7).
///
/// As chaves de serialização são estáveis e seguem o GDD, para que o valor
/// persistido em `noa_user_profile_v1` continue legível entre atualizações.
enum VoiceToneProfile {
  relaxed,
  casual,
  neutral,
  formal,
  femaleAdult,
  girlYouth,
  boyYouth;

  static const VoiceToneProfile fallback = VoiceToneProfile.casual;

  String toMap() {
    switch (this) {
      case VoiceToneProfile.relaxed:
        return 'relaxed';
      case VoiceToneProfile.casual:
        return 'casual';
      case VoiceToneProfile.neutral:
        return 'neutral';
      case VoiceToneProfile.formal:
        return 'formal';
      case VoiceToneProfile.femaleAdult:
        return 'femaleAdult';
      case VoiceToneProfile.girlYouth:
        return 'girlYouth';
      case VoiceToneProfile.boyYouth:
        return 'boyYouth';
    }
  }

  static VoiceToneProfile fromMap(Object? value) {
    switch (value) {
      case 'relaxed':
        return VoiceToneProfile.relaxed;
      case 'casual':
        return VoiceToneProfile.casual;
      case 'neutral':
        return VoiceToneProfile.neutral;
      case 'formal':
        return VoiceToneProfile.formal;
      case 'femaleAdult':
        return VoiceToneProfile.femaleAdult;
      case 'girlYouth':
        return VoiceToneProfile.girlYouth;
      case 'boyYouth':
        return VoiceToneProfile.boyYouth;
      default:
        return fallback;
    }
  }
}
