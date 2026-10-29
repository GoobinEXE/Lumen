import Flutter
import UIKit

/// Abre Ajustes do iPhone na ficha do Lumen (idioma, notificações, permissões).
/// Também expõe flags de acessibilidade legíveis (Reduzir Transparência).
final class SystemSettingsBridge: NSObject {
  static let channelName = "dev.prism.lumen/system_settings"

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "open":
        openAppSettings(result: result)
      case "accessibilityFlags":
        result(accessibilityFlags())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func openAppSettings(result: @escaping FlutterResult) {
    guard let url = URL(string: UIApplication.openSettingsURLString) else {
      result(false)
      return
    }
    UIApplication.shared.open(url, options: [:]) { ok in
      result(ok)
    }
  }

  /// Sem API pública para Liquid Glass Transparente/Colorido (iOS 26.1).
  private static func accessibilityFlags() -> [String: Any] {
    [
      "reduceTransparency": UIAccessibility.isReduceTransparencyEnabled
    ]
  }
}
