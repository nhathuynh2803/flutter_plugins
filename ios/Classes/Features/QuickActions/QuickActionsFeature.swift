// =====================================================
// iOS Quick Actions Feature - Native Implementation
// =====================================================
// This file implements iOS app shortcuts (Quick Actions) functionality.
// It provides a bridge between iOS native shortcuts and Flutter Dart code.
//
// Architecture:
// 1. Flutter calls methods to create/manage shortcuts
// 2. iOS shows shortcuts when user long-presses app icon
// 3. When shortcut is tapped, AppDelegate receives the event
// 4. AppDelegate forwards via NotificationCenter to this class
// 5. This class sends shortcut data to Flutter via EventChannel
// 6. Flutter Dart code handles navigation
//
// Method Channels:
// - secure_storage_helper/quick_actions: Dart -> Native (create/clear shortcuts)
// - secure_storage_helper/quick_actions_stream: Native -> Dart (shortcut events)

import Flutter
import UIKit

public class QuickActionsFeature: NSObject, FlutterPlugin {

    // ==========================================
    // Properties & State Management
    // ==========================================

    /// Method channel for Dart to call native methods (create/clear shortcuts)
    private var channel: FlutterMethodChannel?

    /// Event channel for sending shortcut events from native to Dart
    private var eventChannel: FlutterEventChannel?

    /// Event sink to send data to Dart (nil until Dart starts listening)
    private var eventSink: FlutterEventSink?

    /// Store shortcut if event sink is not ready yet (app cold start scenario)
    private var pendingShortcutType: String?

    /// Shared instance for AppDelegate to access
    static var shared: QuickActionsFeature?

    // ==========================================
    // Plugin Registration & Setup
    // ==========================================

    /// Called by Flutter engine to register this plugin
    /// Sets up all communication channels with Dart
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Create method channel for Dart -> Native calls
        let channel = FlutterMethodChannel(
            name: "secure_storage_helper/quick_actions",
            binaryMessenger: registrar.messenger())

        // Create event channel for Native -> Dart events
        let eventChannel = FlutterEventChannel(
            name: "secure_storage_helper/quick_actions_stream",
            binaryMessenger: registrar.messenger())

        let instance = QuickActionsFeature()
        instance.channel = channel
        instance.eventChannel = eventChannel

