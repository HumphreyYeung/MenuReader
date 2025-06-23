//
//  PhotoPickerView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI
import UIKit
import PhotosUI

// MARK: - Photo Picker View
struct PhotoPickerView: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ModernPhotoLibraryPicker(selectedImage: $selectedImage) {
            dismiss()
        }
        .preferredColorScheme(.light) // 强制使用浅色主题
    }
}

// MARK: - Modern Photo Library Picker using PHPickerViewController
struct ModernPhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        
        // 强制使用浅色主题
        picker.overrideUserInterfaceStyle = .light
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ModernPhotoLibraryPicker
        
        init(_ parent: ModernPhotoLibraryPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            print("📸 [PhotoPickerView] 用户完成选择，结果数量: \(results.count)")
            
            if let result = results.first {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                        if let uiImage = image as? UIImage {
                            print("✅ [PhotoPickerView] 照片获取成功")
                            DispatchQueue.main.async {
                                self?.parent.selectedImage = uiImage
                                self?.parent.onDismiss()
                            }
                        } else {
                            print("❌ [PhotoPickerView] 照片获取失败: \(error?.localizedDescription ?? "未知错误")")
                            DispatchQueue.main.async {
                                self?.parent.onDismiss()
                            }
                        }
                    }
                } else {
                    print("❌ [PhotoPickerView] 无法加载图片")
                    DispatchQueue.main.async {
                        self.parent.onDismiss()
                    }
                }
            } else {
                print("📸 [PhotoPickerView] 用户取消了选择")
                DispatchQueue.main.async {
                    self.parent.onDismiss()
                }
            }
        }
    }
}

#Preview {
    PhotoPickerView(selectedImage: .constant(nil))
} 
