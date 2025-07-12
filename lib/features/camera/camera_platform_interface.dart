import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'camera_method_channel.dart';

abstract class CameraPlatform extends PlatformInterface {
  CameraPlatform() : super(token: _token);

  static final Object _token = Object();
  static CameraPlatform _instance = MethodChannelCamera();

  static CameraPlatform get instance => _instance;

  static set instance(CameraPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> takePicture() {
    throw UnimplementedError('takePicture() has not been implemented.');
  }

  Future<String?> pickImageFromGallery() {
    throw UnimplementedError(
      'pickImageFromGallery() has not been implemented.',
    );
  }

  Future<bool> hasCamera() {
    throw UnimplementedError('hasCamera() has not been implemented.');
  }
}
