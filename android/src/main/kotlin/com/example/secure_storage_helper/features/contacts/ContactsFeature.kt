package com.example.secure_storage_helper.features.contacts

import android.Manifest
import android.app.Activity
import android.content.ContentResolver
import android.content.ContentValues
import android.content.pm.PackageManager
import android.database.Cursor
import android.provider.ContactsContract
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class ContactsFeature : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private var pendingMethod: String? = null
    private var pendingCall: MethodCall? = null

    companion object {
        private const val CHANNEL_NAME = "secure_storage_helper/contacts"
        private const val REQUEST_CONTACTS_PERMISSION = 200
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
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getContacts" -> {
                handleGetContacts(result)
            }
            "addContact" -> {
                handleAddContact(call, result)
            }
            "requestPermission" -> {
                handleRequestPermission(result)
            }
            "hasPermission" -> {
                handleHasPermission(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleGetContacts(result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "No activity available", null)
            return
        }

        if (!hasContactsPermission()) {
            pendingResult = result
            pendingMethod = "getContacts"
            requestContactsPermission()
            return
        }

        getContacts(result)
    }

    private fun handleAddContact(call: MethodCall, result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "No activity available", null)
            return
        }

        if (!hasContactsPermission()) {
            pendingResult = result
            pendingMethod = "addContact"
            pendingCall = call
            requestContactsPermission()
            return
        }

        addContact(call, result)
    }

    private fun handleRequestPermission(result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "No activity available", null)
            return
        }

        if (hasContactsPermission()) {
            result.success(true)
            return
        }

        pendingResult = result
        pendingMethod = "requestPermission"
        requestContactsPermission()
    }

    private fun handleHasPermission(result: Result) {
        result.success(hasContactsPermission())
    }

    private fun hasContactsPermission(): Boolean {
        val currentActivity = activity ?: return false
        return ContextCompat.checkSelfPermission(currentActivity, Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED &&
               ContextCompat.checkSelfPermission(currentActivity, Manifest.permission.WRITE_CONTACTS) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestContactsPermission() {
        val currentActivity = activity ?: return
        ActivityCompat.requestPermissions(
            currentActivity,
            arrayOf(Manifest.permission.READ_CONTACTS, Manifest.permission.WRITE_CONTACTS),
            REQUEST_CONTACTS_PERMISSION
        )
    }

    private fun getContacts(result: Result) {
        val currentActivity = activity ?: return
        val contentResolver = currentActivity.contentResolver
        val contacts = mutableListOf<Map<String, Any>>()

        val cursor: Cursor? = contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            null,
            null,
            null,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME + " ASC"
        )

        cursor?.use {
            val nameIndex = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
            val numberIndex = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
            val contactIdIndex = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.CONTACT_ID)

            while (it.moveToNext()) {
                val contactId = it.getString(contactIdIndex)
                val name = it.getString(nameIndex) ?: ""
                val phoneNumber = it.getString(numberIndex) ?: ""

                // Get email addresses for this contact
                val emailCursor = contentResolver.query(
                    ContactsContract.CommonDataKinds.Email.CONTENT_URI,
                    null,
                    ContactsContract.CommonDataKinds.Email.CONTACT_ID + " = ?",
                    arrayOf(contactId),
                    null
                )

                val emailAddresses = mutableListOf<String>()
                emailCursor?.use { emailCur ->
                    val emailIndex = emailCur.getColumnIndex(ContactsContract.CommonDataKinds.Email.DATA)
                    while (emailCur.moveToNext()) {
                        val email = emailCur.getString(emailIndex)
                        if (email != null) {
                            emailAddresses.add(email)
                        }
                    }
                }

                val nameParts = name.split(" ")
                val firstName = nameParts.firstOrNull() ?: ""
                val lastName = if (nameParts.size > 1) nameParts.drop(1).joinToString(" ") else ""

                val contact = mapOf(
                    "displayName" to name,
                    "givenName" to firstName,
                    "familyName" to lastName,
                    "phoneNumbers" to listOf(phoneNumber),
                    "emailAddresses" to emailAddresses
                )

                contacts.add(contact)
            }
        }

        result.success(contacts)
    }

    private fun addContact(call: MethodCall, result: Result) {
        val currentActivity = activity ?: return
        val contentResolver = currentActivity.contentResolver

        val firstName = call.argument<String>("firstName") ?: ""
        val lastName = call.argument<String>("lastName") ?: ""
        val phoneNumber = call.argument<String>("phoneNumber")
        val email = call.argument<String>("email")

        val displayName = "$firstName $lastName".trim()

        try {
            val values = ContentValues().apply {
                put(ContactsContract.RawContacts.ACCOUNT_TYPE, null as String?)
                put(ContactsContract.RawContacts.ACCOUNT_NAME, null as String?)
            }

            val rawContactUri = contentResolver.insert(ContactsContract.RawContacts.CONTENT_URI, values)
            val rawContactId = rawContactUri?.lastPathSegment?.toLong() ?: 0

            // Insert name
            val nameValues = ContentValues().apply {
                put(ContactsContract.Data.RAW_CONTACT_ID, rawContactId)
                put(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
                put(ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME, displayName)
                put(ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME, firstName)
                put(ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME, lastName)
            }
            contentResolver.insert(ContactsContract.Data.CONTENT_URI, nameValues)

            // Insert phone number if provided
            phoneNumber?.let {
                val phoneValues = ContentValues().apply {
                    put(ContactsContract.Data.RAW_CONTACT_ID, rawContactId)
                    put(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                    put(ContactsContract.CommonDataKinds.Phone.NUMBER, it)
                    put(ContactsContract.CommonDataKinds.Phone.TYPE, ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE)
                }
                contentResolver.insert(ContactsContract.Data.CONTENT_URI, phoneValues)
            }

            // Insert email if provided
            email?.let {
                val emailValues = ContentValues().apply {
                    put(ContactsContract.Data.RAW_CONTACT_ID, rawContactId)
                    put(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE)
                    put(ContactsContract.CommonDataKinds.Email.DATA, it)
                    put(ContactsContract.CommonDataKinds.Email.TYPE, ContactsContract.CommonDataKinds.Email.TYPE_HOME)
                }
                contentResolver.insert(ContactsContract.Data.CONTENT_URI, emailValues)
            }

            result.success(null)
        } catch (e: Exception) {
            result.error("ADD_CONTACT_ERROR", "Failed to add contact: ${e.message}", null)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode == REQUEST_CONTACTS_PERMISSION) {
            val permissionGranted = grantResults.isNotEmpty() && 
                grantResults.all { it == PackageManager.PERMISSION_GRANTED }

            when (pendingMethod) {
                "getContacts" -> {
                    if (permissionGranted) {
                        getContacts(pendingResult!!)
                    } else {
                        pendingResult?.error("PERMISSION_DENIED", "Contacts permission denied", null)
                    }
                }
                "addContact" -> {
                    if (permissionGranted) {
                        addContact(pendingCall!!, pendingResult!!)
                    } else {
                        pendingResult?.error("PERMISSION_DENIED", "Contacts permission denied", null)
                    }
                }
                "requestPermission" -> {
                    pendingResult?.success(permissionGranted)
                }
            }

            pendingResult = null
            pendingMethod = null
            pendingCall = null
            return true
        }
        return false
    }
}
