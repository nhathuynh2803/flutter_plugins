import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_plugins/features/camera/camera_helper.dart';
import 'dart:io';

class CameraDemo extends StatefulWidget {
  const CameraDemo({super.key});

  @override
  State<CameraDemo> createState() => _CameraDemoState();
}

class _CameraDemoState extends State<CameraDemo> {
  final _camera = CameraHelper();
  String _result = '';
  String? _imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Demo'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Picture'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick from Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _checkCameraAvailability,
              icon: const Icon(Icons.info),
              label: const Text('Check Camera Availability'),
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
            if (_imagePath != null) ...[
              Text(
                'Selected Image:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_imagePath!),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Text('Error loading image'));
                      },
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    try {
      final imagePath = await _camera.takePicture();
      setState(() {
        _imagePath = imagePath;
        _result = imagePath != null
            ? 'Picture taken successfully: $imagePath'
            : 'Failed to take picture';
      });
    } on PlatformException catch (e) {
      setState(() {
        _result = 'Failed to take picture: ${e.message}';
        _imagePath = null;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final imagePath = await _camera.pickImageFromGallery();
      setState(() {
        _imagePath = imagePath;
        _result = imagePath != null
            ? 'Image picked successfully: $imagePath'
            : 'Failed to pick image';
      });
    } on PlatformException catch (e) {
      setState(() {
        _result = 'Failed to pick image: ${e.message}';
        _imagePath = null;
      });
    }
  }

  Future<void> _checkCameraAvailability() async {
    try {
      final hasCamera = await _camera.hasCamera();
      setState(() {
        _result = hasCamera
            ? 'Camera is available on this device'
            : 'No camera available on this device';
      });
    } on PlatformException catch (e) {
      setState(() {
        _result = 'Failed to check camera: ${e.message}';
      });
    }
  }
}
