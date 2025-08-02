import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quick_actions_provider.dart';

class QuickActionsDemo extends ConsumerWidget {
  const QuickActionsDemo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickActionsState = ref.watch(quickActionsProvider);
    final quickActionsNotifier = ref.read(quickActionsProvider.notifier);

    // Listen for errors and show snackbar
    ref.listen<QuickActionsState>(quickActionsProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
        quickActionsNotifier.clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Actions Demo'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: quickActionsState.isLoading
                  ? null
                  : () => quickActionsNotifier.setShortcuts(),
              icon: quickActionsState.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle),
              label: const Text('Set Shortcuts'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: quickActionsState.isLoading
                  ? null
                  : () => quickActionsNotifier.clearShortcuts(),
              icon: const Icon(Icons.clear),
              label: const Text('Clear Shortcuts'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to test:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Tap "Set Shortcuts" to create shortcuts\n'
                      '2. Go to home screen\n'
                      '3. Long press the app icon\n'
                      '4. Tap on any shortcut\n'
                      '5. Come back to this screen to see result',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
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
                quickActionsState.result.isEmpty
                    ? 'No result yet'
                    : quickActionsState.result,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 20),
            if (quickActionsState.lastShortcutAction.isNotEmpty) ...[
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Shortcut Action:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        quickActionsState.lastShortcutAction,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Note:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Quick Actions work differently on iOS and Android:\n'
                      '• iOS: 3D Touch or long press on app icon\n'
                      '• Android: Long press on app icon (shortcuts)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
