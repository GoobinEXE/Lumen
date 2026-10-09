/// Configuração interna do canal de feedback.
///
/// **Só maintainers / admins do Lumen editam este arquivo** (ou o
/// `--dart-define=FEEDBACK_FORM_URL=...` no build). Não mover a URL para
/// `app_*.arb`, não exibir na UI e não logar em analytics.
///
/// A URL aponta para um formulário público: o aparelho precisa abri-la, então
/// ela não é um segredo criptográfico — o controle aqui é de **gestão**
/// (um único ponto para trocar o destino), não de ocultação perante a pessoa.
class FeedbackFormConfig {
  const FeedbackFormConfig._();

  /// Destino do tile "Mandar feedback".
  ///
  /// Override de release / staging:
  /// `flutter run --dart-define=FEEDBACK_FORM_URL=https://forms.gle/...`
  static const String url = String.fromEnvironment(
    'FEEDBACK_FORM_URL',
    defaultValue: 'https://forms.gle/Ji2Fwr8KGLRm88Z76',
  );

  static Uri get uri => Uri.parse(url);

  /// `true` só se o destino for https com host não vazio.
  static bool get isConfigured {
    final parsed = uri;
    return parsed.hasScheme &&
        parsed.scheme == 'https' &&
        parsed.host.isNotEmpty;
  }
}
