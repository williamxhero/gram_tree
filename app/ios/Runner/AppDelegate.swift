import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "app.gramtree/device_capabilities",
      binaryMessenger: engineBridge.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "scheduleTimerReminder",
         let args = call.arguments as? [String: Any],
         let id = args["id"] as? String,
         let dueAtMillis = args["dueAtMillis"] as? Int,
         let title = args["title"] as? String,
         let body = args["body"] as? String {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let date = Date(timeIntervalSince1970: Double(dueAtMillis) / 1000)
        let trigger = UNCalendarNotificationTrigger(
          dateMatching: Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date
          ), repeats: false
        )
        UNUserNotificationCenter.current().add(
          UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        ) { error in
          if let error = error {
            result(FlutterError(code: "notification_schedule_failed", message: error.localizedDescription, details: nil))
          } else {
            result(nil)
          }
        }
        return
      }
      if call.method == "cancelTimerReminder",
         let args = call.arguments as? [String: Any],
         let id = args["id"] as? String {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        result(nil)
        return
      }
      guard call.method == "setKeepScreenOn", let enabled = call.arguments as? Bool else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.main.async { UIApplication.shared.isIdleTimerDisabled = enabled }
      result(nil)
    }
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
  }
}
