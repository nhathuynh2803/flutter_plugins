import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'secure_storage_method_channel.dart';

abstract class SecureStoragePlatform extends PlatformInterface {
  SecureStoragePlatform() : super(token: _token);

  static final Object _token = Object();
  static SecureStoragePlatform _instance = MethodChannelSecureStorage();

  static SecureStoragePlatform get instance => _instance;

  static set instance(SecureStoragePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  Future<void> setString(String key, String value) {
    throw UnimplementedError('setString() has not been implemented.');
  }

  Future<String?> getString(String key) {
    throw UnimplementedError('getString() has not been implemented.');
  }

  Future<void> deleteKey(String key) {
    throw UnimplementedError('deleteKey() has not been implemented.');
  }

  Future<void> deleteAll() {
    throw UnimplementedError('deleteAll() has not been implemented.');
  }
}
