//
//  PhotoPreviewView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI

struct PhotoPreviewView: View {
    let image: UIImage
    let onRetake: () -> Void
    
    // 分析服务
    @StateObject private var menuAnalysisService = MenuAnalysisService.shared
    @StateObject private var offlineManager = OfflineManager.shared
    @EnvironmentObject var cartManager: CartManager
    
    // 分析状态管理
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    
    // 分析结果
    @State private var analysisResult: MenuAnalysisResult?
    @State private var dishImages: [String: [DishImage]] = [:]
    @State private var showAnalysisResult = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color.black
                    .ignoresSafeArea()
                
                // 全屏图片预览
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                    .ignoresSafeArea()
                
                // 底部按钮区域 - 只在非分析状态时显示
                if !isAnalyzing {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 0) {
                            // Cancel 按钮
                            Button(action: onRetake) {
                                Text("Cancel")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                            
                            // Choose 按钮
                            Button(action: {
                                Task {
                                    await startCompleteAnalysis()
                                }
                            }) {
                                Text("Choose")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.yellow)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                        }
                        .background(Color.black.opacity(0.8))
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                    }
                }
                
                // 分析进度弹窗
                if isAnalyzing {
                    ZStack {
                        Color.black.opacity(0.7)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            VStack(spacing: 8) {
                                Text("正在分析菜单...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(menuAnalysisService.currentStage.description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                ProgressView(value: menuAnalysisService.analysisProgress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                    .frame(width: 200)
                            }
                        }
                        .padding(30)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(16)
                    }
                    .transition(.opacity)
                }
                
                // 错误处理
                if let error = analysisError {
                    VStack {
                        Spacer()
                        
                        ErrorBannerView(
                            error: error,
                            onRetry: {
                                Task {
                                    await startCompleteAnalysis()
                                }
                            },
                            onDismiss: {
                                analysisError = nil
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .statusBarHidden(true)
        .fullScreenCover(isPresented: $showAnalysisResult) {
            if let result = analysisResult {
                NavigationStack {
                    CategorizedMenuView(
                        analysisResult: result,
                        dishImages: dishImages,
                        onDismiss: {
                            showAnalysisResult = false
                            onRetake()
                        }
                    )
                    .navigationDestination(for: String.self) { destination in
                        switch destination {
                        case "cart":
                            CartView(cartItems: $cartManager.cartItems)
                        default:
                            EmptyView()
                        }
                    }
                }
                .environmentObject(cartManager)
            }
        }
    }
    
    private func startCompleteAnalysis() async {
        print("🔄 PhotoPreviewView: 开始完整的菜单分析...")
        
        isAnalyzing = true
        analysisError = nil
        
        do {
            // 检查网络状态
            if offlineManager.isOfflineMode {
                analysisError = "当前处于离线状态，无法进行在线图片搜索。您可以继续拍照，数据将保存在本地，网络恢复后可同步。"
                isAnalyzing = false
                return
            }
            
            print("📞 调用 menuAnalysisService.analyzeMenuWithDishImages...")
            let (result, images) = try await menuAnalysisService.analyzeMenuWithDishImages(image)
            
            // 为历史记录创建缩略图
            let thumbnailData = image.jpegData(compressionQuality: 0.2)
            
            await MainActor.run {
                print("✅ 分析完成！识别到 \(result.items.count) 个菜品")
                print("🖼️ 获取到 \(images.count) 组菜品图片")
                
                analysisResult = result
                dishImages = images
                isAnalyzing = false
                
                // 保存到历史记录
                let historyEntry = MenuProcessResult(
                    id: UUID(),
                    scanDate: Date(),
                    thumbnailData: thumbnailData,
                    items: result.items,
                    dishImages: self.dishImages
                )
                StorageService.shared.saveMenuHistory(historyEntry)
                
                // 显示结果页面
                showAnalysisResult = true
                
                // 清除错误
                analysisError = nil
            }
            
        } catch {
            await MainActor.run {
                print("❌ 菜单分析失败: \(error)")
                isAnalyzing = false
                analysisError = getUserFriendlyErrorMessage(from: error)
            }
        }
    }
    
    private func getUserFriendlyErrorMessage(from error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("network") || errorDescription.contains("连接") {
            return "网络连接出现问题，请检查网络设置后重试"
        } else if errorDescription.contains("timeout") || errorDescription.contains("超时") {
            return "请求超时，请检查网络连接或稍后重试"
        } else if errorDescription.contains("unauthorized") || errorDescription.contains("401") {
            return "服务认证失败，请检查应用配置"
        } else if errorDescription.contains("rate limit") || errorDescription.contains("429") {
            return "请求过于频繁，请稍后再试"
        } else if errorDescription.contains("server") || errorDescription.contains("500") {
            return "服务器暂时不可用，请稍后重试"
        } else if errorDescription.contains("parse") || errorDescription.contains("解析") {
            return "数据处理失败，请重试或选择其他图片"
        } else {
            return "分析过程遇到问题，请重试。如果问题持续存在，请联系客服"
        }
    }
}

#Preview {
    PhotoPreviewView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        onRetake: { }
    )
} 