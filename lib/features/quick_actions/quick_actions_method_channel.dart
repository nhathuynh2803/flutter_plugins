// =====================================================
// Dart Quick Actions Method Channel Implementation
// =====================================================
// This file implements the platform interface using Flutter's MethodChannel
// and EventChannel to communicate with native iOS/Android code.
//
// Architecture:
// - MethodChannel: Dart -> Native (create/clear shortcuts)
// - EventChannel: Native -> Dart (shortcut events)
//
// Channel Names (must match native implementations):
// - secure_storage_helper/quick_actions: Method channel
// - secure_storage_helper/quick_actions_stream: Event channel

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'quick_actions_platform_interface.dart';

/// Method channel implementation of Quick Actions platform interface
/// Handles communication with native iOS/Android code via Flutter channels
class MethodChannelQuickActions extends QuickActionsPlatform {
  // ==========================================
  // Communication Channels
  // ==========================================

  /// Method channel for calling native methods (create/clear shortcuts)
  /// Channel name must match iOS/Android implementations exactly
  @visibleForTesting
  final methodChannel = const MethodChannel(
    'secure_storage_helper/quick_actions',
  );

  /// Event channel for receiving shortcut events from native code
  /// Channel name must match iOS/Android implementations exactly
  @visibleForTesting
  final eventChannel = const EventChannel(
    'secure_storage_helper/quick_actions_stream',
  );

  // ==========================================
  // Platform Interface Implementation
  // ==========================================

  /// Creates app shortcuts by calling native setShortcutItems method
  /// Sends shortcut data to native code for platform-specific processing
  @override
  Future<void> setShortcutItems(List<Map<String, String>> shortcuts) async {
    await methodChannel.invokeMethod<void>('setShortcutItems', {
      'items': shortcuts,
    });
  }

  /// Removes all app shortcuts by calling native clearShortcutItems method
  @override
  Future<void> clearShortcutItems() async {
    await methodChannel.invokeMethod<void>('clearShortcutItems');
  }

  /// Returns stream of shortcut events from native code
  /// Native code sends shortcut type when user taps a shortcut
  @override
  Stream<String> get shortcutStream {
    return eventChannel.receiveBroadcastStream().cast<String>();
  }
}
