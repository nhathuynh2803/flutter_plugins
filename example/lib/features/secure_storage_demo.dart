import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:secure_storage_helper/features/secure_storage/secure_storage_helper.dart';

class SecureStorageDemo extends StatefulWidget {
  const SecureStorageDemo({super.key});

  @override
  State<SecureStorageDemo> createState() => _SecureStorageDemoState();
}

class _SecureStorageDemoState extends State<SecureStorageDemo> {
  final _secureStorage = SecureStorageHelper();
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();
  String _result = '';

  @override
  Widget build(BuildContext context) {
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
                    onPressed: _setValue,
                    child: const Text('Set Value'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _getValue,
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
                    onPressed: _deleteKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Delete Key'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _deleteAll,
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
                _result.isEmpty ? 'No result yet' : _result,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setValue() async {
    if (_keyController.text.isEmpty || _valueController.text.isEmpty) {
      _showSnackBar('Please enter both key and value');
      return;
    }

    try {
      await _secureStorage.setString(
        _keyController.text,
        _valueController.text,
      );
      setState(() {
        _result = 'Value set successfully for key: ${_keyController.text}';
      });
    } on PlatformException catch (e) {
      setState(() {
        _result = 'Failed to set value: ${e.message}';
      });
    }
  }

  Future<void> _getValue() async {
    if (_keyController.text.isEmpty) {
      _showSnackBar('Please enter a key');
      return;
    }

    try {
      final value = await _secureStorage.getString(_keyController.text);
      setState(() {
        _result = value != null
            ? 'Value for key "${_keyController.text}": $value'
            : 'No value found for key: ${_keyController.text}';
      });
    } on PlatformException catch (e) {
      setState(() {
        _result = 'Failed to get value: ${e.message}';
      });
    }
  }

  Future<void> _deleteKey() async {
    if (_keyController.text.isEmpty) {
      _showSnackBar('Please enter a key');
      return;
    }

    try {
      await _secureStorage.deleteKey(_keyController.text);
      setState(() {
        _result = 'Key deleted successfully: ${_keyController.text}';
      });
    } on PlatformException catch (e) {
      setState(() {
        _result = 'Failed to delete key: ${e.message}';
      });
    }
  }

  Future<void> _deleteAll() async {
    try {
      await _secureStorage.deleteAll();
      setState(() {
        _result = 'All keys deleted successfully';
      });
    } on PlatformException catch (e) {
      setState(() {
        _result = 'Failed to delete all keys: ${e.message}';
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }
}
