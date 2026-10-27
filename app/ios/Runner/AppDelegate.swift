import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var exportShareInProgress = false
  private var exportGeneration: UInt64 = 0
  private var exportDirectory: URL?
  private var exportPendingResult: FlutterResult?

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
      DispatchQueue.main.async {
        guard let self = self else {
          result(FlutterError(code: "share_failed", message: "Sharing is unavailable.", details: nil))
          return
        }
        if call.method == "cancelShare" || call.method == "discardExport" {
          self.cancelShare(result: result)
          return
        }
        guard call.method == "shareZip" else {
          result(FlutterMethodNotImplemented)
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
      if (call.method == "scheduleTimerReminder" || call.method == "scheduleMonthlyReviewReminder"),
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
        var calendar = Calendar.current
        if let timezone = args["timezone"] as? String,
           let zone = TimeZone(identifier: timezone) {
          calendar.timeZone = zone
        }
        let trigger = UNCalendarNotificationTrigger(
          dateMatching: calendar.dateComponents(
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
    cleanupStaleExportDirectories()
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
    guard !exportShareInProgress, exportDirectory == nil, let presenter = exportPresenter(),
          !(presenter is UIActivityViewController), !presenter.isBeingDismissed,
          !presenter.isBeingPresented else {
      result(FlutterError(code: "share_failed", message: "Sharing is unavailable or already open.", details: nil))
      return
    }
    exportShareInProgress = true
    exportGeneration &+= 1
    let generation = exportGeneration
    exportPendingResult = result
    let manager = FileManager.default
    let root = manager.temporaryDirectory.appendingPathComponent("gramtree-exports", isDirectory: true)
    let directory = root.appendingPathComponent(UUID().uuidString, isDirectory: true)
    exportDirectory = directory
    DispatchQueue.global(qos: .userInitiated).async {
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
          guard self.exportShareInProgress, self.exportGeneration == generation else {
            try? manager.removeItem(at: directory)
            return
          }
          guard let presenter = self.exportPresenter(),
                !(presenter is UIActivityViewController), !presenter.isBeingDismissed,
                !presenter.isBeingPresented else {
            try? manager.removeItem(at: directory)
            self.exportShareInProgress = false
            self.exportDirectory = nil
            self.exportPendingResult = nil
            result(FlutterError(code: "share_failed", message: "Sharing is unavailable.", details: nil))
            return
          }
          let share = UIActivityViewController(activityItems: [file], applicationActivities: nil)
          share.completionWithItemsHandler = { _, _, _, _ in
            // Save to Files / the receiving activity has finished consuming the URL.
            try? manager.removeItem(at: directory)
            DispatchQueue.main.async {
              guard self.exportGeneration == generation else { return }
              self.exportShareInProgress = false
              self.exportDirectory = nil
            }
          }
          if let popover = share.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
              x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1
            )
            popover.permittedArrowDirections = []
          }
          self.exportShareInProgress = false
          self.exportDirectory = directory
          let pending = self.exportPendingResult
          self.exportPendingResult = nil
          presenter.present(share, animated: true) { pending?(nil) }
        }
      } catch {
        try? manager.removeItem(at: directory)
        DispatchQueue.main.async {
          self.failExport(generation: generation, message: "Could not prepare ZIP sharing.")
        }
      }
    }
  }

  private func cancelShare(result: @escaping FlutterResult) {
    guard exportShareInProgress || exportDirectory != nil else {
      result(nil)
      return
    }
    exportGeneration &+= 1
    let wasPreparing = exportShareInProgress
    exportShareInProgress = false
    let directory = exportDirectory
    exportDirectory = nil
    let pending = exportPendingResult
    exportPendingResult = nil
    if let directory { try? FileManager.default.removeItem(at: directory) }
    if !wasPreparing { exportPresenter()?.dismiss(animated: true) }
    pending?(FlutterError(code: "share_cancelled", message: "ZIP sharing was cancelled.", details: nil))
    result(nil)
  }

  private func failExport(generation: UInt64, message: String) {
    guard exportShareInProgress, exportGeneration == generation else { return }
    exportShareInProgress = false
    exportDirectory = nil
    let pending = exportPendingResult
    exportPendingResult = nil
    pending?(FlutterError(code: "share_failed", message: message, details: nil))
  }

  private func cleanupStaleExportDirectories() {
    let manager = FileManager.default
    let root = manager.temporaryDirectory.appendingPathComponent("gramtree-exports", isDirectory: true)
    let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
    let directories = (try? manager.contentsOfDirectory(
      at: root, includingPropertiesForKeys: [.creationDateKey, .isDirectoryKey], options: [.skipsHiddenFiles]
    )) ?? []
    for directory in directories.prefix(20) {
      guard UUID(uuidString: directory.lastPathComponent) != nil,
            let values = try? directory.resourceValues(forKeys: [.creationDateKey, .isDirectoryKey]),
            values.isDirectory == true, let created = values.creationDate, created < cutoff else { continue }
      try? manager.removeItem(at: directory)
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
