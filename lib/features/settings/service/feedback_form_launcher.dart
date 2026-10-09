import 'package:url_launcher/url_launcher.dart';

import 'feedback_form_config.dart';

/// Abre o formulário de feedback no navegador / app do sistema.
/// A UI só chama — não lê a URL nem monta o [Uri].
class FeedbackFormLauncher {
  const FeedbackFormLauncher();

  Future<bool> open() async {
    if (!FeedbackFormConfig.isConfigured) return false;
    final uri = FeedbackFormConfig.uri;
    try {
      if (!await canLaunchUrl(uri)) return false;
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
