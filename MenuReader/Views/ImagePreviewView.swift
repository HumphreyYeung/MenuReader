//
//  ImagePreviewView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI

struct ImagePreviewView: View {
    let image: UIImage
    let onConfirm: () -> Void
    let onRetake: () -> Void
    
    @State private var showProcessingView = false
    @State private var processingManager = ProcessingManager()
    @State private var processingResult: ProcessingResult?
    @State private var showResultView = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color.black
                    .ignoresSafeArea()
                
                // 图片显示
                VStack {
                    Spacer()
                    
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: geometry.size.width - 40)
                        .cornerRadius(12)
                    
                    Spacer()
                }
                
                // 底部按钮区域
                VStack {
                    Spacer()
                    
                    HStack(spacing: 40) {
                        // 重拍/重选按钮
                        Button(action: onRetake) {
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                                
                                Text("重拍")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(showProcessingView)
                        
                        // 确认处理按钮
                        Button(action: {
                            startProcessing()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.green)
                                
                                Text("开始处理")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(showProcessingView)
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 40)
                }
                
                // 顶部关闭按钮
                VStack {
                    HStack {
                        Button(action: onRetake) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 20)
                        .padding(.top, geometry.safeAreaInsets.top + 10)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
            }
        }
        .statusBarHidden(true)
        .fullScreenCover(isPresented: $showProcessingView) {
            ImageProcessingView(
                processingManager: processingManager,
                image: image,
                onComplete: handleProcessingComplete,
                onCancel: handleProcessingCancel
            )
        }
        .fullScreenCover(isPresented: $showResultView) {
            if let result = processingResult {
                ProcessingResultView(
                    result: result,
                    onDone: {
                        showResultView = false
                        onConfirm() // 通知完成整个流程
                    },
                    onRetry: {
                        showResultView = false
                        showProcessingView = true
                        // 重置处理器状态
                        processingManager = ProcessingManager()
                    }
                )
            }
        }
    }
    
    // MARK: - Private Methods
    private func startProcessing() {
        showProcessingView = true
    }
    
    private func handleProcessingComplete(_ result: ProcessingResult) {
        processingResult = result
        showProcessingView = false
        showResultView = true
    }
    
    private func handleProcessingCancel() {
        showProcessingView = false
        processingManager = ProcessingManager() // 重置状态
    }
}

// MARK: - Processing Result View
struct ProcessingResultView: View {
    let result: ProcessingResult
    let onDone: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 处理结果图片
                        Image(uiImage: result.originalImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                        
                        // 置信度显示
                        HStack {
                            Text("识别准确度:")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(Int(result.confidence * 100))%")
                                .font(.headline)
                                .foregroundColor(result.confidence > 0.8 ? .green : .orange)
                        }
                        .padding(.horizontal, 20)
                        
                        // 识别的菜单项
                        VStack(alignment: .leading, spacing: 12) {
                            Text("识别到的菜品:")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(result.menuItems) { item in
                                    MenuItemRow(item: item)
                                }
                            }
                        }
                        
                        // 原始提取文本
                        if !result.extractedText.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("提取的文本:")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                
                                Text(result.extractedText)
                                    .font(.body)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 20)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("处理结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("重试") {
                        onRetry()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        onDone()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Menu Item Row Component
struct MenuItemRow: View {
    let item: MenuItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.originalName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if let category = item.category {
                    Text(category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(8)
                        .foregroundColor(.blue)
                }
            }
            
            Text(item.translatedName ?? "翻译中...")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if item.hasAllergens {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("包含过敏原: \(item.allergenTypes.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 20)
    }
}

#Preview {
    ImagePreviewView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        onConfirm: {},
        onRetake: {}
    )
} 