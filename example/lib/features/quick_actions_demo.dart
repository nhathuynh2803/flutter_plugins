import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:secure_storage_helper/features/quick_actions/quick_actions_helper.dart';
import 'dart:async';

class QuickActionsDemo extends StatefulWidget {
  const QuickActionsDemo({super.key});

  @override
  State<QuickActionsDemo> createState() => _QuickActionsDemoState();
}

class _QuickActionsDemoState extends State<QuickActionsDemo> {
  final _quickActions = QuickActionsHelper();
  String _result = '';
  String _lastShortcutAction = '';
  StreamSubscription<String>? _shortcutSubscription;

  @override
  void initState() {
    super.initState();
    _initShortcutListener();
  }

  void _initShortcutListener() {
    _shortcutSubscription = _quickActions.shortcutStream.listen(
      (action) {
        print(
          'QuickActionsDemo: Received shortcut action: $action',
        ); // Debug log
        setState(() {
          _lastShortcutAction = action;
          _result = 'Shortcut pressed: $action';
        });
      },
      onError: (error) {
        print('QuickActionsDemo: Shortcut stream error: $error'); // Debug log
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: _setShortcuts,
              icon: const Icon(Icons.add_circle),
              label: const Text('Set Shortcuts'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _clearShortcuts,
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
                _result.isEmpty ? 'No result yet' : _result,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 20),
            if (_lastShortcutAction.isNotEmpty) ...[
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
                        _lastShortcutAction,
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

  Future<void> _setShortcuts() async {
    try {
      final shortcuts = [
        {'type': 'camera', 'title': 'Take Photo', 'icon': 'capture_photo'},
        {'type': 'contacts', 'title': 'View Contacts', 'icon': 'contact'},
        {'type': 'storage', 'title': 'Secure Storage', 'icon': 'bookmark'},
      ];

      await _quickActions.setShortcutItems(shortcuts);
      setState(() {
        _result =
            'Shortcuts set successfully!\nGo to home screen and long press the app icon to test.';
      });
    } on PlatformException catch (e) {
      setState(() {
        _result = 'Failed to set shortcuts: ${e.message}';
      });
    }
  }

  Future<void> _clearShortcuts() async {
    try {
      await _quickActions.clearShortcutItems();
      setState(() {
        _result = 'Shortcuts cleared successfully';
        _lastShortcutAction = '';
      });
    } on PlatformException catch (e) {
      setState(() {
        _result = 'Failed to clear shortcuts: ${e.message}';
      });
    }
  }

  @override
  void dispose() {
    _shortcutSubscription?.cancel();
    super.dispose();
  }
}
