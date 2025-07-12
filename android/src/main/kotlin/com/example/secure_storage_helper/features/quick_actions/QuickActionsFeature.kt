// =====================================================
// Android Quick Actions Feature - Native Implementation
// =====================================================
// This file implements Android app shortcuts functionality.
// It provides a bridge between Android native shortcuts and Flutter Dart code.
//
// Architecture:
// 1. Flutter calls methods to create/manage shortcuts
// 2. Android shows shortcuts when user long-presses app icon
// 3. When shortcut is tapped, MainActivity receives the intent
// 4. MainActivity forwards via internal method channel to this class
// 5. This class sends shortcut data to Flutter via EventChannel
// 6. Flutter Dart code handles navigation
//
// Method Channels:
// - secure_storage_helper/quick_actions: Dart -> Native (create/clear shortcuts)
// - secure_storage_helper/quick_actions_stream: Native -> Dart (shortcut events)
// - secure_storage_helper/quick_actions_internal: MainActivity -> QuickActionsFeature

package com.example.secure_storage_helper.features.quick_actions

import android.annotation.TargetApi
import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class QuickActionsFeature : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    
    // ==========================================
    // Properties & State Management
    // ==========================================
    
    /// Method channel for Dart to call native methods (create/clear shortcuts)
    private lateinit var channel: MethodChannel
    
    /// Event channel for sending shortcut events from native to Dart
    private lateinit var eventChannel: EventChannel
    
    /// Internal method channel for MainActivity to forward shortcuts
    private lateinit var internalChannel: MethodChannel
    
    /// Android application context
    private lateinit var context: Context
    
    /// Event sink to send data to Dart (null until Dart starts listening)
    private var eventSink: EventChannel.EventSink? = null

    companion object {
        /// Channel names - must match iOS and Dart implementations
        private const val CHANNEL_NAME = "secure_storage_helper/quick_actions"
        private const val EVENT_CHANNEL_NAME = "secure_storage_helper/quick_actions_stream"
        private const val INTERNAL_CHANNEL_NAME = "secure_storage_helper/quick_actions_internal"
        
        /// Shared instance for MainActivity access
        var instance: QuickActionsFeature? = null
    }

    // ==========================================
    // Plugin Registration & Setup
    // ==========================================
    
    /// Called by Flutter engine to register this plugin
    /// Sets up all communication channels with Dart and MainActivity
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // Create method channel for Dart -> Native calls
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        
        // Create event channel for Native -> Dart events
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL_NAME)
        
        // Create internal channel for MainActivity -> QuickActionsFeature communication
        internalChannel = MethodChannel(flutterPluginBinding.binaryMessenger, INTERNAL_CHANNEL_NAME)
        
        // Register handlers
        channel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        
        // Handle internal channel calls from MainActivity
        internalChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "handleShortcut" -> {
                    val shortcutType = call.arguments as? String
                    println("QuickActionsFeature: Received internal shortcut: $shortcutType")
                    if (shortcutType != null) {
                        handleShortcutAction(shortcutType)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        
        context = flutterPluginBinding.applicationContext
        instance = this
    }

    /// Called when plugin is detached from Flutter engine
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        internalChannel.setMethodCallHandler(null)
        instance = null
    }

    // ==========================================
    // Flutter Method Call Handler
    // ==========================================
    
    /// Handles method calls from Flutter Dart code
    /// Supported methods: setShortcutItems, clearShortcutItems
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setShortcutItems" -> {
                handleSetShortcutItems(call, result)
            }
            "clearShortcutItems" -> {
                handleClearShortcutItems(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    // ==========================================
    // Shortcut Management Methods
    // ==========================================
    
    /// Creates Android app shortcuts from Flutter data
    /// Called when Flutter calls setShortcutItems method
    private fun handleSetShortcutItems(call: MethodCall, result: Result) {
        // Android 7.1+ (API 25) required for app shortcuts
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N_MR1) {
            result.error("UNSUPPORTED_VERSION", "App shortcuts are only supported on Android 7.1 (API 25) and above", null)
            return
        }

        val items = call.argument<List<Map<String, Any>>>("items")
        if (items == null) {
            result.error("INVALID_ARGUMENTS", "Items must be provided", null)
            return
        }

        setShortcutItems(items, result)
    }

    /// Removes all Android app shortcuts
    /// Called when Flutter calls clearShortcutItems method
    private fun handleClearShortcutItems(result: Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N_MR1) {
            result.error("UNSUPPORTED_VERSION", "App shortcuts are only supported on Android 7.1 (API 25) and above", null)
            return
        }

        clearShortcutItems(result)
    }

    /// Internal method to create Android shortcuts
    /// Processes Flutter shortcut data and creates native Android shortcuts
    @TargetApi(Build.VERSION_CODES.N_MR1)
    private fun setShortcutItems(items: List<Map<String, Any>>, result: Result) {
        try {
            val shortcutManager = context.getSystemService(Context.SHORTCUT_SERVICE) as ShortcutManager
            val shortcuts = mutableListOf<ShortcutInfo>()

            // Process each shortcut item from Flutter
            for (item in items) {
                val type = item["type"] as? String ?: continue
                val title = item["title"] as? String ?: continue
                val subtitle = item["subtitle"] as? String
                val iconName = item["icon"] as? String

                // Create intent that will be triggered when shortcut is tapped
                // This intent will start MainActivity with shortcut info
                val intent = Intent().apply {
                    action = Intent.ACTION_MAIN
                    setClassName(context, "com.example.secure_storage_helper_example.MainActivity")
                    putExtra("shortcut_type", type) // Pass shortcut type to MainActivity
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }

                // Build Android shortcut with title and intent
                val builder = ShortcutInfo.Builder(context, type)
                    .setShortLabel(title)
                    .setIntent(intent)

                // Add subtitle if provided
                subtitle?.let {
                    builder.setLongLabel(it)
                }

                // Map icon name to Android system icons
                iconName?.let { name ->
                    val iconResourceId = getIconResourceId(name)
                    if (iconResourceId != 0) {
                        builder.setIcon(Icon.createWithResource(context, iconResourceId))
                    }
                }

                shortcuts.add(builder.build())
            }

            // Apply shortcuts to Android system
            shortcutManager.dynamicShortcuts = shortcuts
            result.success(null)
        } catch (e: Exception) {
            result.error("SHORTCUT_ERROR", "Failed to set shortcuts: ${e.message}", null)
        }
    }

    /// Internal method to clear all Android shortcuts
    @TargetApi(Build.VERSION_CODES.N_MR1)
    private fun clearShortcutItems(result: Result) {
        try {
            val shortcutManager = context.getSystemService(Context.SHORTCUT_SERVICE) as ShortcutManager
            shortcutManager.removeAllDynamicShortcuts()
            result.success(null)
        } catch (e: Exception) {
            result.error("SHORTCUT_ERROR", "Failed to clear shortcuts: ${e.message}", null)
        }
    }

    // ==========================================
    // Icon Mapping Helper
    // ==========================================
    
    /// Maps icon names to Android system drawable resources
    /// This ensures consistent icons across different Android versions
    private fun getIconResourceId(iconName: String): Int {
        return when (iconName) {
            "search" -> android.R.drawable.ic_menu_search
            "add" -> android.R.drawable.ic_menu_add
            "share" -> android.R.drawable.ic_menu_share
            "edit" -> android.R.drawable.ic_menu_edit
            "delete" -> android.R.drawable.ic_menu_delete
            "save" -> android.R.drawable.ic_menu_save
            "camera", "capture_photo" -> android.R.drawable.ic_menu_camera
            "gallery" -> android.R.drawable.ic_menu_gallery
            "location" -> android.R.drawable.ic_menu_mylocation
            "info" -> android.R.drawable.ic_menu_info_details
            "settings" -> android.R.drawable.ic_menu_preferences
            "help" -> android.R.drawable.ic_menu_help
            "contact" -> android.R.drawable.ic_menu_call
            "bookmark" -> android.R.drawable.ic_menu_sort_by_size
            else -> 0 // Return 0 for unknown icons (no icon will be shown)
        }
    }

    // ==========================================
    // Event Channel Stream Handler
    // ==========================================
    // Handles Flutter listening for shortcut events via EventChannel

    /// Called when Flutter starts listening for shortcut events
    /// Sets up event sink for sending shortcut events to Dart
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    /// Called when Flutter stops listening for shortcut events
    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // ==========================================
    // Shortcut Event Handling
    // ==========================================
    
    /// Handles shortcut actions received from MainActivity
    /// Forwards shortcut events to Flutter Dart code via EventChannel
    fun handleShortcutAction(shortcutType: String) {
        println("QuickActionsFeature: Handling shortcut action: $shortcutType")
        
        eventSink?.let { sink ->
            // Flutter is listening, send shortcut event immediately
            println("QuickActionsFeature: Sending to event sink: $shortcutType")
            sink.success(shortcutType)
        } ?: run {
            // Flutter not listening yet (should not happen in normal flow)
            println("QuickActionsFeature: Event sink is null")
        }
    }
}
