//
//  CameraManager.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import Foundation
import AVFoundation
import UIKit
import SwiftUI

// MARK: - Camera Settings

// MARK: - Camera Manager
@MainActor
class CameraManager: NSObject, ObservableObject {
    @Published var isCameraAvailable = false
    @Published var isConfigured = false
    @Published var capturedImage: UIImage?
    @Published var isCapturing = false
    
    // Camera Settings
    @Published var exposureValue: Float = 0.0 {
        didSet { saveSettings(); updateExposure() }
    }
    
    // AVFoundation components
    private let captureSession = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var currentDevice: AVCaptureDevice?
    
    override init() {
        super.init()
        isCameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        loadSettings()
    }
    
    // MARK: - Settings Persistence
    private func saveSettings() {
        UserDefaults.standard.set(exposureValue, forKey: "camera_exposure_value")
    }
    
    private func loadSettings() {
        exposureValue = UserDefaults.standard.float(forKey: "camera_exposure_value")
    }
    
    func configureCameraSession() async {
        guard !isConfigured && isCameraAvailable else { return }
        
        captureSession.beginConfiguration()
        
        // Configure session preset
        if captureSession.canSetSessionPreset(.photo) {
            captureSession.sessionPreset = .photo
        }
        
        // Add video input
        await addVideoInput()
        
        // Add photo output
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            
            if #available(iOS 16.0, *) {
                photoOutput.maxPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024)
            } else {
                photoOutput.isHighResolutionCaptureEnabled = true
            }
            photoOutput.maxPhotoQualityPrioritization = .quality
        }
        
        captureSession.commitConfiguration()
        
        await MainActor.run {
            isConfigured = true
        }
        
        // Apply initial settings
        updateExposure()
    }
    
    private func addVideoInput() async {
        do {
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            
            guard let videoDevice = videoDevice else {
                print("无法获取后置摄像头")
                captureSession.commitConfiguration()
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                self.currentDevice = videoDevice
            }
        } catch {
            print("无法创建视频输入: \(error)")
        }
    }
    
    func startSession() {
        guard isConfigured && !captureSession.isRunning else { return }
        captureSession.startRunning()
    }
    
    func stopSession() {
        guard captureSession.isRunning else { return }
        captureSession.stopRunning()
    }
    
    // MARK: - Preview Layer
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        if videoPreviewLayer == nil {
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
        }
        return videoPreviewLayer!
    }
    
    // MARK: - Photo Capture
    func capturePhoto() {
        guard isConfigured && !isCapturing else { return }
        
        isCapturing = true
        
        let photoSettings = AVCapturePhotoSettings()
        
        if let _ = videoDeviceInput,
           photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0 {
            photoSettings.previewPhotoFormat = [
                kCVPixelBufferPixelFormatTypeKey as String: photoSettings.availablePreviewPhotoPixelFormatTypes.first!,
                kCVPixelBufferWidthKey as String: 160,
                kCVPixelBufferHeightKey as String: 160
            ]
        }
        
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    // MARK: - Camera Controls
    
    private func updateExposure() {
        guard let device = currentDevice else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.isExposureModeSupported(.custom) {
                let exposureBias = AVCaptureDevice.ExposureMode.continuousAutoExposure
                device.exposureMode = exposureBias
                device.setExposureTargetBias(exposureValue, completionHandler: nil)
            }
            
            device.unlockForConfiguration()
        } catch {
            print("无法设置曝光: \(error)")
        }
    }
    
    // MARK: - Public Control Methods
    
    func adjustExposure(_ value: Float) {
        exposureValue = max(-2.0, min(2.0, value))
    }
    
    func resetExposure() {
        exposureValue = 0.0
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // 在nonisolated上下文中提取数据
        let imageData = photo.fileDataRepresentation()
        
        Task { @MainActor in
            isCapturing = false
            
            if let error = error {
                print("拍照失败: \(error)")
                return
            }
            
            guard let imageData = imageData,
                  let image = UIImage(data: imageData) else {
                print("无法获取图片数据")
                return
            }
            
            // 修正图片方向
            let correctedImage = image.fixOrientation()
            capturedImage = correctedImage
        }
    }
}

// MARK: - UIImage Extension for Orientation Fix
extension UIImage {
    func fixOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
            
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
            
        default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        default:
            break
        }
        
        guard let cgImage = cgImage else { return self }
        
        let context = CGContext(data: nil,
                               width: Int(size.width),
                               height: Int(size.height),
                               bitsPerComponent: cgImage.bitsPerComponent,
                               bytesPerRow: 0,
                               space: cgImage.colorSpace!,
                               bitmapInfo: cgImage.bitmapInfo.rawValue)
        
        context?.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        guard let newCGImage = context?.makeImage() else { return self }
        return UIImage(cgImage: newCGImage)
    }
} 
