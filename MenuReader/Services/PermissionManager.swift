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
        print("📸 [PermissionManager] 请求相册权限，当前状态: \(photoLibraryPermissionStatus)")
        
        switch photoLibraryPermissionStatus {
        case .authorized, .limited:
            print("✅ [PermissionManager] 相册权限已授权")
            return true
        case .notDetermined:
            print("🔄 [PermissionManager] 相册权限未确定，发起请求")
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            print("📝 [PermissionManager] 相册权限请求结果: \(status)")
            await MainActor.run {
                photoLibraryPermissionStatus = status
            }
            let granted = status == .authorized || status == .limited
            print(granted ? "✅ [PermissionManager] 相册权限授权成功" : "❌ [PermissionManager] 相册权限授权失败")
            return granted
        case .denied, .restricted:
            print("❌ [PermissionManager] 相册权限被拒绝或受限")
            return false
        @unknown default:
            print("⚠️ [PermissionManager] 相册权限状态未知")
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