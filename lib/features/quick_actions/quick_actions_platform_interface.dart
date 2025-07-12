import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'quick_actions_method_channel.dart';

abstract class QuickActionsPlatform extends PlatformInterface {
  QuickActionsPlatform() : super(token: _token);

  static final Object _token = Object();
  static QuickActionsPlatform _instance = MethodChannelQuickActions();

  static QuickActionsPlatform get instance => _instance;

  static set instance(QuickActionsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> setShortcutItems(List<Map<String, String>> shortcuts) {
    throw UnimplementedError('setShortcutItems() has not been implemented.');
  }

  Future<void> clearShortcutItems() {
    throw UnimplementedError('clearShortcutItems() has not been implemented.');
  }

  Stream<String> get shortcutStream {
    throw UnimplementedError('shortcutStream has not been implemented.');
  }
}
