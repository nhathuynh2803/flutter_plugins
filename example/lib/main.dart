// =====================================================
// Flutter Example App - Quick Actions Integration
// =====================================================
// This example app demonstrates how to integrate Quick Actions
// with a Flutter application for seamless shortcut navigation.
//
// Features:
// - Global shortcut listener for app-wide navigation
// - Safe navigation handling for cold starts
// - Integration with all plugin features
//
// Quick Actions Flow:
// 1. User long-presses app icon
// 2. System shows shortcuts created by app
// 3. User taps shortcut
// 4. Native code receives shortcut event
// 5. Native forwards to Flutter via EventChannel
// 6. This app receives event and navigates to appropriate screen

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/secure_storage_demo.dart';
import 'features/camera_demo.dart';
import 'features/contacts_demo.dart';
import 'features/quick_actions_demo.dart';
import 'providers/main_providers.dart';

// ==========================================
// Global Navigation Key
// ==========================================
// Required for navigation from shortcut events when no BuildContext is available
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  // ==========================================
  // State Variables
  // ==========================================

  StreamSubscription<String>? _shortcutSubscription;

  @override
  void initState() {
    super.initState();
    _setupQuickActions(); // Set up default shortcuts
    _initShortcutListener();
  }

  // ==========================================
  // Quick Actions Setup
  // ==========================================

  /// Initialize global shortcut listener for app-wide navigation
  /// This listener handles shortcuts from anywhere in the app
  void _initShortcutListener() {
    print('Main: Initializing shortcut listener...'); // Debug log
    final quickActionsStream = ref.read(quickActionsStreamProvider.stream);
    _shortcutSubscription = quickActionsStream.listen(
      (shortcutType) {
        print('Main: Received shortcut action: $shortcutType'); // Debug log
        _handleShortcutAction(shortcutType);
      },
      onError: (error) {
        print('Main: Shortcut stream error: $error'); // Debug log
      },
      onDone: () {
        print('Main: Shortcut stream closed'); // Debug log
      },
    );
  }

  /// Set up default shortcuts
  /// These shortcuts will be shown when the user long-presses the app icon
  /// They can be customized based on your app's features
  void _setupQuickActions() async {
    ref.read(setupShortcutsProvider);
  }

  // ==========================================
  // Shortcut Navigation Logic
  // ==========================================

  /// Main shortcut handler - processes shortcut events safely
  /// Uses post-frame callback to ensure UI is ready for navigation
  void _handleShortcutAction(String shortcutType) {
    try {
      print('Main: Handling shortcut action: $shortcutType');

      // Multiple delays to ensure Flutter is fully ready
      // First delay for widget tree to be built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Second delay for Navigator to be fully initialized
        Future.delayed(const Duration(milliseconds: 1000), () {
          _performNavigation(shortcutType);
        });
      });
    } catch (e, stackTrace) {
      print('Main: Error handling shortcut action: $e');
      print('Main: Stack trace: $stackTrace');
    }
  }

  /// Performs the actual navigation with retry logic
  /// Handles cases where Navigator context is not ready yet
  void _performNavigation(String shortcutType) {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        print('Main: Navigator context is null, retrying...');
        // Retry after a short delay if context not ready
        Future.delayed(const Duration(milliseconds: 1000), () {
          _performNavigation(shortcutType);
        });
        return;
      }

      // Additional check: ensure Navigator is ready for push operations
      if (!Navigator.canPop(context) && ModalRoute.of(context) == null) {
        print('Main: Navigator not fully ready, retrying...');
        Future.delayed(const Duration(milliseconds: 500), () {
          _performNavigation(shortcutType);
        });
        return;
      }

      // Map shortcut types to screens
      Widget targetScreen;
      switch (shortcutType) {
        case 'camera':
          targetScreen = const CameraDemo();
          break;
        case 'contacts':
          targetScreen = const ContactsDemo();
          break;
        case 'storage':
          targetScreen = const SecureStorageDemo();
          break;
        default:
          print('Main: Unknown shortcut type: $shortcutType');
          return; // Unknown shortcut type
      }

      print('Main: Navigating to screen for $shortcutType');

      // Use pushAndRemoveUntil to ensure clean navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => targetScreen),
        (route) => route.isFirst, // Keep only the home route
      );
    } catch (e, stackTrace) {
      print('Main: Error performing navigation: $e');
      print('Main: Stack trace: $stackTrace');

      // Retry one more time if navigation failed
      Future.delayed(const Duration(milliseconds: 1000), () {
        _performNavigation(shortcutType);
      });
    }
  }

  // ==========================================
  // Platform Initialization
  // ==========================================
  // Platform version is now handled by Riverpod provider

  // ==========================================
  // Lifecycle Management
  // ==========================================

  /// Clean up resources when widget is disposed
  @override
  void dispose() {
    _shortcutSubscription?.cancel();
    super.dispose();
  }

  // ==========================================
  // UI Build Method
  // ==========================================

  /// Build the main application UI with global navigator key
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi-Feature Plugin Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      navigatorKey: navigatorKey, // Required for shortcut navigation
      home: const HomePage(),
    );
  }
}

// ==========================================
// Home Page Widget
// ==========================================
/// Main home page with navigation to all plugin features
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformVersionAsync = ref.watch(platformVersionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Feature Plugin Demo'),
        backgroundColor: Colors.blue[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // Platform Information Card
            // ==========================================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.blue[600]),
                    const SizedBox(height: 8),
                    Text(
                      'Platform Info',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    platformVersionAsync.when(
                      data: (platformVersion) => Text(
                        'Running on: $platformVersion',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stackTrace) => Text(
                        'Error: $error',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Available Features:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    context,
                    'Secure Storage',
                    Icons.security,
                    Colors.blue,
                    'Store data securely',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SecureStorageDemo(),
                      ),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    'Camera',
                    Icons.camera_alt,
                    Colors.green,
                    'Take photos & pick images',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CameraDemo(),
                      ),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    'Contacts',
                    Icons.contacts,
                    Colors.orange,
                    'Access device contacts',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContactsDemo(),
                      ),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    'Quick Actions',
                    Icons.touch_app,
                    Colors.purple,
                    'App shortcuts & actions',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuickActionsDemo(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
