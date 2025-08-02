import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_plugins/features/camera/camera_helper.dart';
import 'package:flutter_plugins_example/providers/camera_provider.dart';

import 'camera_provider_test.mocks.dart';

@GenerateMocks([CameraHelper])
void main() {
  late MockCameraHelper mockCamera;
  late ProviderContainer container;

  setUp(() {
    mockCamera = MockCameraHelper();
    container = ProviderContainer(
      overrides: [cameraHelperProvider.overrideWithValue(mockCamera)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('CameraProvider', () {
    test('initial state is correct', () {
      final state = container.read(cameraProvider);

      expect(state.result, isEmpty);
      expect(state.imagePath, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('takePicture takes picture successfully', () async {
      when(
        mockCamera.takePicture(),
      ).thenAnswer((_) async => '/path/to/image.jpg');

      final notifier = container.read(cameraProvider.notifier);

      await notifier.takePicture();

      final state = container.read(cameraProvider);
      expect(state.result, 'Picture taken successfully: /path/to/image.jpg');
      expect(state.imagePath, '/path/to/image.jpg');
      expect(state.isLoading, false);
      expect(state.error, isNull);
      verify(mockCamera.takePicture()).called(1);
    });

    test('takePicture handles null result', () async {
      when(mockCamera.takePicture()).thenAnswer((_) async => null);

      final notifier = container.read(cameraProvider.notifier);

      await notifier.takePicture();

      final state = container.read(cameraProvider);
      expect(state.result, 'Failed to take picture');
      expect(state.imagePath, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('takePicture handles PlatformException', () async {
      when(
        mockCamera.takePicture(),
      ).thenThrow(PlatformException(code: 'ERROR', message: 'Camera error'));

      final notifier = container.read(cameraProvider.notifier);

      await notifier.takePicture();

      final state = container.read(cameraProvider);
      expect(state.result, 'Failed to take picture: Camera error');
      expect(state.error, 'Failed to take picture: Camera error');
      expect(state.imagePath, isNull);
      expect(state.isLoading, false);
    });

    test('pickFromGallery picks image successfully', () async {
      when(
        mockCamera.pickImageFromGallery(),
      ).thenAnswer((_) async => '/path/to/gallery.jpg');

      final notifier = container.read(cameraProvider.notifier);

      await notifier.pickFromGallery();

      final state = container.read(cameraProvider);
      expect(state.result, 'Image picked successfully: /path/to/gallery.jpg');
      expect(state.imagePath, '/path/to/gallery.jpg');
      expect(state.isLoading, false);
      expect(state.error, isNull);
      verify(mockCamera.pickImageFromGallery()).called(1);
    });

    test('pickFromGallery handles null result', () async {
      when(mockCamera.pickImageFromGallery()).thenAnswer((_) async => null);

      final notifier = container.read(cameraProvider.notifier);

      await notifier.pickFromGallery();

      final state = container.read(cameraProvider);
      expect(state.result, 'Failed to pick image');
      expect(state.imagePath, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('checkCameraAvailability checks camera successfully', () async {
      when(mockCamera.hasCamera()).thenAnswer((_) async => true);

      final notifier = container.read(cameraProvider.notifier);

      await notifier.checkCameraAvailability();

      final state = container.read(cameraProvider);
      expect(state.result, 'Camera is available on this device');
      expect(state.isLoading, false);
      expect(state.error, isNull);
      verify(mockCamera.hasCamera()).called(1);
    });

    test('checkCameraAvailability handles no camera', () async {
      when(mockCamera.hasCamera()).thenAnswer((_) async => false);

      final notifier = container.read(cameraProvider.notifier);

      await notifier.checkCameraAvailability();

      final state = container.read(cameraProvider);
      expect(state.result, 'No camera available on this device');
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('clearError clears error', () async {
      // First cause an error
      when(
        mockCamera.takePicture(),
      ).thenThrow(PlatformException(code: 'ERROR', message: 'Test error'));

      final notifier = container.read(cameraProvider.notifier);
      await notifier.takePicture();

      final stateWithError = container.read(cameraProvider);
      expect(stateWithError.error, isNotNull);

      // Clear the error
      notifier.clearError();

      final stateAfterClear = container.read(cameraProvider);
      expect(stateAfterClear.error, isNull);
    });
  });
}
