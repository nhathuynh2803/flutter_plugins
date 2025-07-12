package com.example.secure_storage_helper.features.secure_storage

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class SecureStorageFeature : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var encryptedPrefs: SharedPreferences

    companion object {
        private const val CHANNEL_NAME = "secure_storage_helper/secure_storage"
        private const val PREFS_NAME = "secure_storage_helper_prefs"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        
        try {
            val masterKey = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()

            encryptedPrefs = EncryptedSharedPreferences.create(
                context,
                PREFS_NAME,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            // Fallback to regular SharedPreferences if encryption fails
            encryptedPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "setString" -> {
                handleSetString(call, result)
            }
            "getString" -> {
                handleGetString(call, result)
            }
            "deleteKey" -> {
                handleDeleteKey(call, result)
            }
            "deleteAll" -> {
                handleDeleteAll(call, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleSetString(call: MethodCall, result: Result) {
        val key = call.argument<String>("key")
        val value = call.argument<String>("value")

        if (key == null || value == null) {
            result.error("INVALID_ARGUMENTS", "Key and value must be provided", null)
            return
        }

        try {
            encryptedPrefs.edit().putString(key, value).apply()
            result.success(null)
        } catch (e: Exception) {
            result.error("STORAGE_ERROR", "Failed to store value: ${e.message}", null)
        }
    }

    private fun handleGetString(call: MethodCall, result: Result) {
        val key = call.argument<String>("key")

        if (key == null) {
            result.error("INVALID_ARGUMENTS", "Key must be provided", null)
            return
        }

        try {
            val value = encryptedPrefs.getString(key, null)
            result.success(value)
        } catch (e: Exception) {
            result.error("STORAGE_ERROR", "Failed to retrieve value: ${e.message}", null)
        }
    }

    private fun handleDeleteKey(call: MethodCall, result: Result) {
        val key = call.argument<String>("key")

        if (key == null) {
            result.error("INVALID_ARGUMENTS", "Key must be provided", null)
            return
        }

        try {
            encryptedPrefs.edit().remove(key).apply()
            result.success(null)
        } catch (e: Exception) {
            result.error("STORAGE_ERROR", "Failed to delete key: ${e.message}", null)
        }
    }

    private fun handleDeleteAll(call: MethodCall, result: Result) {
        try {
            encryptedPrefs.edit().clear().apply()
            result.success(null)
        } catch (e: Exception) {
            result.error("STORAGE_ERROR", "Failed to clear storage: ${e.message}", null)
        }
    }
}
