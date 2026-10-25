import Flutter
import UIKit
import UserNotifications

// Canal «kaeli_ui/badge» (0.10.0, KaeliBadge en lib/src/badge.dart): el número del ícono = avisos sin leer de la app
// (0 lo quita) y quitar del centro de notificaciones las que ya se vieron.
public class KaeliUiPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "kaeli_ui/badge", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(KaeliUiPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "set":
      let count = max(0, (call.arguments as? [String: Any])?["count"] as? Int ?? 0)
      if #available(iOS 16.0, *) {
        UNUserNotificationCenter.current().setBadgeCount(count) { _ in result(nil) }
      } else {
        UIApplication.shared.applicationIconBadgeNumber = count
        result(nil)
      }
    case "clearDelivered":
      UNUserNotificationCenter.current().removeAllDeliveredNotifications()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
