//
//  OCRProcessingView.swift
//  MenuReader
//
//  Created by MenuReader on 2025-06-13.
//

import SwiftUI

/// OCR处理界面
struct OCRProcessingView: View {
    @StateObject private var processingManager = OCRProcessingManager.shared
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // 标题区域
                VStack(spacing: 8) {
                    Text("OCR 菜单识别")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("上传菜单图片，自动识别并翻译")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // 图片显示区域
                if let image = processingManager.currentImage {
                    imageDisplaySection(image)
                } else {
                    imagePlaceholderSection
                }
                
                // 处理进度区域
                if processingManager.isProcessing {
                    processingProgressSection
                } else if let result = processingManager.ocrResult {
                    resultsSection(result)
                } else if let error = processingManager.errorMessage {
                    errorSection(error)
                }
                
                Spacer()
                
                // 操作按钮
                actionButtonsSection
            }
            .padding()
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                Task {
                    await processingManager.startMockProcessing(image: image)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private func imageDisplaySection(_ image: UIImage) -> some View {
        VStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)
                .cornerRadius(12)
                .shadow(radius: 4)
            
            Button("选择其他图片") {
                showingImagePicker = true
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
    }
    
    private var imagePlaceholderSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("选择菜单图片开始识别")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button("选择图片") {
                showingImagePicker = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var processingProgressSection: some View {
        VStack(spacing: 16) {
            Text(processingManager.currentStatus.displayName)
                .font(.headline)
            
            ProgressView(value: processingManager.progress)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("\(Int(processingManager.progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func resultsSection(_ result: OCRProcessingResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("识别结果")
                    .font(.headline)
                Spacer()
                Text("置信度: \(Int(result.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if result.menuItems.isEmpty {
                Text("未识别到菜单项")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(result.menuItems, id: \.id) { item in
                        menuItemRow(item)
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func errorSection(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            Text("处理失败")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            if processingManager.isProcessing {
                Button("取消") {
                    Task {
                        await processingManager.cancelProcessing()
                    }
                }
                .buttonStyle(.bordered)
            } else {
                if processingManager.errorMessage != nil {
                    Button("重试") {
                        Task {
                            if let image = processingManager.currentImage {
                                await processingManager.startMockProcessing(image: image)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("选择新图片") {
                    showingImagePicker = true
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private func menuItemRow(_ item: MenuItemAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.originalName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if let price = item.price {
                    Text(price)
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
            
            Text(item.translatedName ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview

struct OCRProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        OCRProcessingView()
    }
} 