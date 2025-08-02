import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_plugins/features/camera/camera_helper.dart';

// ==========================================
// Camera State
// ==========================================

class CameraState {
  final String result;
  final String? imagePath;
  final bool isLoading;
  final String? error;

  const CameraState({
    this.result = '',
    this.imagePath,
    this.isLoading = false,
    this.error,
  });

  CameraState copyWith({
    String? result,
    String? imagePath,
    bool? isLoading,
    String? error,
    bool clearImagePath = false,
  }) {
    return CameraState(
      result: result ?? this.result,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ==========================================
// Camera Notifier
// ==========================================

class CameraNotifier extends StateNotifier<CameraState> {
  final CameraHelper _camera;

  CameraNotifier(this._camera) : super(const CameraState());

  Future<void> takePicture() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final imagePath = await _camera.takePicture();
      state = state.copyWith(
        isLoading: false,
        imagePath: imagePath,
        result: imagePath != null
            ? 'Picture taken successfully: $imagePath'
            : 'Failed to take picture',
      );
    } on PlatformException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to take picture: ${e.message}',
        result: 'Failed to take picture: ${e.message}',
        clearImagePath: true,
      );
    }
  }

  Future<void> pickFromGallery() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final imagePath = await _camera.pickImageFromGallery();
      state = state.copyWith(
        isLoading: false,
        imagePath: imagePath,
        result: imagePath != null
            ? 'Image picked successfully: $imagePath'
            : 'Failed to pick image',
      );
    } on PlatformException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to pick image: ${e.message}',
        result: 'Failed to pick image: ${e.message}',
        clearImagePath: true,
      );
    }
  }

  Future<void> checkCameraAvailability() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final hasCamera = await _camera.hasCamera();
      state = state.copyWith(
        isLoading: false,
        result: hasCamera
            ? 'Camera is available on this device'
            : 'No camera available on this device',
      );
    } on PlatformException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to check camera: ${e.message}',
        result: 'Failed to check camera: ${e.message}',
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

final cameraHelperProvider = Provider<CameraHelper>((ref) {
  return CameraHelper();
});

final cameraProvider = StateNotifierProvider<CameraNotifier, CameraState>((
  ref,
) {
  final camera = ref.watch(cameraHelperProvider);
  return CameraNotifier(camera);
});
