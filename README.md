# Flutter Plugins Collection

A comprehensive Flutter plugin collection providing modular features for common mobile app functionalities.

## Features

This plugin collection includes the following modular features:

### 🔐 Secure Storage
- Encrypted key-value storage for sensitive data
- Platform-specific secure storage (iOS Keychain, Android Keystore)
- Simple API for storing and retrieving sensitive information

### 📷 Camera
- Camera access and photo capture
- Image handling and file management
- Cross-platform camera functionality

### 📱 Contacts
- Contact access and management
- Read device contacts with proper permissions
- Contact information retrieval

### ⚡ Quick Actions (App Shortcuts)
- iOS 3D Touch and long-press shortcuts
- Android app shortcuts
- Dynamic shortcut creation and management
- Deep linking and navigation support

## Architecture

This plugin follows a modular architecture where each feature is:
- **Self-contained**: Each feature has its own platform interface, method channel implementation, and helper classes
- **Well-documented**: Comprehensive comments and documentation for easy understanding
- **Cross-platform**: Consistent API across iOS and Android with platform-specific optimizations
- **Extensible**: Easy to add new features following the established pattern

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_plugins:
    git:
      url: https://github.com/nhathuynh2803/flutter_plugins.git
```

### Usage

```dart
import 'package:flutter_plugins/features.dart';

// Secure Storage
final secureStorage = SecureStorageHelper();
await secureStorage.write(key: 'token', value: 'your_token');
String? token = await secureStorage.read(key: 'token');

// Camera
final camera = CameraHelper();
String? imagePath = await camera.takePhoto();

// Contacts
final contacts = ContactsHelper();
List<Map<String, dynamic>> contactList = await contacts.getContacts();

// Quick Actions
final quickActions = QuickActionsHelper();
await quickActions.setShortcutItems([
  {
    'type': 'camera',
    'title': 'Take Photo',
    'icon': 'camera'
  }
]);

// Listen for shortcut events
quickActions.shortcutStream.listen((shortcutType) {
  // Handle navigation based on shortcut type
});
```

## Example App

The example app demonstrates all features with:
- Interactive demos for each feature
- Comprehensive UI showcasing functionality
- Quick Actions integration with navigation
- Best practices implementation

Run the example:
```bash
cd example
flutter run
```

## Platform Support

| Feature | iOS | Android |
|---------|-----|---------|
| Secure Storage | ✅ | ✅ |
| Camera | ✅ | ✅ |
| Contacts | ✅ | ✅ |
| Quick Actions | ✅ | ✅ |

## Requirements

- Flutter SDK: >=3.3.0
- Dart: >=3.8.1
- iOS: 12.0+
- Android: API 25+ (Quick Actions), API 21+ (other features)

## Documentation

- [Quick Actions Implementation Guide](QUICK_ACTIONS_GUIDE.md)
- [API Reference](https://pub.dev/documentation/flutter_plugins/)
- [Example App](example/)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
