import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'camera_platform_interface.dart';

class MethodChannelCamera extends CameraPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('secure_storage_helper/camera');

  @override
  Future<String?> takePicture() async {
    final imagePath = await methodChannel.invokeMethod<String>('takePicture');
    return imagePath;
  }

  @override
  Future<String?> pickImageFromGallery() async {
    final imagePath = await methodChannel.invokeMethod<String>(
      'pickImageFromGallery',
    );
    return imagePath;
  }

  @override
  Future<bool> hasCamera() async {
    final hasCamera = await methodChannel.invokeMethod<bool>('hasCamera');
    return hasCamera ?? false;
  }
}
