import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_plugins_example/features/camera_demo.dart';
import 'package:flutter_plugins_example/providers/camera_provider.dart';

import '../providers/camera_provider_test.mocks.dart';

void main() {
  late MockCameraHelper mockCamera;

  setUp(() {
    mockCamera = MockCameraHelper();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [cameraHelperProvider.overrideWithValue(mockCamera)],
      child: const MaterialApp(home: CameraDemo()),
    );
  }

  group('CameraDemo Widget Tests', () {
    testWidgets('renders all UI elements correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Check for app bar
      expect(find.text('Camera Demo'), findsOneWidget);

      // Check for buttons
      expect(find.text('Take Picture'), findsOneWidget);
      expect(find.text('Pick from Gallery'), findsOneWidget);
      expect(find.text('Check Camera Availability'), findsOneWidget);

      // Check for result section
      expect(find.text('Result:'), findsOneWidget);
      expect(find.text('No result yet'), findsOneWidget);
    });

    testWidgets('take picture button triggers takePicture', (
      WidgetTester tester,
    ) async {
      when(
        mockCamera.takePicture(),
      ).thenAnswer((_) async => '/path/to/image.jpg');

      await tester.pumpWidget(createWidgetUnderTest());

      // Tap take picture button
      await tester.tap(find.text('Take Picture'));
      await tester.pumpAndSettle();

      // Verify mock was called
      verify(mockCamera.takePicture()).called(1);

      // Check result
      expect(
        find.text('Picture taken successfully: /path/to/image.jpg'),
        findsOneWidget,
      );
    });

    testWidgets('pick from gallery button triggers pickFromGallery', (
      WidgetTester tester,
    ) async {
      when(
        mockCamera.pickImageFromGallery(),
      ).thenAnswer((_) async => '/path/to/gallery.jpg');

      await tester.pumpWidget(createWidgetUnderTest());

      // Tap pick from gallery button
      await tester.tap(find.text('Pick from Gallery'));
      await tester.pumpAndSettle();

      // Verify mock was called
      verify(mockCamera.pickImageFromGallery()).called(1);

      // Check result
      expect(
        find.text('Image picked successfully: /path/to/gallery.jpg'),
        findsOneWidget,
      );
    });

    testWidgets(
      'check camera availability button triggers checkCameraAvailability',
      (WidgetTester tester) async {
        when(mockCamera.hasCamera()).thenAnswer((_) async => true);

        await tester.pumpWidget(createWidgetUnderTest());

        // Tap check camera availability button
        await tester.tap(find.text('Check Camera Availability'));
        await tester.pumpAndSettle();

        // Verify mock was called
        verify(mockCamera.hasCamera()).called(1);

        // Check result
        expect(find.text('Camera is available on this device'), findsOneWidget);
      },
    );

    testWidgets('shows loading indicator when isLoading is true', (
      WidgetTester tester,
    ) async {
      // Make the async operation delay to test loading state
      when(mockCamera.takePicture()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return '/path/to/image.jpg';
      });

      await tester.pumpWidget(createWidgetUnderTest());

      // Tap take picture button
      await tester.tap(find.text('Take Picture'));
      await tester.pump(); // Don't settle, so we can see loading state

      // Check for loading indicator in the button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows snackbar for errors', (WidgetTester tester) async {
      when(mockCamera.takePicture()).thenThrow(Exception('Camera error'));

      await tester.pumpWidget(createWidgetUnderTest());

      // Tap take picture button
      await tester.tap(find.text('Take Picture'));
      await tester.pumpAndSettle();

      // Should show result with error message
      expect(find.textContaining('Failed to take picture'), findsOneWidget);
    });
  });
}
