//
//  DishImageDemoView.swift
//  MenuReader
//
//  Created by MenuReader on 2025-06-13.
//

import SwiftUI

/// Task005演示视图 - 展示菜品图片检索功能
struct DishImageDemoView: View {
    @StateObject private var menuAnalysisService = MenuAnalysisService.shared
    @StateObject private var imageService = ImageService.shared
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var analysisResult: MenuAnalysisResult?
    @State private var dishImages: [String: [DishImage]] = [:]
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 标题和说明
                    headerSection
                    
                    // 图片选择区域
                    imageSelectionSection
                    
                    // 分析结果
                    if let result = analysisResult {
                        analysisResultSection(result)
                    }
                    
                    // 错误信息
                    if let error = errorMessage {
                        errorSection(error)
                    }
                }
                .padding()
            }
            .navigationTitle("菜品图片检索")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingImagePicker) {
                DemoImagePicker(selectedImage: $selectedImage)
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    Task {
                        await analyzeMenuWithImages(image)
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Task005: 菜品图片检索服务")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("上传菜单图片，系统将识别菜品并自动搜索相关图片")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var imageSelectionSection: some View {
        VStack(spacing: 16) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
                    .shadow(radius: 4)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay {
                        VStack {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("点击选择菜单图片")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
            }
            
            Button(action: {
                showingImagePicker = true
            }) {
                Label(selectedImage == nil ? "选择图片" : "更换图片", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            if isAnalyzing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(menuAnalysisService.currentStage.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
    
    private func analysisResultSection(_ result: MenuAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("识别结果")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("识别到 \(result.items.count) 个菜品")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(result.items) { item in
                dishItemView(item)
            }
        }
    }
    
    private func dishItemView(_ item: MenuItemAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 菜品信息
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.originalName)
                        .font(.headline)
                    
                    if let translatedName = item.translatedName {
                        Text(translatedName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let price = item.price {
                        Text(price)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                // 置信度
                Text("\(Int(item.confidence * 100))%")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // 菜品图片
            dishImagesView(for: item)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func dishImagesView(for item: MenuItemAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("参考图片")
                .font(.subheadline)
                .fontWeight(.medium)
            
            let loadingState = imageService.getLoadingState(for: item)
            DishImageLoadingView(loadingState: loadingState, menuItemName: item.originalName)
        }
    }
    
    private func errorSection(_ error: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
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
    
    // MARK: - Methods
    
    private func analyzeMenuWithImages(_ image: UIImage) async {
        print("🚀 开始分析菜单图片...")
        print("🔑 API配置检查:")
        print("   Gemini API Key: \(APIConfig.geminiAPIKey.isEmpty ? "❌ 空" : "✅ 已设置 (长度: \(APIConfig.geminiAPIKey.count))")")
        print("   Google Search API Key: \(APIConfig.googleSearchAPIKey.isEmpty ? "❌ 空" : "✅ 已设置 (长度: \(APIConfig.googleSearchAPIKey.count))")")
        print("   Google Search Engine ID: \(APIConfig.googleSearchEngineId.isEmpty ? "❌ 空" : "✅ 已设置 (长度: \(APIConfig.googleSearchEngineId.count))")")
        print("   配置状态: \(APIConfig.isConfigured ? "✅ 完整" : "❌ 不完整")")
        
        isAnalyzing = true
        errorMessage = nil
        analysisResult = nil
        dishImages = [:]
        
        do {
            print("📞 调用 menuAnalysisService.analyzeMenuWithDishImages...")
            let (result, images) = try await menuAnalysisService.analyzeMenuWithDishImages(image)
            print("✅ 分析完成，识别到 \(result.items.count) 个菜品")
            print("🖼️ 获取到 \(images.count) 组图片")
            
            await MainActor.run {
                print("🎯 更新UI状态...")
                analysisResult = result
                dishImages = images
                isAnalyzing = false
                print("✅ UI更新完成")
            }
            
        } catch {
            print("❌ 分析失败: \(error)")
            print("❌ 错误类型: \(type(of: error))")
            print("❌ 错误描述: \(error.localizedDescription)")
            
            await MainActor.run {
                errorMessage = error.localizedDescription
                isAnalyzing = false
                print("🔄 错误状态已更新到UI")
            }
        }
    }
}

// MARK: - Demo Image Picker

struct DemoImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
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
        let parent: DemoImagePicker
        
        init(_ parent: DemoImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    DishImageDemoView()
} 