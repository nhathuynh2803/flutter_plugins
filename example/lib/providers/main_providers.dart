import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_plugins/features.dart';

// ==========================================
// Platform Version Provider
// ==========================================

final platformVersionProvider = FutureProvider<String>((ref) async {
  try {
    final secureStorage = SecureStorageHelper();
    final version = await secureStorage.getPlatformVersion();
    return version ?? 'Unknown platform version';
  } on PlatformException {
    return 'Failed to get platform version.';
  }
});

// ==========================================
// Quick Actions Provider
// ==========================================

final quickActionsProvider = Provider<QuickActionsHelper>((ref) {
  return QuickActionsHelper();
});

// Quick Actions Stream Provider
final quickActionsStreamProvider = StreamProvider<String>((ref) {
  final quickActions = ref.watch(quickActionsProvider);
  return quickActions.shortcutStream;
});

// Setup shortcuts provider
final setupShortcutsProvider = FutureProvider<void>((ref) async {
  final quickActions = ref.watch(quickActionsProvider);
  final shortcuts = [
    {'type': 'camera', 'title': 'Take Photo', 'icon': 'capture_photo'},
    {'type': 'contacts', 'title': 'View Contacts', 'icon': 'contact'},
    {'type': 'storage', 'title': 'Secure Storage', 'icon': 'bookmark'},
  ];
  await quickActions.setShortcutItems(shortcuts);
});
