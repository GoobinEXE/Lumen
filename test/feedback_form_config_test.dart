import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/settings/service/feedback_form_config.dart';

void main() {
  test('destino de feedback é https configurado (só maintainers trocam)', () {
    expect(FeedbackFormConfig.isConfigured, isTrue);
    expect(FeedbackFormConfig.uri.scheme, 'https');
    expect(FeedbackFormConfig.uri.host, isNotEmpty);
    // URL não vaza pra l10n / UI — só existe na config interna.
    expect(FeedbackFormConfig.url, startsWith('https://forms.gle/'));
  });
}
