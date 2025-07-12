import 'secure_storage_platform_interface.dart';

class SecureStorageHelper {
  Future<String?> getPlatformVersion() {
    return SecureStoragePlatform.instance.getPlatformVersion();
  }

  Future<void> setString(String key, String value) {
    return SecureStoragePlatform.instance.setString(key, value);
  }

  Future<String?> getString(String key) {
    return SecureStoragePlatform.instance.getString(key);
  }

  Future<void> deleteKey(String key) {
    return SecureStoragePlatform.instance.deleteKey(key);
  }

  Future<void> deleteAll() {
    return SecureStoragePlatform.instance.deleteAll();
  }
}
