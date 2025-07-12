import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'secure_storage_platform_interface.dart';

class MethodChannelSecureStorage extends SecureStoragePlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel(
    'secure_storage_helper/secure_storage',
  );

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> setString(String key, String value) async {
    await methodChannel.invokeMethod<void>('setString', {
      'key': key,
      'value': value,
    });
  }

  @override
  Future<String?> getString(String key) async {
    final value = await methodChannel.invokeMethod<String>('getString', {
      'key': key,
    });
    return value;
  }

  @override
  Future<void> deleteKey(String key) async {
    await methodChannel.invokeMethod<void>('deleteKey', {'key': key});
  }

  @override
  Future<void> deleteAll() async {
    await methodChannel.invokeMethod<void>('deleteAll');
  }
}
