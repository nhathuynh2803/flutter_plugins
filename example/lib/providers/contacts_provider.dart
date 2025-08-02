import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_plugins/features/contacts/contacts_helper.dart';

// ==========================================
// Contacts State
// ==========================================

class ContactsState {
  final String result;
  final List<Map<String, dynamic>> contactsList;
  final bool isLoading;
  final String? error;

  const ContactsState({
    this.result = '',
    this.contactsList = const [],
    this.isLoading = false,
    this.error,
  });

  ContactsState copyWith({
    String? result,
    List<Map<String, dynamic>>? contactsList,
    bool? isLoading,
    String? error,
  }) {
    return ContactsState(
      result: result ?? this.result,
      contactsList: contactsList ?? this.contactsList,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ==========================================
// Contacts Notifier
// ==========================================

class ContactsNotifier extends StateNotifier<ContactsState> {
  final ContactsHelper _contacts;

  ContactsNotifier(this._contacts) : super(const ContactsState());

  Future<void> checkPermission() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final hasPermission = await _contacts.hasContactsPermission();
      state = state.copyWith(
        isLoading: false,
        result: hasPermission
            ? 'Contacts permission is granted'
            : 'Contacts permission is not granted',
      );
    } on PlatformException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to check permission: ${e.message}',
        result: 'Failed to check permission: ${e.message}',
      );
    }
  }

  Future<void> requestPermission() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final granted = await _contacts.requestContactsPermission();
      state = state.copyWith(
        isLoading: false,
        result: granted
            ? 'Contacts permission granted'
            : 'Contacts permission denied',
      );
    } on PlatformException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to request permission: ${e.message}',
        result: 'Failed to request permission: ${e.message}',
      );
    }
  }

  Future<void> getAllContacts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final contacts = await _contacts.getAllContacts();
      state = state.copyWith(
        isLoading: false,
        contactsList: contacts,
        result: 'Retrieved ${contacts.length} contacts successfully',
      );
    } on PlatformException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get contacts: ${e.message}',
        result: 'Failed to get contacts: ${e.message}',
        contactsList: [],
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ==========================================
// Providers
// ==========================================

final contactsHelperProvider = Provider<ContactsHelper>((ref) {
  return ContactsHelper();
});

final contactsProvider = StateNotifierProvider<ContactsNotifier, ContactsState>(
  (ref) {
    final contacts = ref.watch(contactsHelperProvider);
    return ContactsNotifier(contacts);
  },
);
