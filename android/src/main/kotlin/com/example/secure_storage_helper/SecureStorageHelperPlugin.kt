package com.example.secure_storage_helper

import com.example.secure_storage_helper.features.secure_storage.SecureStorageFeature
import com.example.secure_storage_helper.features.camera.CameraFeature
import com.example.secure_storage_helper.features.contacts.ContactsFeature
import com.example.secure_storage_helper.features.quick_actions.QuickActionsFeature
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** SecureStorageHelperPlugin */
class SecureStorageHelperPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  
  // Feature plugins
  private val secureStorageFeature = SecureStorageFeature()
  private val cameraFeature = CameraFeature()
  private val contactsFeature = ContactsFeature()
  private val quickActionsFeature = QuickActionsFeature()

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    // Register all feature plugins
    secureStorageFeature.onAttachedToEngine(flutterPluginBinding)
    cameraFeature.onAttachedToEngine(flutterPluginBinding)
    contactsFeature.onAttachedToEngine(flutterPluginBinding)
    quickActionsFeature.onAttachedToEngine(flutterPluginBinding)
    
    // Keep the main channel for backward compatibility
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "secure_storage_helper")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    // Detach all feature plugins
    secureStorageFeature.onDetachedFromEngine(binding)
    cameraFeature.onDetachedFromEngine(binding)
    contactsFeature.onDetachedFromEngine(binding)
    quickActionsFeature.onDetachedFromEngine(binding)
    
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    // Attach activity-aware features
    cameraFeature.onAttachedToActivity(binding)
    contactsFeature.onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivity() {
    // Detach activity-aware features
    cameraFeature.onDetachedFromActivity()
    contactsFeature.onDetachedFromActivity()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    // Reattach activity-aware features
    cameraFeature.onReattachedToActivityForConfigChanges(binding)
    contactsFeature.onReattachedToActivityForConfigChanges(binding)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    // Detach activity-aware features for config changes
    cameraFeature.onDetachedFromActivityForConfigChanges()
    contactsFeature.onDetachedFromActivityForConfigChanges()
  }
}
    channel.setMethodCallHandler(null)
  }
}
