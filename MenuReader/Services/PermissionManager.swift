//
//  PermissionManager.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import Foundation
import AVFoundation
import Photos
import SwiftUI

// MARK: - Permission Manager
class PermissionManager: ObservableObject, @unchecked Sendable {
    static let shared = PermissionManager()
    
    @Published var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var photoLibraryPermissionStatus: PHAuthorizationStatus = .notDetermined
    
    private init() {
        updatePermissionStatuses()
    }
    
    // MARK: - Permission Status Updates
    func updatePermissionStatuses() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        photoLibraryPermissionStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    // MARK: - Camera Permission
    func requestCameraPermission() async -> Bool {
        switch cameraPermissionStatus {
        case .authorized:
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                updatePermissionStatuses()
            }
            return granted
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    var cameraPermissionGranted: Bool {
        return cameraPermissionStatus == .authorized
    }
    
    // MARK: - Photo Library Permission
    func requestPhotoLibraryPermission() async -> Bool {
        switch photoLibraryPermissionStatus {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            await MainActor.run {
                updatePermissionStatuses()
            }
            return status == .authorized || status == .limited
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    var photoLibraryPermissionGranted: Bool {
        return photoLibraryPermissionStatus == .authorized || photoLibraryPermissionStatus == .limited
    }
    
    // MARK: - Settings Navigation
    @MainActor
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
} 