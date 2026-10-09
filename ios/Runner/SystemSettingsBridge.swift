import Flutter
import UIKit

/// Abre Ajustes do iPhone na ficha do Lumen (idioma, notificações, permissões).
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
}
