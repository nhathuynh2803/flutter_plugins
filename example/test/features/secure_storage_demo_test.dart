import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_plugins/features/secure_storage/secure_storage_helper.dart';
import 'package:flutter_plugins_example/features/secure_storage_demo.dart';
import 'package:flutter_plugins_example/providers/secure_storage_provider.dart';

import '../providers/secure_storage_provider_test.mocks.dart';

@GenerateMocks([SecureStorageHelper])
void main() {
  late MockSecureStorageHelper mockSecureStorage;

  setUp(() {
    mockSecureStorage = MockSecureStorageHelper();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        secureStorageHelperProvider.overrideWithValue(mockSecureStorage),
      ],
      child: const MaterialApp(home: SecureStorageDemo()),
    );
  }

  group('SecureStorageDemo Widget Tests', () {
    testWidgets('renders all UI elements correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Check for app bar
      expect(find.text('Secure Storage Demo'), findsOneWidget);

      // Check for text fields
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Key'), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);

      // Check for buttons
      expect(find.text('Set Value'), findsOneWidget);
      expect(find.text('Get Value'), findsOneWidget);
      expect(find.text('Delete Key'), findsOneWidget);
      expect(find.text('Delete All'), findsOneWidget);

      // Check for result section
      expect(find.text('Result:'), findsOneWidget);
      expect(find.text('No result yet'), findsOneWidget);
    });

    testWidgets('set value button triggers setValue', (
      WidgetTester tester,
    ) async {
      when(
        mockSecureStorage.setString('testKey', 'testValue'),
      ).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter key and value
      await tester.enterText(find.byType(TextField).first, 'testKey');
      await tester.enterText(find.byType(TextField).last, 'testValue');

      // Tap set value button
      await tester.tap(find.text('Set Value'));
      await tester.pumpAndSettle();

      // Verify mock was called
      verify(mockSecureStorage.setString('testKey', 'testValue')).called(1);

      // Check result
      expect(
        find.text('Value set successfully for key: testKey'),
        findsOneWidget,
      );
    });

    testWidgets('get value button triggers getValue', (
      WidgetTester tester,
    ) async {
      when(
        mockSecureStorage.getString('testKey'),
      ).thenAnswer((_) async => 'testValue');

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter key
      await tester.enterText(find.byType(TextField).first, 'testKey');

      // Tap get value button
      await tester.tap(find.text('Get Value'));
      await tester.pumpAndSettle();

      // Verify mock was called
      verify(mockSecureStorage.getString('testKey')).called(1);

      // Check result
      expect(find.text('Value for key "testKey": testValue'), findsOneWidget);
    });

    testWidgets('delete key button triggers deleteKey', (
      WidgetTester tester,
    ) async {
      when(mockSecureStorage.deleteKey('testKey')).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter key
      await tester.enterText(find.byType(TextField).first, 'testKey');

      // Tap delete key button
      await tester.tap(find.text('Delete Key'));
      await tester.pumpAndSettle();

      // Verify mock was called
      verify(mockSecureStorage.deleteKey('testKey')).called(1);

      // Check result
      expect(find.text('Key deleted successfully: testKey'), findsOneWidget);
    });

    testWidgets('delete all button triggers deleteAll', (
      WidgetTester tester,
    ) async {
      when(mockSecureStorage.deleteAll()).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidgetUnderTest());

      // Tap delete all button
      await tester.tap(find.text('Delete All'));
      await tester.pumpAndSettle();

      // Verify mock was called
      verify(mockSecureStorage.deleteAll()).called(1);

      // Check result
      expect(find.text('All keys deleted successfully'), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading is true', (
      WidgetTester tester,
    ) async {
      // Make the async operation delay to test loading state
      when(mockSecureStorage.setString('testKey', 'testValue')).thenAnswer((
        _,
      ) async {
        await Future.delayed(const Duration(milliseconds: 100));
      });

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter key and value
      await tester.enterText(find.byType(TextField).first, 'testKey');
      await tester.enterText(find.byType(TextField).last, 'testValue');

      // Tap set value button
      await tester.tap(find.text('Set Value'));
      await tester.pump(); // Don't settle, so we can see loading state

      // Check for loading indicator in the button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows snackbar for errors', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Don't enter key or value
      await tester.tap(find.text('Set Value'));
      await tester.pumpAndSettle();

      // Should show snackbar with error message
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Please enter both key and value'), findsOneWidget);
    });
  });
}
