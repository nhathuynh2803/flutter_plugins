import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_plugins/features/contacts/contacts_helper.dart';

class ContactsDemo extends StatefulWidget {
  const ContactsDemo({super.key});

  @override
  State<ContactsDemo> createState() => _ContactsDemoState();
}

class _ContactsDemoState extends State<ContactsDemo> {
  final _contacts = ContactsHelper();
  String _result = '';
  List<Map<String, dynamic>> _contactsList = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts Demo'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _checkPermission,
                    icon: const Icon(Icons.security),
                    label: const Text('Check Permission'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _requestPermission,
                    icon: const Icon(Icons.request_page),
                    label: const Text('Request Permission'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _getAllContacts,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.contacts),
              label: Text(_isLoading ? 'Loading...' : 'Get All Contacts'),
            ),
            const SizedBox(height: 20),
            Text('Result:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _result.isEmpty ? 'No result yet' : _result,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 20),
            if (_contactsList.isNotEmpty) ...[
              Text(
                'Contacts (${_contactsList.length}):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _contactsList.length,
                  itemBuilder: (context, index) {
                    final contact = _contactsList[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            (contact['name']?.toString() ?? 'N')[0]
                                .toUpperCase(),
                          ),
                        ),
                        title: Text(contact['name']?.toString() ?? 'No Name'),
                        subtitle: Text(
                          contact['phone']?.toString() ?? 'No Phone',
                        ),
                        trailing: contact['email'] != null
                            ? Icon(Icons.email, color: Colors.grey[600])
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _checkPermission() async {
    try {
      final hasPermission = await _contacts.hasContactsPermission();
      setState(() {
        _result = hasPermission
            ? 'Contacts permission is granted'
            : 'Contacts permission is not granted';
      });
    } on PlatformException catch (e) {
      setState(() {
        _result = 'Failed to check permission: ${e.message}';
      });
    }
  }

  Future<void> _requestPermission() async {
    try {
      final granted = await _contacts.requestContactsPermission();
      setState(() {
        _result = granted
            ? 'Contacts permission granted'
            : 'Contacts permission denied';
      });
    } on PlatformException catch (e) {
      setState(() {
        _result = 'Failed to request permission: ${e.message}';
      });
    }
  }

  Future<void> _getAllContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final contacts = await _contacts.getAllContacts();
      setState(() {
        _contactsList = contacts;
        _result = 'Retrieved ${contacts.length} contacts successfully';
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _result = 'Failed to get contacts: ${e.message}';
        _contactsList = [];
        _isLoading = false;
      });
    }
  }
}
