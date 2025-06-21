//
//  PhotoPickerView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI
import UIKit

// MARK: - Photo Picker View
struct PhotoPickerView: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        PhotoLibraryPicker(selectedImage: $selectedImage) {
            dismiss()
        }
    }
}

// MARK: - Photo Library Picker
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoLibraryPicker
        
        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            print("📸 [PhotoPickerView] 用户选择了照片")
            
            if let image = info[.originalImage] as? UIImage {
                print("✅ [PhotoPickerView] 照片获取成功")
                DispatchQueue.main.async {
                    self.parent.selectedImage = image
                    self.parent.onDismiss()
                }
            } else {
                print("❌ [PhotoPickerView] 照片获取失败")
                DispatchQueue.main.async {
                    self.parent.onDismiss()
                }
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("📸 [PhotoPickerView] 用户取消了照片选择")
            DispatchQueue.main.async {
                self.parent.onDismiss()
            }
        }
    }
}

#Preview {
    PhotoPickerView(selectedImage: .constant(nil))
} 
