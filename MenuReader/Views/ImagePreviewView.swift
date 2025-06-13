//
//  ImagePreviewView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI
import UIKit

struct ImagePreviewView: View {
    let image: UIImage
    let onConfirm: () -> Void
    let onRetake: () -> Void
    
    @State private var showProcessingView = false
    @State private var processingProgress: Double = 0.0
    @State private var processingMessage = "正在分析图像..."
    @State private var showMockResult = false
    
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
        .fullScreenCover(isPresented: $showMockResult) {
            MockResultView(
                image: image,
                onDone: {
                    showMockResult = false
                    onConfirm()
                }
            )
        }
    }
    
    // MARK: - Private Methods
    private func startProcessing() {
        showProcessingView = true
        simulateProcessing()
    }
    
    private func simulateProcessing() {
        // 模拟处理过程
        let steps = [
            (0.2, "正在分析图像..."),
            (0.4, "识别菜单文字..."),
            (0.6, "提取菜品信息..."),
            (0.8, "搜索参考图片..."),
            (1.0, "处理完成！")
        ]
        
        Task { @MainActor in
            for (_, step) in steps.enumerated() {
                let (progress, message) = step
                
                withAnimation(.easeInOut(duration: 0.5)) {
                    processingProgress = progress
                    processingMessage = message
                }
                
                // 等待1秒再进行下一步
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            
            // 延迟一下显示结果
            try? await Task.sleep(nanoseconds: 500_000_000)
            showProcessingView = false
            showMockResult = true
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

// MARK: - Mock Result View
struct MockResultView: View {
    let image: UIImage
    let onDone: () -> Void
    
    // 模拟数据
    private let mockMenuItems = [
        MockMenuItem(name: "宫保鸡丁", translation: "Kung Pao Chicken", price: "¥28"),
        MockMenuItem(name: "麻婆豆腐", translation: "Mapo Tofu", price: "¥18"),
        MockMenuItem(name: "红烧肉", translation: "Braised Pork", price: "¥35"),
        MockMenuItem(name: "西湖醋鱼", translation: "West Lake Fish", price: "¥45")
    ]
    
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
                        
                        // 置信度显示
                        HStack {
                            Text("识别准确度:")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("95%")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 20)
                        
                        // 识别的菜单项
                        VStack(alignment: .leading, spacing: 12) {
                            Text("识别到的菜品:")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(mockMenuItems) { item in
                                    MockMenuItemRow(item: item)
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("处理结果")
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

// MARK: - Mock Data Models
struct MockMenuItem: Identifiable {
    let id = UUID()
    let name: String
    let translation: String
    let price: String
}

struct MockMenuItemRow: View {
    let item: MockMenuItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(item.translation)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(item.price)
                .font(.headline)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
        .padding(.horizontal, 20)
    }
}

#Preview {
    ImagePreviewView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        onConfirm: { },
        onRetake: { }
    )
} 