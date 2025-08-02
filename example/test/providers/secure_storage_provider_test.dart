import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_plugins/features/secure_storage/secure_storage_helper.dart';
import 'package:flutter_plugins_example/providers/secure_storage_provider.dart';

import 'secure_storage_provider_test.mocks.dart';

@GenerateMocks([SecureStorageHelper])
void main() {
  late MockSecureStorageHelper mockSecureStorage;
  late ProviderContainer container;

  setUp(() {
    mockSecureStorage = MockSecureStorageHelper();
    container = ProviderContainer(
      overrides: [
        secureStorageHelperProvider.overrideWithValue(mockSecureStorage),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('SecureStorageProvider', () {
    test('initial state is correct', () {
      final state = container.read(secureStorageProvider);

      expect(state.result, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('setValue sets value successfully', () async {
      when(
        mockSecureStorage.setString('testKey', 'testValue'),
      ).thenAnswer((_) async => {});

      final notifier = container.read(secureStorageProvider.notifier);

      await notifier.setValue('testKey', 'testValue');

      final state = container.read(secureStorageProvider);
      expect(state.result, 'Value set successfully for key: testKey');
      expect(state.isLoading, false);
      expect(state.error, isNull);
      verify(mockSecureStorage.setString('testKey', 'testValue')).called(1);
    });

    test('setValue handles empty key or value', () async {
      final notifier = container.read(secureStorageProvider.notifier);

      await notifier.setValue('', 'testValue');

      final state = container.read(secureStorageProvider);
      expect(state.error, 'Please enter both key and value');
      verifyNever(mockSecureStorage.setString(any, any));
    });

    test('setValue handles PlatformException', () async {
      when(
        mockSecureStorage.setString('testKey', 'testValue'),
      ).thenThrow(PlatformException(code: 'ERROR', message: 'Test error'));

      final notifier = container.read(secureStorageProvider.notifier);

      await notifier.setValue('testKey', 'testValue');

      final state = container.read(secureStorageProvider);
      expect(state.result, 'Failed to set value: Test error');
      expect(state.error, 'Failed to set value: Test error');
      expect(state.isLoading, false);
    });

    test('getValue gets value successfully', () async {
      when(
        mockSecureStorage.getString('testKey'),
      ).thenAnswer((_) async => 'testValue');

      final notifier = container.read(secureStorageProvider.notifier);

      await notifier.getValue('testKey');

      final state = container.read(secureStorageProvider);
      expect(state.result, 'Value for key "testKey": testValue');
      expect(state.isLoading, false);
      expect(state.error, isNull);
      verify(mockSecureStorage.getString('testKey')).called(1);
    });

    test('getValue handles null value', () async {
      when(
        mockSecureStorage.getString('testKey'),
      ).thenAnswer((_) async => null);

      final notifier = container.read(secureStorageProvider.notifier);

      await notifier.getValue('testKey');

      final state = container.read(secureStorageProvider);
      expect(state.result, 'No value found for key: testKey');
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('getValue handles empty key', () async {
      final notifier = container.read(secureStorageProvider.notifier);

      await notifier.getValue('');

      final state = container.read(secureStorageProvider);
      expect(state.error, 'Please enter a key');
      verifyNever(mockSecureStorage.getString(any));
    });

    test('deleteKey deletes key successfully', () async {
      when(mockSecureStorage.deleteKey('testKey')).thenAnswer((_) async => {});

      final notifier = container.read(secureStorageProvider.notifier);

      await notifier.deleteKey('testKey');

      final state = container.read(secureStorageProvider);
      expect(state.result, 'Key deleted successfully: testKey');
      expect(state.isLoading, false);
      expect(state.error, isNull);
      verify(mockSecureStorage.deleteKey('testKey')).called(1);
    });

    test('deleteAll deletes all keys successfully', () async {
      when(mockSecureStorage.deleteAll()).thenAnswer((_) async => {});

      final notifier = container.read(secureStorageProvider.notifier);

      await notifier.deleteAll();

      final state = container.read(secureStorageProvider);
      expect(state.result, 'All keys deleted successfully');
      expect(state.isLoading, false);
      expect(state.error, isNull);
      verify(mockSecureStorage.deleteAll()).called(1);
    });

    test('clearError clears error', () async {
      // First set an error
      final notifier = container.read(secureStorageProvider.notifier);
      await notifier.setValue('', 'testValue'); // This will set an error

      final stateWithError = container.read(secureStorageProvider);
      expect(stateWithError.error, isNotNull);

      // Clear the error
      notifier.clearError();

      final stateAfterClear = container.read(secureStorageProvider);
      expect(stateAfterClear.error, isNull);
    });
  });
}
