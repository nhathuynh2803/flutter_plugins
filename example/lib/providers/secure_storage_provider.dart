import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_plugins/features/secure_storage/secure_storage_helper.dart';

// ==========================================
// Secure Storage State
// ==========================================

class SecureStorageState {
  final String result;
  final bool isLoading;
  final String? error;

  const SecureStorageState({
    this.result = '',
    this.isLoading = false,
    this.error,
  });

  SecureStorageState copyWith({
    String? result,
    bool? isLoading,
    String? error,
  }) {
    return SecureStorageState(
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ==========================================
// Secure Storage Notifier
// ==========================================

class SecureStorageNotifier extends StateNotifier<SecureStorageState> {
  final SecureStorageHelper _secureStorage;

  SecureStorageNotifier(this._secureStorage)
    : super(const SecureStorageState());

  Future<void> setValue(String key, String value) async {
    if (key.isEmpty || value.isEmpty) {
      state = state.copyWith(error: 'Please enter both key and value');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _secureStorage.setString(key, value);
      state = state.copyWith(
        isLoading: false,
        result: 'Value set successfully for key: $key',
      );
    } on PlatformException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to set value: ${e.message}',
        result: 'Failed to set value: ${e.message}',
      );
    }
  }

  Future<void> getValue(String key) async {
    if (key.isEmpty) {
      state = state.copyWith(error: 'Please enter a key');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final value = await _secureStorage.getString(key);
      state = state.copyWith(
        isLoading: false,
        result: value != null
            ? 'Value for key "$key": $value'
            : 'No value found for key: $key',
      );
    } on PlatformException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get value: ${e.message}',
        result: 'Failed to get value: ${e.message}',
      );
    }
  }

  Future<void> deleteKey(String key) async {
    if (key.isEmpty) {
      state = state.copyWith(error: 'Please enter a key');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _secureStorage.deleteKey(key);
      state = state.copyWith(
        isLoading: false,
        result: 'Key deleted successfully: $key',
      );
    } on PlatformException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete key: ${e.message}',
        result: 'Failed to delete key: ${e.message}',
      );
    }
  }

  Future<void> deleteAll() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _secureStorage.deleteAll();
      state = state.copyWith(
        isLoading: false,
        result: 'All keys deleted successfully',
      );
    } on PlatformException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete all keys: ${e.message}',
        result: 'Failed to delete all keys: ${e.message}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ==========================================
// Providers
// ==========================================

final secureStorageHelperProvider = Provider<SecureStorageHelper>((ref) {
  return SecureStorageHelper();
});

final secureStorageProvider =
    StateNotifierProvider<SecureStorageNotifier, SecureStorageState>((ref) {
      final secureStorage = ref.watch(secureStorageHelperProvider);
      return SecureStorageNotifier(secureStorage);
    });
