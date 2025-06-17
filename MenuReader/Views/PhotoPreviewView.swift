//
//  PhotoPreviewView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI
import UIKit

struct PhotoPreviewView: View {
    let image: UIImage
    let onConfirm: () -> Void
    let onRetake: () -> Void
    
    @State private var showProcessingView = false
    @State private var processingProgress: Double = 0.0
    @State private var processingMessage = "正在分析图像..."
    @State private var showResult = false
    @State private var ocrResult: OCRProcessingResult?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color.black
                    .ignoresSafeArea()
                
                if !showProcessingView {
                    // 图片预览界面
                    VStack {
                        Spacer()
                        
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: max(geometry.size.width - 40, 100))
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
                            
                            // 确认处理按钮
                            Button(action: startProcessing) {
                                VStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.green)
                                    
                                    Text("开始处理")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                            }
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
                } else {
                    // 处理中界面
                    ProcessingView(
                        image: image,
                        progress: processingProgress,
                        message: processingMessage,
                        onCancel: {
                            showProcessingView = false
                        }
                    )
                }
            }
        }
        .statusBarHidden(true)
        .fullScreenCover(isPresented: $showResult) {
            if let result = ocrResult {
                SimpleResultView(
                    image: image,
                    result: result,
                    onDone: {
                        showResult = false
                        onConfirm()
                    }
                )
            }
        }
    }
    
    // MARK: - Private Methods
    private func startProcessing() {
        showProcessingView = true
        performRealOCR()
    }
    
    private func performRealOCR() {
        Task { @MainActor in
            let processingManager = OCRProcessingManager.shared
            
            // 开始处理
            await processingManager.startOCRProcessing(image: image)
            
                         // 监听处理状态
             var isCompleted = false
             while !isCompleted {
                 processingProgress = processingManager.progress
                 processingMessage = processingManager.currentStatus.displayName
                
                if let result = processingManager.ocrResult {
                    ocrResult = result
                    showProcessingView = false
                    showResult = true
                    isCompleted = true
                } else if processingManager.errorMessage != nil {
                    showProcessingView = false
                    isCompleted = true
                }
                
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
            }
        }
    }
}

// MARK: - Processing View
struct ProcessingView: View {
    let image: UIImage
    let progress: Double
    let message: String
    let onCancel: () -> Void
    
    @State private var rotationAngle: Double = 0
    @State private var scaleEffect: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // 图片预览（小尺寸）
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 10)
                    .scaleEffect(scaleEffect)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: scaleEffect)
                
                // 加载指示器
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.8)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(rotationAngle))
                        .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: rotationAngle)
                }
                
                // 状态文本和进度
                VStack(spacing: 12) {
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 8) {
                        ProgressView(value: progress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .frame(maxWidth: 200)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // 取消按钮
                if progress < 0.8 {
                    Button(action: onCancel) {
                        HStack {
                            Image(systemName: "xmark")
                            Text("取消处理")
                        }
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            withAnimation {
                rotationAngle = 360
                scaleEffect = 1.1
            }
        }
    }
}

// MARK: - Simple Result View
struct SimpleResultView: View {
    let image: UIImage
    let result: OCRProcessingResult
    let onDone: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 处理结果图片
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                        
                        // 识别结果统计
                        HStack {
                            VStack(alignment: .leading) {
                                Text("识别准确度")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("\(Int(result.confidence * 100))%")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("菜品数量")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("\(result.menuItems.count)项")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 分类菜品列表
                        if !result.menuItems.isEmpty {
                            let categorizedItems = Dictionary(grouping: result.menuItems) { item in
                                item.category ?? "其他"
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("识别到的菜品:")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                
                                LazyVStack(spacing: 16) {
                                    ForEach(categorizedItems.keys.sorted(), id: \.self) { category in
                                        if let items = categorizedItems[category], !items.isEmpty {
                                            SimplePhotoPreviewCategorySection(
                                                category: category,
                                                items: items
                                            )
                                        }
                                    }
                                }
                            }
                        } else {
                            Text("未识别到菜品信息")
                                .font(.headline)
                                .foregroundColor(.orange)
                                .padding()
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("识别结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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

// MARK: - Photo Preview Category Section

struct SimplePhotoPreviewCategorySection: View {
    let category: String
    let items: [MenuItemAnalysis]
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 可点击的分类标题
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // 展开/收起图标
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    
                    // 分类名称
                    Text(category)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // 菜品数量标签
                    Text("\(items.count)道菜")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(6)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 菜品卡片（可折叠）
            if isExpanded {
                LazyVStack(spacing: 8) {
                    ForEach(items, id: \.id) { item in
                        UnifiedDishCard(
                            menuItem: item,
                            dishImages: [] // PhotoPreviewView 默认没有搜索图片
                        )
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    PhotoPreviewView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        onConfirm: { },
        onRetake: { }
    )
} 