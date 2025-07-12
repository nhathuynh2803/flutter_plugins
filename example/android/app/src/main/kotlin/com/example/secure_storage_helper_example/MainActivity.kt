// =====================================================
// Android MainActivity - Quick Actions Handler
// =====================================================
// This activity handles Android app shortcuts when user long-presses
// the app icon on launcher or when shortcuts are triggered.
//
// Flow:
// 1. User long-presses app icon -> Android shows shortcuts
// 2. User taps shortcut -> Android starts MainActivity with intent
// 3. MainActivity extracts shortcut info from intent
// 4. MainActivity forwards shortcut to Flutter via internal method channel
// 5. QuickActionsFeature receives and forwards to Dart via EventChannel
// 6. Dart handles navigation to appropriate screen

package com.example.secure_storage_helper_example

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    
    // ==========================================
    // Activity Lifecycle - Initial Launch
    // ==========================================
    
    /// Called when activity is first created
    /// Handles shortcuts when app was launched from closed state
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Handle shortcut if app was launched via shortcut
        handleShortcutIntent(intent)
    }
    
    // ==========================================
    // Activity Lifecycle - New Intent
    // ==========================================
    
    /// Called when activity receives new intent (app already running)
    /// Handles shortcuts when app was already running/in background
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Handle shortcut from the new intent
        handleShortcutIntent(intent)
    }
    
    // ==========================================
    // Shortcut Processing Logic
    // ==========================================
    
    /// Extracts shortcut information from intent and forwards to Flutter
    /// This method handles both cold start and warm start scenarios
    private fun handleShortcutIntent(intent: Intent?) {
        println("MainActivity: Handling intent: ${intent?.action}")
        
        // Extract shortcut type from intent extras
        // This is set when creating shortcuts in QuickActionsFeature
        val shortcutType = intent?.getStringExtra("shortcut_type")
        println("MainActivity: Shortcut type: $shortcutType")
        
        if (shortcutType != null) {
            // Forward shortcut to Flutter via internal method channel
            flutterEngine?.let { engine ->
                try {
                    println("MainActivity: Sending shortcut to Flutter: $shortcutType")
                    
                    // Create method channel to communicate with QuickActionsFeature
                    // This channel is only used internally between MainActivity and QuickActionsFeature
                    val channel = io.flutter.plugin.common.MethodChannel(
                        engine.dartExecutor.binaryMessenger,
                        "secure_storage_helper/quick_actions_internal"
                    )
                    
                    // Send shortcut type to QuickActionsFeature
                    // QuickActionsFeature will then forward to Dart via EventChannel
                    channel.invokeMethod("handleShortcut", shortcutType)
                } catch (e: Exception) {
                    println("MainActivity: Error handling shortcut: ${e.message}")
                    e.printStackTrace()
                }
            } ?: run {
                println("MainActivity: Flutter engine is null")
            }
        }
    }
}
