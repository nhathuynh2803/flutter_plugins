import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_plugins/features/quick_actions/quick_actions_helper.dart';
import 'dart:async';

// ==========================================
// Quick Actions State
// ==========================================

class QuickActionsState {
  final String result;
  final String lastShortcutAction;
  final bool isLoading;
  final String? error;

  const QuickActionsState({
    this.result = '',
    this.lastShortcutAction = '',
    this.isLoading = false,
    this.error,
  });

  QuickActionsState copyWith({
    String? result,
    String? lastShortcutAction,
    bool? isLoading,
    String? error,
  }) {
    return QuickActionsState(
      result: result ?? this.result,
      lastShortcutAction: lastShortcutAction ?? this.lastShortcutAction,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ==========================================
// Quick Actions Notifier
// ==========================================

class QuickActionsNotifier extends StateNotifier<QuickActionsState> {
  final QuickActionsHelper _quickActions;
  StreamSubscription<String>? _shortcutSubscription;

  QuickActionsNotifier(this._quickActions) : super(const QuickActionsState()) {
    _initShortcutListener();
  }

  void _initShortcutListener() {
    _shortcutSubscription = _quickActions.shortcutStream.listen(
      (action) {
        state = state.copyWith(
          lastShortcutAction: action,
          result: 'Shortcut pressed: $action',
        );
      },
      onError: (error) {
        state = state.copyWith(error: 'Shortcut stream error: $error');
      },
    );
  }

  Future<void> setShortcuts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final shortcuts = [
        {'type': 'camera', 'title': 'Take Photo', 'icon': 'capture_photo'},
        {'type': 'contacts', 'title': 'View Contacts', 'icon': 'contact'},
        {'type': 'storage', 'title': 'Secure Storage', 'icon': 'bookmark'},
      ];

      await _quickActions.setShortcutItems(shortcuts);
      state = state.copyWith(
        isLoading: false,
        result:
            'Shortcuts set successfully!\nGo to home screen and long press the app icon to test.',
      );
    } on PlatformException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to set shortcuts: ${e.message}',
        result: 'Failed to set shortcuts: ${e.message}',
      );
    }
  }

  Future<void> clearShortcuts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _quickActions.clearShortcutItems();
      state = state.copyWith(
        isLoading: false,
        result: 'Shortcuts cleared successfully',
        lastShortcutAction: '',
      );
    } on PlatformException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to clear shortcuts: ${e.message}',
        result: 'Failed to clear shortcuts: ${e.message}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _shortcutSubscription?.cancel();
    super.dispose();
  }
}

// ==========================================
// Providers
// ==========================================

final quickActionsHelperProvider = Provider<QuickActionsHelper>((ref) {
  return QuickActionsHelper();
});

final quickActionsProvider =
    StateNotifierProvider<QuickActionsNotifier, QuickActionsState>((ref) {
      final quickActions = ref.watch(quickActionsHelperProvider);
      return QuickActionsNotifier(quickActions);
    });
