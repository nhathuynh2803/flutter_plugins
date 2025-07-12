import Flutter
import UIKit

public class SecureStorageFeature: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "secure_storage_helper/secure_storage", binaryMessenger: registrar.messenger())
        let instance = SecureStorageFeature()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "setString":
            handleSetString(call, result: result)
        case "getString":
            handleGetString(call, result: result)
        case "deleteKey":
            handleDeleteKey(call, result: result)
        case "deleteAll":
            handleDeleteAll(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleSetString(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String,
              let value = args["value"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for setString", details: nil))
            return
        }
        
        let keychain = Keychain()
        let success = keychain.set(value, forKey: key)
        
        if success {
            result(nil)
        } else {
            result(FlutterError(code: "KEYCHAIN_ERROR", message: "Failed to store value in keychain", details: nil))
        }
    }
    
    private func handleGetString(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for getString", details: nil))
            return
        }
        
        let keychain = Keychain()
        let value = keychain.get(key)
        result(value)
    }
    
    private func handleDeleteKey(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for deleteKey", details: nil))
            return
        }
        
        let keychain = Keychain()
        let success = keychain.delete(key)
        
        if success {
            result(nil)
        } else {
            result(FlutterError(code: "KEYCHAIN_ERROR", message: "Failed to delete key from keychain", details: nil))
        }
    }
    
    private func handleDeleteAll(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let keychain = Keychain()
        let success = keychain.deleteAll()
        
        if success {
            result(nil)
        } else {
            result(FlutterError(code: "KEYCHAIN_ERROR", message: "Failed to delete all keys from keychain", details: nil))
        }
    }
}

// Simple Keychain wrapper
class Keychain {
    func set(_ value: String, forKey key: String) -> Bool {
        let data = Data(value.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    func delete(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    func deleteAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
