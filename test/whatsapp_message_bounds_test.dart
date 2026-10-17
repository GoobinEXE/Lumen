import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/therapist_export/service/whatsapp_text_formatter.dart';

void main() {
  group('WhatsappTextFormatter.clipMessage', () {
    test('texto no teto permanece inteiro', () {
      final exact = 'a' * kWhatsAppMessageMaxChars;
      expect(WhatsappTextFormatter.clipMessage(exact), exact);
      expect(WhatsappTextFormatter.clipMessage(''), isEmpty);
    });

    test('um caractere além do teto vira reticência dentro do limite', () {
      final over = 'b' * (kWhatsAppMessageMaxChars + 1);
      final clipped = WhatsappTextFormatter.clipMessage(over);

      expect(clipped.length, kWhatsAppMessageMaxChars);
      expect(clipped.endsWith('…'), isTrue);
      expect(clipped.startsWith('b' * (kWhatsAppMessageMaxChars - 1)), isTrue);
    });
  });

  group('WhatsappTextFormatter.digitsOnlyPhone', () {
    test('telefone formatado fica só com os dígitos', () {
      expect(
        WhatsappTextFormatter.digitsOnlyPhone('+55 (11) 98888-7777'),
        '5511988887777',
      );
      expect(
        WhatsappTextFormatter.digitsOnlyPhone('5511988887777'),
        '5511988887777',
      );
    });

    test('vazio, nulo ou só símbolo não inventa número', () {
      expect(WhatsappTextFormatter.digitsOnlyPhone(null), isEmpty);
      expect(WhatsappTextFormatter.digitsOnlyPhone(''), isEmpty);
      expect(WhatsappTextFormatter.digitsOnlyPhone(' + ( ) - '), isEmpty);
    });
  });
}
