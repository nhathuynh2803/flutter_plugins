// ==========================================
// iOS AppDelegate - Quick Actions Handler
// ==========================================
// This file handles iOS app shortcuts (Quick Actions) when user
// long-presses the app icon on home screen.
//
// Flow:
// 1. User long-presses app icon -> system shows shortcuts
// 2. User taps shortcut -> iOS calls AppDelegate methods
// 3. AppDelegate forwards shortcut to Flutter via NotificationCenter
// 4. QuickActionsFeature receives notification and sends to Dart
// 5. Dart handles navigation to appropriate screen

import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

  // ==========================================
  // App Launch Handler
  // ==========================================
  // Called when app starts. Handles shortcuts pressed when app is closed.
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register all Flutter plugins first
    GeneratedPluginRegistrant.register(with: self)

    // Check if app was launched by tapping a shortcut (app was closed)
    if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem]
      as? UIApplicationShortcutItem
    {
      // IMPORTANT: Delay shortcut handling to ensure:
      // - Flutter engine is fully initialized
      // - All plugins (including QuickActionsFeature) are registered
      // - Event channels are ready to receive data
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.handleShortcutItem(shortcutItem)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ==========================================
  // Shortcut Handler (App Running/Background)
  // ==========================================
  // Called when user taps shortcut while app is running or in background
  override func application(
    _ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    // Handle the shortcut immediately since app is already running
    handleShortcutItem(shortcutItem)
    // Tell iOS we successfully handled the shortcut
    completionHandler(true)
  }

  // ==========================================
  // Shortcut Processing Logic
  // ==========================================
  // Processes shortcut and forwards to Flutter via NotificationCenter
  private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
    print("AppDelegate: Handling shortcut item: \(shortcutItem.type)")

    // Add longer delay to ensure Flutter engine and UI are fully ready
    // This prevents the issue where navigation requires an additional tap
    let delayTime = DispatchTime.now() + 2.0
    DispatchQueue.main.asyncAfter(deadline: delayTime) {
      // Send shortcut info to QuickActionsFeature via NotificationCenter
      // This is a decoupled approach that doesn't require direct plugin references
      print("AppDelegate: Posting notification for shortcut: \(shortcutItem.type)")
      NotificationCenter.default.post(
        name: NSNotification.Name("QuickActionPressed"),
        object: shortcutItem.type
      )
    }
  }
}
