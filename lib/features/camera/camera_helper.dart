import 'camera_platform_interface.dart';

class CameraHelper {
  Future<String?> takePicture() {
    return CameraPlatform.instance.takePicture();
  }

  Future<String?> pickImageFromGallery() {
    return CameraPlatform.instance.pickImageFromGallery();
  }

  Future<bool> hasCamera() {
    return CameraPlatform.instance.hasCamera();
  }
}