        // Register handlers
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)

        // Store reference for AppDelegate to access
        QuickActionsFeature.shared = instance

        // Listen for shortcut notifications from AppDelegate
        // This decouples AppDelegate from direct plugin access
        NotificationCenter.default.addObserver(
            instance,
            selector: #selector(instance.handleQuickActionNotification(_:)),
            name: NSNotification.Name("QuickActionPressed"),
            object: nil
        )
    }

    // ==========================================
    // Shortcut Event Handling from AppDelegate
    // ==========================================

    /// Receives shortcut notifications from AppDelegate via NotificationCenter
    /// Forwards shortcut events to Flutter Dart code
    @objc private func handleQuickActionNotification(_ notification: Notification) {
        guard let shortcutType = notification.object as? String else { return }

        print("QuickActionsFeature: Received notification for shortcut: \(shortcutType)")

        // Always store as pending first to ensure it's not lost
        pendingShortcutType = shortcutType

        // If Flutter is listening (eventSink ready), send immediately
        if let sink = eventSink {
            print("QuickActionsFeature: Sending shortcut to Flutter immediately: \(shortcutType)")

            // Add small delay to ensure Flutter UI is ready for navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                sink(shortcutType)
                self.pendingShortcutType = nil  // Clear after sending
            }
        } else {
            // Flutter not ready yet (cold start), keep stored for later
            print("QuickActionsFeature: EventSink not ready, shortcut stored: \(shortcutType)")
        }
    }

    /// Static method for external access (if needed)
    public static func handleShortcut(_ shortcutType: String) {
        print("QuickActionsFeature: Static handleShortcut called with: \(shortcutType)")
        if let instance = shared {
            instance.handleShortcutAction(shortcutType)
        } else {
            print("QuickActionsFeature: No shared instance available")
        }
    }

    // ==========================================
    // Flutter Method Call Handler
    // ==========================================

    /// Handles method calls from Flutter Dart code
    /// Supported methods: setShortcutItems, clearShortcutItems
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setShortcutItems":
            handleSetShortcutItems(call, result: result)
        case "clearShortcutItems":
            handleClearShortcutItems(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // ==========================================
    // Shortcut Management Methods
    // ==========================================

    /// Creates iOS app shortcuts from Flutter data
    /// Called when Flutter calls setShortcutItems method
    private func handleSetShortcutItems(_ call: FlutterMethodCall, result: @escaping FlutterResult)
    {
        // Validate arguments from Flutter
        guard let args = call.arguments as? [String: Any],
            let items = args["items"] as? [[String: Any]]
        else {
            result(
                FlutterError(
                    code: "INVALID_ARGUMENTS", message: "Invalid arguments for setShortcutItems",
                    details: nil))
            return
        }

        // iOS 9.0+ required for app shortcuts
        if #available(iOS 9.0, *) {
            var shortcutItems: [UIApplicationShortcutItem] = []

            // Process each shortcut item from Flutter
            for item in items {
                guard let type = item["type"] as? String,
                    let title = item["title"] as? String
                else {
                    continue
                }

                let subtitle = item["subtitle"] as? String
                let icon = item["icon"] as? String

                // Map icon names to iOS system icons
                var shortcutIcon: UIApplicationShortcutIcon?
                if let iconName = icon {
                    // Map common icon names to iOS system icons
                    switch iconName {
                    case "search":
                        shortcutIcon = UIApplicationShortcutIcon(type: .search)
                    case "compose":
                        shortcutIcon = UIApplicationShortcutIcon(type: .compose)
                    case "play":
                        shortcutIcon = UIApplicationShortcutIcon(type: .play)
                    case "pause":
                        shortcutIcon = UIApplicationShortcutIcon(type: .pause)
                    case "add":
                        shortcutIcon = UIApplicationShortcutIcon(type: .add)
                    case "location":
                        shortcutIcon = UIApplicationShortcutIcon(type: .location)
                    case "share":
                        shortcutIcon = UIApplicationShortcutIcon(type: .share)
                    case "prohibit":
                        shortcutIcon = UIApplicationShortcutIcon(type: .prohibit)
                    case "contact":
                        shortcutIcon = UIApplicationShortcutIcon(type: .contact)
                    case "home":
                        shortcutIcon = UIApplicationShortcutIcon(type: .home)
                    case "mark_location":
                        shortcutIcon = UIApplicationShortcutIcon(type: .markLocation)
                    case "favorite":
                        shortcutIcon = UIApplicationShortcutIcon(type: .favorite)
                    case "love":
                        shortcutIcon = UIApplicationShortcutIcon(type: .love)
                    case "cloud":
                        shortcutIcon = UIApplicationShortcutIcon(type: .cloud)
                    case "invitation":
                        shortcutIcon = UIApplicationShortcutIcon(type: .invitation)
                    case "confirmation":
                        shortcutIcon = UIApplicationShortcutIcon(type: .confirmation)
                    case "mail":
                        shortcutIcon = UIApplicationShortcutIcon(type: .mail)
                    case "message":
                        shortcutIcon = UIApplicationShortcutIcon(type: .message)
                    case "date":
                        shortcutIcon = UIApplicationShortcutIcon(type: .date)
                    case "time":
                        shortcutIcon = UIApplicationShortcutIcon(type: .time)
                    case "capture_photo":
                        shortcutIcon = UIApplicationShortcutIcon(type: .capturePhoto)
                    case "capture_video":
                        shortcutIcon = UIApplicationShortcutIcon(type: .captureVideo)
                    case "task":
                        shortcutIcon = UIApplicationShortcutIcon(type: .task)
                    case "task_completed":
                        shortcutIcon = UIApplicationShortcutIcon(type: .taskCompleted)
                    case "alarm":
                        shortcutIcon = UIApplicationShortcutIcon(type: .alarm)
                    case "bookmark":
                        shortcutIcon = UIApplicationShortcutIcon(type: .bookmark)
                    case "shuffle":
                        shortcutIcon = UIApplicationShortcutIcon(type: .shuffle)
                    case "audio":
                        shortcutIcon = UIApplicationShortcutIcon(type: .audio)
                    case "update":
                        shortcutIcon = UIApplicationShortcutIcon(type: .update)
                    default:
                        shortcutIcon = nil
                    }
                }

                // Create iOS shortcut item with all configured properties
                let shortcutItem = UIApplicationShortcutItem(
                    type: type,
                    localizedTitle: title,
                    localizedSubtitle: subtitle,
                    icon: shortcutIcon,
                    userInfo: nil
                )

                shortcutItems.append(shortcutItem)
            }

            // Apply shortcuts to iOS system
            UIApplication.shared.shortcutItems = shortcutItems
            result(nil)
        } else {
            result(
                FlutterError(
                    code: "UNSUPPORTED_VERSION",
                    message: "Quick actions are only supported on iOS 9.0 and above", details: nil))
        }
    }

    /// Removes all iOS app shortcuts
    /// Called when Flutter calls clearShortcutItems method
    private func handleClearShortcutItems(result: @escaping FlutterResult) {
        if #available(iOS 9.0, *) {
            UIApplication.shared.shortcutItems = []
            result(nil)
        } else {
            result(
                FlutterError(
                    code: "UNSUPPORTED_VERSION",
                    message: "Quick actions are only supported on iOS 9.0 and above", details: nil))
        }
    }
}

// ==========================================
// Event Channel Stream Handler
// ==========================================
// Handles Flutter listening for shortcut events via EventChannel

extension QuickActionsFeature: FlutterStreamHandler {

    /// Called when Flutter starts listening for shortcut events
    /// Sets up event sink and sends any pending shortcuts
    public func onListen(
        withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        print("QuickActionsFeature: EventSink connected")
        self.eventSink = events

        // Send any pending shortcut that was triggered before Flutter was ready
        if let pending = pendingShortcutType {
            print("QuickActionsFeature: Sending pending shortcut: \(pending)")
            events(pending)
            pendingShortcutType = nil
        }

        return nil
    }

    /// Called when Flutter stops listening for shortcut events
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        print("QuickActionsFeature: EventSink disconnected")
        self.eventSink = nil
        return nil
    }

    /// Internal method to handle shortcut actions
    /// Sends shortcut type to Flutter or stores if Flutter not ready
    public func handleShortcutAction(_ shortcutType: String) {
        print("QuickActionsFeature: handleShortcutAction called with: \(shortcutType)")

        if let sink = eventSink {
            // Flutter is listening, send immediately
            print("QuickActionsFeature: Sending to eventSink: \(shortcutType)")
            sink(shortcutType)
        } else {
            // Flutter not ready, store for later
            print(
                "QuickActionsFeature: No eventSink available, storing as pending: \(shortcutType)")
            pendingShortcutType = shortcutType
        }
    }
}
