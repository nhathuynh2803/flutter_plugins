import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'contacts_platform_interface.dart';

class MethodChannelContacts extends ContactsPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('secure_storage_helper/contacts');

  @override
  Future<List<Map<String, dynamic>>> getAllContacts() async {
    final contacts = await methodChannel.invokeMethod<List>('getAllContacts');
    return contacts?.cast<Map<String, dynamic>>() ?? [];
  }

  @override
  Future<Map<String, dynamic>?> getContactById(String contactId) async {
    final contact = await methodChannel.invokeMethod<Map>('getContactById', {
      'contactId': contactId,
    });
    return contact?.cast<String, dynamic>();
  }

  @override
  Future<bool> hasContactsPermission() async {
    final hasPermission = await methodChannel.invokeMethod<bool>(
      'hasContactsPermission',
    );
    return hasPermission ?? false;
  }

  @override
  Future<bool> requestContactsPermission() async {
    final permission = await methodChannel.invokeMethod<bool>(
      'requestContactsPermission',
    );
    return permission ?? false;
  }
}
