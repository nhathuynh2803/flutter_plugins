package com.example.secure_storage_helper.features.camera

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class CameraFeature : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private var currentPhotoPath: String? = null

    companion object {
        private const val CHANNEL_NAME = "secure_storage_helper/camera"
        private const val REQUEST_IMAGE_CAPTURE = 1
        private const val REQUEST_PICK_IMAGE = 2
        private const val REQUEST_CAMERA_PERMISSION = 100
        private const val REQUEST_STORAGE_PERMISSION = 101
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "takePicture" -> {
                handleTakePicture(result)
            }
            "pickImageFromGallery" -> {
                handlePickImageFromGallery(result)
            }
            "hasCamera" -> {
                handleHasCamera(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleTakePicture(result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "No activity available", null)
            return
        }

        if (!hasCamera()) {
            result.error("NO_CAMERA", "No camera available", null)
            return
        }

        if (ContextCompat.checkSelfPermission(currentActivity, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            pendingResult = result
            ActivityCompat.requestPermissions(currentActivity, arrayOf(Manifest.permission.CAMERA), REQUEST_CAMERA_PERMISSION)
            return
        }

        openCamera(result)
    }

    private fun handlePickImageFromGallery(result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "No activity available", null)
            return
        }

        if (ContextCompat.checkSelfPermission(currentActivity, Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            pendingResult = result
            ActivityCompat.requestPermissions(currentActivity, arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE), REQUEST_STORAGE_PERMISSION)
            return
        }

        openGallery(result)
    }

    private fun handleHasCamera(result: Result) {
        result.success(hasCamera())
    }

    private fun hasCamera(): Boolean {
        return activity?.packageManager?.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY) == true
    }

    private fun openCamera(result: Result) {
        val currentActivity = activity ?: return
        
        val takePictureIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        if (takePictureIntent.resolveActivity(currentActivity.packageManager) != null) {
            val photoFile: File? = try {
                createImageFile()
            } catch (ex: IOException) {
                result.error("FILE_ERROR", "Error creating image file", ex.message)
                return
            }

            photoFile?.also {
                val photoURI: Uri = FileProvider.getUriForFile(
                    currentActivity,
                    "${currentActivity.packageName}.fileprovider",
                    it
                )
                takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, photoURI)
                pendingResult = result
                currentActivity.startActivityForResult(takePictureIntent, REQUEST_IMAGE_CAPTURE)
            }
        } else {
            result.error("NO_CAMERA_APP", "No camera app available", null)
        }
    }

    private fun openGallery(result: Result) {
        val currentActivity = activity ?: return
        
        val pickPhoto = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
        if (pickPhoto.resolveActivity(currentActivity.packageManager) != null) {
            pendingResult = result
            currentActivity.startActivityForResult(pickPhoto, REQUEST_PICK_IMAGE)
        } else {
            result.error("NO_GALLERY_APP", "No gallery app available", null)
        }
    }

    @Throws(IOException::class)
    private fun createImageFile(): File {
        val timeStamp: String = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val storageDir: File? = activity?.getExternalFilesDir(Environment.DIRECTORY_PICTURES)
        return File.createTempFile(
            "JPEG_${timeStamp}_",
            ".jpg",
            storageDir
        ).apply {
            currentPhotoPath = absolutePath
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (pendingResult == null) return false

        when (requestCode) {
            REQUEST_IMAGE_CAPTURE -> {
                if (resultCode == Activity.RESULT_OK) {
                    currentPhotoPath?.let { path ->
                        pendingResult?.success(path)
                    } ?: run {
                        pendingResult?.error("CAPTURE_ERROR", "Failed to capture image", null)
                    }
                } else {
                    pendingResult?.error("CAPTURE_CANCELLED", "Image capture cancelled", null)
                }
                pendingResult = null
                return true
            }
            REQUEST_PICK_IMAGE -> {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    val selectedImageUri = data.data
                    selectedImageUri?.let { uri ->
                        pendingResult?.success(uri.toString())
                    } ?: run {
                        pendingResult?.error("PICK_ERROR", "Failed to pick image", null)
                    }
                } else {
                    pendingResult?.error("PICK_CANCELLED", "Image pick cancelled", null)
                }
                pendingResult = null
                return true
            }
        }
        return false
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (pendingResult == null) return false

        when (requestCode) {
            REQUEST_CAMERA_PERMISSION -> {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    openCamera(pendingResult!!)
                } else {
                    pendingResult?.error("PERMISSION_DENIED", "Camera permission denied", null)
                    pendingResult = null
                }
                return true
            }
            REQUEST_STORAGE_PERMISSION -> {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    openGallery(pendingResult!!)
                } else {
                    pendingResult?.error("PERMISSION_DENIED", "Storage permission denied", null)
                    pendingResult = null
                }
                return true
            }
        }
        return false
    }
}
