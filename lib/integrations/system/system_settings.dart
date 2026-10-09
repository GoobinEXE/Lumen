import 'package:flutter/services.dart';

/// Destinos das configurações do aparelho que o Lumen pode abrir.
enum SystemSettingsTarget {
  /// Ficha do app (idioma, notificações e permissões no iOS).
  app,

  /// Idioma do app (Android 13+; nos demais cai na ficha do app).
  locale,

  /// Notificações do app.
  notifications,

  /// Health Connect (Android); Play Store do HC se o app não estiver instalado.
  healthConnect,
}

/// Abre telas do sistema. A UI chama só esta API — sem MethodChannel na tela.
class SystemSettings {
  SystemSettings({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'dev.prism.lumen/system_settings';

  final MethodChannel _channel;

  Future<bool> open(SystemSettingsTarget target) async {
    try {
      final ok = await _channel.invokeMethod<bool>('open', {
        'target': target.name,
      });
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
