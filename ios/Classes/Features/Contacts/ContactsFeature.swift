import Flutter
import UIKit
import Contacts

public class ContactsFeature: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "secure_storage_helper/contacts", binaryMessenger: registrar.messenger())
        let instance = ContactsFeature()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getContacts":
            handleGetContacts(result: result)
        case "addContact":
            handleAddContact(call, result: result)
        case "requestPermission":
            handleRequestPermission(result: result)
        case "hasPermission":
            handleHasPermission(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleGetContacts(result: @escaping FlutterResult) {
        let store = CNContactStore()
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        guard authStatus == .authorized else {
            result(FlutterError(code: "PERMISSION_DENIED", message: "Contacts permission denied", details: nil))
            return
        }
        
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey]
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        
        var contacts: [[String: Any]] = []
        
        do {
            try store.enumerateContacts(with: request) { (contact, _) in
                var contactDict: [String: Any] = [:]
                
                // Full name
                contactDict["displayName"] = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                contactDict["givenName"] = contact.givenName
                contactDict["familyName"] = contact.familyName
                
                // Phone numbers
                var phoneNumbers: [String] = []
                for phoneNumber in contact.phoneNumbers {
                    phoneNumbers.append(phoneNumber.value.stringValue)
                }
                contactDict["phoneNumbers"] = phoneNumbers
                
                // Email addresses
                var emailAddresses: [String] = []
                for emailAddress in contact.emailAddresses {
                    emailAddresses.append(emailAddress.value as String)
                }
                contactDict["emailAddresses"] = emailAddresses
                
                contacts.append(contactDict)
            }
            
            result(contacts)
        } catch {
            result(FlutterError(code: "FETCH_ERROR", message: "Failed to fetch contacts: \(error.localizedDescription)", details: nil))
        }
    }
    
    private func handleAddContact(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let firstName = args["firstName"] as? String,
              let lastName = args["lastName"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for addContact", details: nil))
            return
        }
        
        let store = CNContactStore()
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        guard authStatus == .authorized else {
            result(FlutterError(code: "PERMISSION_DENIED", message: "Contacts permission denied", details: nil))
            return
        }
        
        let contact = CNMutableContact()
        contact.givenName = firstName
        contact.familyName = lastName
        
        // Add phone number if provided
        if let phoneNumber = args["phoneNumber"] as? String {
            let phone = CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: phoneNumber))
            contact.phoneNumbers = [phone]
        }
        
        // Add email if provided
        if let email = args["email"] as? String {
            let emailAddress = CNLabeledValue(label: CNLabelHome, value: email as NSString)
            contact.emailAddresses = [emailAddress]
        }
        
        let saveRequest = CNSaveRequest()
        saveRequest.add(contact, toContainerWithIdentifier: nil)
        
        do {
            try store.execute(saveRequest)
            result(nil)
        } catch {
            result(FlutterError(code: "SAVE_ERROR", message: "Failed to save contact: \(error.localizedDescription)", details: nil))
        }
    }
    
    private func handleRequestPermission(result: @escaping FlutterResult) {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { (granted, error) in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "PERMISSION_ERROR", message: "Failed to request permission: \(error.localizedDescription)", details: nil))
                } else {
                    result(granted)
                }
            }
        }
    }
    
    private func handleHasPermission(result: @escaping FlutterResult) {
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        result(authStatus == .authorized)
    }
}
