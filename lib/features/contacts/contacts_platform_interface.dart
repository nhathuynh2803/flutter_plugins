import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'contacts_method_channel.dart';

abstract class ContactsPlatform extends PlatformInterface {
  ContactsPlatform() : super(token: _token);

  static final Object _token = Object();
  static ContactsPlatform _instance = MethodChannelContacts();

  static ContactsPlatform get instance => _instance;

  static set instance(ContactsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<Map<String, dynamic>>> getAllContacts() {
    throw UnimplementedError('getAllContacts() has not been implemented.');
  }

  Future<Map<String, dynamic>?> getContactById(String contactId) {
    throw UnimplementedError('getContactById() has not been implemented.');
  }

  Future<bool> hasContactsPermission() {
    throw UnimplementedError(
      'hasContactsPermission() has not been implemented.',
    );
  }

  Future<bool> requestContactsPermission() {
    throw UnimplementedError(
      'requestContactsPermission() has not been implemented.',
    );
  }
}
