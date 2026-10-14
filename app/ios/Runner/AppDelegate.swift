import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var exportShareInProgress = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let exportChannel = FlutterMethodChannel(
      name: "app.gramtree/export_file", binaryMessenger: engineBridge.binaryMessenger
    )
    exportChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "shareZip" else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.main.async {
        guard let self = self else {
          result(FlutterError(code: "share_failed", message: "Sharing is unavailable.", details: nil))
          return
        }
        self.shareZip(call.arguments, result: result)
      }
    }
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

  private func shareZip(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any],
          let bytes = args["bytes"] as? FlutterStandardTypedData, !bytes.data.isEmpty,
          let filename = args["filename"] as? String,
          filename.range(
            of: #"\A[\p{L}\p{N}][\p{L}\p{N}._ -]{0,123}\.[zZ][iI][pP]\z"#,
            options: .regularExpression
          ) != nil else {
      result(FlutterError(code: "invalid_arguments", message: "Expected ZIP bytes and a safe ZIP basename.", details: nil))
      return
    }
    guard !exportShareInProgress, let presenter = exportPresenter(),
          !(presenter is UIActivityViewController), !presenter.isBeingDismissed,
          !presenter.isBeingPresented else {
      result(FlutterError(code: "share_failed", message: "Sharing is unavailable or already open.", details: nil))
      return
    }
    exportShareInProgress = true
    DispatchQueue.global(qos: .userInitiated).async {
      let manager = FileManager.default
      let root = manager.temporaryDirectory.appendingPathComponent("gramtree-exports", isDirectory: true)
      let directory = root.appendingPathComponent(UUID().uuidString, isDirectory: true)
      let file = directory.appendingPathComponent(filename)
      do {
        try manager.createDirectory(at: root, withIntermediateDirectories: true)
        // Crash leftovers only: a recent, still-active share is never removed.
        let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
        let oldDirectories = (try? manager.contentsOfDirectory(
          at: root, includingPropertiesForKeys: [.creationDateKey, .isDirectoryKey],
          options: [.skipsHiddenFiles]
        )) ?? []
        let expired = oldDirectories.filter { old in
          guard UUID(uuidString: old.lastPathComponent) != nil,
                let values = try? old.resourceValues(forKeys: [.creationDateKey, .isDirectoryKey]),
                values.isDirectory == true, let created = values.creationDate else { return false }
          return created < cutoff
        }.sorted { $0.lastPathComponent < $1.lastPathComponent }
        for old in expired.prefix(20) { try? manager.removeItem(at: old) }
        try manager.createDirectory(at: directory, withIntermediateDirectories: false)
        try bytes.data.write(to: file, options: .atomic)
        DispatchQueue.main.async {
          guard let presenter = self.exportPresenter(),
                !(presenter is UIActivityViewController), !presenter.isBeingDismissed,
                !presenter.isBeingPresented else {
            try? manager.removeItem(at: directory)
            self.exportShareInProgress = false
            result(FlutterError(code: "share_failed", message: "Sharing is unavailable.", details: nil))
            return
          }
          let share = UIActivityViewController(activityItems: [file], applicationActivities: nil)
          share.completionWithItemsHandler = { _, _, _, _ in
            // Save to Files / the receiving activity has finished consuming the URL.
            try? manager.removeItem(at: directory)
            self.exportShareInProgress = false
          }
          if let popover = share.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
              x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1
            )
            popover.permittedArrowDirections = []
          }
          presenter.present(share, animated: true) { result(nil) }
        }
      } catch {
        try? manager.removeItem(at: directory)
        DispatchQueue.main.async {
          self.exportShareInProgress = false
          result(FlutterError(code: "share_failed", message: "Could not prepare ZIP sharing.", details: nil))
        }
      }
    }
  }

  private func exportPresenter() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }
    guard let window = scenes.flatMap({ $0.windows }).first(where: { $0.isKeyWindow }),
          var presenter = window.rootViewController else { return nil }
    while true {
      if let presented = presenter.presentedViewController {
        presenter = presented
      } else if let navigation = presenter as? UINavigationController,
                let visible = navigation.visibleViewController {
        presenter = visible
      } else if let tabs = presenter as? UITabBarController,
                let selected = tabs.selectedViewController {
        presenter = selected
      } else {
        return presenter.viewIfLoaded?.window != nil ? presenter : nil
      }
    }
  }
}
