import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/contacts_provider.dart';

class ContactsDemo extends ConsumerWidget {
  const ContactsDemo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsState = ref.watch(contactsProvider);
    final contactsNotifier = ref.read(contactsProvider.notifier);

    // Listen for errors and show snackbar
    ref.listen<ContactsState>(contactsProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
        contactsNotifier.clearError();
      }
    });

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
                    onPressed: contactsState.isLoading
                        ? null
                        : () => contactsNotifier.checkPermission(),
                    icon: const Icon(Icons.security),
                    label: const Text('Check Permission'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: contactsState.isLoading
                        ? null
                        : () => contactsNotifier.requestPermission(),
                    icon: const Icon(Icons.request_page),
                    label: const Text('Request Permission'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: contactsState.isLoading
                  ? null
                  : () => contactsNotifier.getAllContacts(),
              icon: contactsState.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.contacts),
              label: Text(
                contactsState.isLoading ? 'Loading...' : 'Get All Contacts',
              ),
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
                contactsState.result.isEmpty
                    ? 'No result yet'
                    : contactsState.result,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 20),
            if (contactsState.contactsList.isNotEmpty) ...[
              Text(
                'Contacts (${contactsState.contactsList.length}):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: contactsState.contactsList.length,
                  itemBuilder: (context, index) {
                    final contact = contactsState.contactsList[index];
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
}
