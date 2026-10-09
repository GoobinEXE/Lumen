import 'package:url_launcher/url_launcher.dart';

import 'privacy_policy_config.dart';

/// Abre a Política de Privacidade no navegador do sistema.
class PrivacyPolicyLauncher {
  const PrivacyPolicyLauncher();

  Future<bool> open() async {
    if (!PrivacyPolicyConfig.isConfigured) return false;
    final uri = PrivacyPolicyConfig.uri;
    try {
      if (!await canLaunchUrl(uri)) return false;
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
