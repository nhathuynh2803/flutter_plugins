import 'contacts_platform_interface.dart';

class ContactsHelper {
  Future<List<Map<String, dynamic>>> getAllContacts() {
    return ContactsPlatform.instance.getAllContacts();
  }

  Future<Map<String, dynamic>?> getContactById(String contactId) {
    return ContactsPlatform.instance.getContactById(contactId);
  }

  Future<bool> hasContactsPermission() {
    return ContactsPlatform.instance.hasContactsPermission();
  }

  Future<bool> requestContactsPermission() {
    return ContactsPlatform.instance.requestContactsPermission();
  }
}
