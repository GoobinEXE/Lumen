/// URL pública da Política de Privacidade (GitHub Pages).
///
/// Override: `flutter run --dart-define=PRIVACY_POLICY_URL=https://...`
class PrivacyPolicyConfig {
  const PrivacyPolicyConfig._();

  static const String url = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://goobinexe.github.io/lumen-privacy/',
  );

  static Uri get uri => Uri.parse(url);

  static bool get isConfigured {
    final parsed = uri;
    return parsed.hasScheme &&
        parsed.scheme == 'https' &&
        parsed.host.isNotEmpty;
  }
}
