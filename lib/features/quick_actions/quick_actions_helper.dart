// =====================================================
// Dart Quick Actions Helper - Public API
// =====================================================
// This file provides the main public API for Quick Actions functionality.
// It's a simple wrapper around the platform interface to provide a clean API.
//
// Usage:
// 1. Create shortcuts: helper.setShortcutItems([...])
// 2. Listen for shortcuts: helper.shortcutStream.listen(...)
// 3. Clear shortcuts: helper.clearShortcutItems()
//
// Data Flow:
// Flutter App -> QuickActionsHelper -> Platform Interface -> Method Channel -> Native Code

import 'quick_actions_platform_interface.dart';

/// Main helper class for Quick Actions functionality
/// Provides simplified access to app shortcuts features
class QuickActionsHelper {
  // ==========================================
  // Shortcut Management
  // ==========================================

  /// Creates app shortcuts that appear when user long-presses app icon
  ///
  /// [shortcuts] - List of shortcut definitions with:
  ///   - 'type': Unique identifier for the shortcut
  ///   - 'title': Short title shown in the shortcut
  ///   - 'subtitle': (Optional) Longer description
  ///   - 'icon': (Optional) Icon name for the shortcut
  ///
  /// Example:
  /// ```dart
  /// await helper.setShortcutItems([
  ///   {
  ///     'type': 'camera',
  ///     'title': 'Take Photo',
  ///     'subtitle': 'Quickly capture a photo',
  ///     'icon': 'camera'
  ///   }
  /// ]);
  /// ```
  Future<void> setShortcutItems(List<Map<String, String>> shortcuts) {
    return QuickActionsPlatform.instance.setShortcutItems(shortcuts);
  }

  /// Removes all app shortcuts from the system
  /// Useful for cleanup or when shortcuts are no longer needed
  Future<void> clearShortcutItems() {
    return QuickActionsPlatform.instance.clearShortcutItems();
  }

  // ==========================================
  // Shortcut Event Stream
  // ==========================================

  /// Stream that emits shortcut events when user taps a shortcut
  /// Listen to this stream to handle shortcut navigation
  ///
  /// The stream emits the 'type' value of the tapped shortcut
  ///
  /// Example:
  /// ```dart
  /// helper.shortcutStream.listen((shortcutType) {
  ///   switch (shortcutType) {
  ///     case 'camera':
  ///       Navigator.pushNamed(context, '/camera');
  ///       break;
  ///     case 'contacts':
  ///       Navigator.pushNamed(context, '/contacts');
  ///       break;
  ///   }
  /// });
  /// ```
  Stream<String> get shortcutStream {
    return QuickActionsPlatform.instance.shortcutStream;
  }
}
