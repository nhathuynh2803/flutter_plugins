# Quick Actions Implementation Guide

## Overview
This guide explains the complete implementation of Quick Actions (App Shortcuts) feature in the Flutter plugin, covering both Dart and native code (iOS/Android).

## Architecture

### Data Flow
1. **Flutter App** calls `QuickActionsHelper.setShortcutItems()` to create shortcuts
2. **Dart Method Channel** forwards request to native code
3. **Native Code** creates platform-specific shortcuts (iOS/Android)
4. **User** long-presses app icon and taps shortcut
5. **Native Code** receives shortcut event and forwards to Flutter via Event Channel
6. **Flutter App** receives shortcut event and handles navigation

### Channel Structure
- **Method Channel**: `secure_storage_helper/quick_actions` (Dart → Native)
- **Event Channel**: `secure_storage_helper/quick_actions_stream` (Native → Dart)
- **Internal Channel**: `secure_storage_helper/quick_actions_internal` (Android MainActivity → QuickActionsFeature)

## Implementation Details

### 1. Dart Implementation

#### File: `lib/features/quick_actions/quick_actions_helper.dart`
```dart
// Main public API for Quick Actions
class QuickActionsHelper {
  Future<void> setShortcutItems(List<Map<String, String>> shortcuts);
  Future<void> clearShortcutItems();
  Stream<String> get shortcutStream;
}
```

#### File: `lib/features/quick_actions/quick_actions_method_channel.dart`
```dart
// Method channel implementation
class MethodChannelQuickActions extends QuickActionsPlatform {
  final methodChannel = const MethodChannel('secure_storage_helper/quick_actions');
  final eventChannel = const EventChannel('secure_storage_helper/quick_actions_stream');
}
```

#### Usage Example:
```dart
final quickActions = QuickActionsHelper();

// Create shortcuts
await quickActions.setShortcutItems([
  {
    'type': 'camera',
    'title': 'Take Photo',
    'subtitle': 'Quickly capture a photo',
    'icon': 'camera'
  }
]);

// Listen for shortcut events
quickActions.shortcutStream.listen((shortcutType) {
  switch (shortcutType) {
    case 'camera':
      Navigator.pushNamed(context, '/camera');
      break;
  }
});
```

### 2. iOS Implementation

#### File: `ios/Classes/Features/QuickActions/QuickActionsFeature.swift`
- Handles Flutter method calls to create/clear shortcuts
- Listens for shortcut notifications from AppDelegate via NotificationCenter
- Forwards shortcut events to Flutter via EventChannel
- Manages pending shortcuts for cold start scenarios

#### File: `example/ios/Runner/AppDelegate.swift`
- Handles iOS shortcut events in `application:performActionFor:completionHandler:`
- Forwards shortcut events to QuickActionsFeature via NotificationCenter
- Handles cold start scenarios with proper delays

#### Key Features:
- **iOS 9.0+** compatibility
- **System icon mapping** for consistent appearance
- **Cold start handling** with pending shortcut storage
- **Debug logging** for troubleshooting

### 3. Android Implementation

#### File: `android/src/main/kotlin/.../QuickActionsFeature.kt`
- Handles Flutter method calls to create/clear shortcuts
- Receives shortcut events from MainActivity via internal method channel
- Forwards shortcut events to Flutter via EventChannel
- Maps icon names to Android system drawables

#### File: `example/android/app/src/main/kotlin/.../MainActivity.kt`
- Handles shortcut intents in `onCreate()` and `onNewIntent()`
- Extracts shortcut type from intent extras
- Forwards to QuickActionsFeature via internal method channel

#### Key Features:
- **Android 7.1+ (API 25)** compatibility
- **Dynamic shortcuts** management
- **Intent-based** shortcut handling
- **Background/foreground** launch support

## Configuration

### iOS Configuration
- **Info.plist**: No special configuration needed
- **Permissions**: None required for basic shortcuts
- **Icons**: Uses system-provided icons

### Android Configuration
- **AndroidManifest.xml**: MainActivity must handle shortcut intents
- **Permissions**: None required for basic shortcuts
- **Icons**: Uses system-provided drawable resources

## Icon Mapping

### iOS System Icons
- `search` → `UIApplicationShortcutIcon.search`
- `camera` → `UIApplicationShortcutIcon.capturePhoto`
- `contact` → `UIApplicationShortcutIcon.contact`
- `bookmark` → `UIApplicationShortcutIcon.bookmark`
- And many more...

### Android System Icons
- `search` → `android.R.drawable.ic_menu_search`
- `camera` → `android.R.drawable.ic_menu_camera`
- `contact` → `android.R.drawable.ic_menu_call`
- `bookmark` → `android.R.drawable.ic_menu_sort_by_size`
- And many more...

## Testing

### Manual Testing Steps
1. Run the app: `flutter run`
2. Navigate to Quick Actions Demo
3. Tap "Set Shortcuts" to create shortcuts
4. Go to home screen
5. Long-press app icon
6. Tap any shortcut
7. Verify navigation to correct screen

### Cold Start Testing
1. Force close the app
2. Long-press app icon and tap shortcut
3. Verify app opens and navigates correctly

### Background Testing
1. Put app in background
2. Long-press app icon and tap shortcut
3. Verify app comes to foreground and navigates

## Debugging

### Enable Debug Logging
All implementation files include comprehensive debug logging:
- iOS: Uses `print()` statements
- Android: Uses `println()` statements
- Dart: Uses `print()` statements

### Common Issues
1. **Shortcuts not appearing**: Check platform version compatibility
2. **Navigation not working**: Verify global navigator key setup
3. **Cold start crashes**: Ensure proper delay handling
4. **Icon not showing**: Check icon name mapping

## Platform Differences

### iOS
- Uses `UIApplicationShortcutItem`
- Handled via AppDelegate methods
- Supports 3D Touch and long-press
- System-provided icons only

### Android
- Uses `ShortcutManager` and `ShortcutInfo`
- Handled via Intent extras
- Long-press on launcher
- System drawable icons only

## Best Practices

1. **Always handle cold start scenarios** with proper delays
2. **Use global navigator key** for shortcut navigation
3. **Implement error handling** for all platform calls
4. **Test on both platforms** thoroughly
5. **Keep shortcut types consistent** across platforms
6. **Limit shortcuts to 3-4 items** for best UX
7. **Use descriptive titles and subtitles**
8. **Choose appropriate icons** for each shortcut

## Integration with Main App

### Global Setup (main.dart)
```dart
// Global navigator key for shortcut navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class _MyAppState extends State<MyApp> {
  final _quickActions = QuickActionsHelper();
  StreamSubscription<String>? _shortcutSubscription;

  @override
  void initState() {
    super.initState();
    _initShortcutListener();
  }

  void _initShortcutListener() {
    _shortcutSubscription = _quickActions.shortcutStream.listen(
      (shortcutType) => _handleShortcutAction(shortcutType),
    );
  }

  void _handleShortcutAction(String shortcutType) {
    // Handle navigation with proper error handling and delays
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performNavigation(shortcutType);
    });
  }
}
```

This implementation provides a robust, cross-platform Quick Actions feature that handles all edge cases and provides excellent user experience.
