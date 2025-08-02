import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/secure_storage_provider.dart';

class SecureStorageDemo extends ConsumerStatefulWidget {
  const SecureStorageDemo({super.key});

  @override
  ConsumerState<SecureStorageDemo> createState() => _SecureStorageDemoState();
}

class _SecureStorageDemoState extends ConsumerState<SecureStorageDemo> {
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final secureStorageState = ref.watch(secureStorageProvider);
    final secureStorageNotifier = ref.read(secureStorageProvider.notifier);

    // Listen for errors and show snackbar
    ref.listen<SecureStorageState>(secureStorageProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
        secureStorageNotifier.clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Storage Demo'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: 'Key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Value',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: secureStorageState.isLoading
                        ? null
                        : () => secureStorageNotifier.setValue(
                            _keyController.text,
                            _valueController.text,
                          ),
                    child: secureStorageState.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Set Value'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: secureStorageState.isLoading
                        ? null
                        : () => secureStorageNotifier.getValue(
                            _keyController.text,
                          ),
                    child: const Text('Get Value'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: secureStorageState.isLoading
                        ? null
                        : () => secureStorageNotifier.deleteKey(
                            _keyController.text,
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Delete Key'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: secureStorageState.isLoading
                        ? null
                        : () => secureStorageNotifier.deleteAll(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Delete All'),
                  ),
                ),
              ],
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
                secureStorageState.result.isEmpty
                    ? 'No result yet'
                    : secureStorageState.result,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }
}
