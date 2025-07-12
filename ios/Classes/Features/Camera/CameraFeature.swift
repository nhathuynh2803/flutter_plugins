import Flutter
import UIKit
import AVFoundation
import Photos

public class CameraFeature: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    private var presentingViewController: UIViewController?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "secure_storage_helper/camera", binaryMessenger: registrar.messenger())
        let instance = CameraFeature()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "takePicture":
            handleTakePicture(result: result)
        case "pickImageFromGallery":
            handlePickImageFromGallery(result: result)
        case "hasCamera":
            handleHasCamera(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleTakePicture(result: @escaping FlutterResult) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            result(FlutterError(code: "CAMERA_NOT_AVAILABLE", message: "Camera not available", details: nil))
            return
        }
        
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authStatus == .denied || authStatus == .restricted {
            result(FlutterError(code: "CAMERA_PERMISSION_DENIED", message: "Camera permission denied", details: nil))
            return
        }
        
        DispatchQueue.main.async {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = false
            
            if let viewController = UIApplication.shared.windows.first?.rootViewController {
                self.presentingViewController = viewController
                viewController.present(picker, animated: true, completion: nil)
                
                // Store result callback
                self.pendingResult = result
            } else {
                result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No view controller to present camera", details: nil))
            }
        }
    }
    
    private func handlePickImageFromGallery(result: @escaping FlutterResult) {
        let authStatus = PHPhotoLibrary.authorizationStatus()
        if authStatus == .denied || authStatus == .restricted {
            result(FlutterError(code: "PHOTO_PERMISSION_DENIED", message: "Photo library permission denied", details: nil))
            return
        }
        
        DispatchQueue.main.async {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = false
            
            if let viewController = UIApplication.shared.windows.first?.rootViewController {
                self.presentingViewController = viewController
                viewController.present(picker, animated: true, completion: nil)
                
                // Store result callback
                self.pendingResult = result
            } else {
                result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No view controller to present photo library", details: nil))
            }
        }
    }
    
    private func handleHasCamera(result: @escaping FlutterResult) {
        let hasCamera = UIImagePickerController.isSourceTypeAvailable(.camera)
        result(hasCamera)
    }
    
    private var pendingResult: FlutterResult?
    
    private func saveImageToDocuments(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "camera_image_\(Date().timeIntervalSince1970).jpg"
        let filePath = documentsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: filePath)
            return filePath.path
        } catch {
            return nil
        }
    }
}

extension CameraFeature: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[.originalImage] as? UIImage else {
            pendingResult?(FlutterError(code: "IMAGE_PROCESSING_ERROR", message: "Failed to process image", details: nil))
            pendingResult = nil
            return
        }
        
        if let imagePath = saveImageToDocuments(image) {
            pendingResult?(imagePath)
        } else {
            pendingResult?(FlutterError(code: "IMAGE_SAVE_ERROR", message: "Failed to save image", details: nil))
        }
        
        pendingResult = nil
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        pendingResult?(nil)
        pendingResult = nil
    }
}
