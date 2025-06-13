//
//  ImageProcessingView.swift
//  MenuReader
//
//  Created by MenuReader on 2025-06-12.
//

import SwiftUI

struct ImageProcessingView: View {
    @ObservedObject var processingManager: ProcessingManager
    @Environment(\.dismiss) private var dismiss
    
    let image: UIImage
    let onComplete: (ProcessingResult) -> Void
    let onCancel: () -> Void
    
    @State private var rotationAngle: Double = 0
    @State private var scaleEffect: CGFloat = 1.0
    @State private var showCancelAlert = false
    
    var body: some View {
        ZStack {
            // 背景遮罩
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
                    // 外圈旋转指示器
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
                    Text(processingManager.statusMessage)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    if processingManager.showProgress {
                        VStack(spacing: 8) {
                            ProgressView(value: processingManager.progress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .frame(maxWidth: 200)
                            
                            Text("\(Int(processingManager.progress * 100))%")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if !processingManager.detailMessage.isEmpty {
                        Text(processingManager.detailMessage)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                
                Spacer()
                
                // 底部按钮
                VStack(spacing: 16) {
                    if processingManager.allowCancel {
                        Button(action: {
                            showCancelAlert = true
                        }) {
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
                    }
                    
                    if let error = processingManager.error {
                        VStack(spacing: 12) {
                            Text("处理失败")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            Text(error.localizedDescription)
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            HStack(spacing: 16) {
                                Button("重试") {
                                    processingManager.retryProcessing()
                                }
                                .font(.body)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                Button("取消") {
                                    onCancel()
                                }
                                .font(.body)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal, 40)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            startAnimations()
            startProcessing()
        }
        .onChange(of: processingManager.processingComplete) { complete in
            if complete, let result = processingManager.result {
                onComplete(result)
            }
        }
        .alert("确认取消", isPresented: $showCancelAlert) {
            Button("继续处理", role: .cancel) { }
            Button("确认取消", role: .destructive) {
                processingManager.cancelProcessing()
                onCancel()
            }
        } message: {
            Text("确定要取消图像处理吗？进度将会丢失。")
        }
    }
    
    // MARK: - Private Methods
    private func startAnimations() {
        withAnimation {
            rotationAngle = 360
            scaleEffect = 1.1
        }
    }
    
    private func startProcessing() {
        processingManager.startProcessing(image: image)
    }
}

// MARK: - Processing Manager
class ProcessingManager: ObservableObject {
    @Published var statusMessage = "正在分析图像..."
    @Published var detailMessage = ""
    @Published var progress: Double = 0.0
    @Published var showProgress = false
    @Published var allowCancel = true
    @Published var error: Error?
    @Published var processingComplete = false
    @Published var result: ProcessingResult?
    
    private var processingTask: Task<Void, Never>?
    private let menuAnalysisService = MenuAnalysisService.shared
    
    func startProcessing(image: UIImage) {
        resetState()
        
        processingTask = Task {
            await performProcessing(image: image)
        }
    }
    
    func cancelProcessing() {
        processingTask?.cancel()
        processingTask = nil
    }
    
    func retryProcessing() {
        guard let lastImage = result?.originalImage else { return }
        startProcessing(image: lastImage)
    }
    
    private func resetState() {
        DispatchQueue.main.async {
            self.statusMessage = "正在分析图像..."
            self.detailMessage = ""
            self.progress = 0.0
            self.showProgress = false
            self.allowCancel = true
            self.error = nil
            self.processingComplete = false
            self.result = nil
        }
    }
    
    @MainActor
    private func performProcessing(image: UIImage) async {
        do {
            // 检查API配置
            let healthStatus = await menuAnalysisService.checkServiceHealth()
            guard healthStatus.isConfigured else {
                throw ProcessingError.serviceNotConfigured
            }
            
            showProgress = true
            
            // 使用MenuAnalysisService进行处理
            let (analysisResult, searchResults) = try await menuAnalysisService.analyzeMenu(image)
            
            // 监听处理进度
            for await _ in Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().values {
                if Task.isCancelled { break }
                
                // 更新UI状态
                let stage = menuAnalysisService.currentStage
                statusMessage = stage.description
                progress = stage.progress
                
                switch stage {
                case .preprocessing:
                    detailMessage = "优化图像质量和格式"
                case .textRecognition:
                    detailMessage = "使用AI识别菜单文字"
                case .menuExtraction:
                    detailMessage = "提取菜品信息和价格"
                case .imageSearch:
                    detailMessage = "搜索菜品参考图片"
                    allowCancel = false
                case .completed:
                    detailMessage = "分析完成！"
                    break
                case .error(let message):
                    throw ProcessingError.analysisError(message)
                default:
                    break
                }
                
                if case .completed = stage {
                    break
                }
            }
            
            // 转换结果格式
            let menuItems = analysisResult.menuItems.map { analysisItem in
                MenuItem(
                    originalName: analysisItem.originalName,
                    translatedName: analysisItem.translatedName,
                    category: analysisItem.category,
                    description: analysisItem.description,
                    price: analysisItem.price,
                    confidence: analysisItem.confidence,
                    imageResults: searchResults[analysisItem.originalName] ?? []
                )
            }
            
            let result = ProcessingResult(
                originalImage: image,
                extractedText: analysisResult.extractedText,
                menuItems: menuItems,
                confidence: analysisResult.confidence,
                language: analysisResult.language,
                processingTime: analysisResult.processingTime
            )
            
            self.result = result
            processingComplete = true
            
        } catch {
            if !Task.isCancelled {
                self.error = error
                statusMessage = "处理失败"
                detailMessage = error.localizedDescription
                allowCancel = false
            }
        }
    }
}

// MARK: - Processing Errors
enum ProcessingError: LocalizedError {
    case serviceNotConfigured
    case analysisError(String)
    
    var errorDescription: String? {
        switch self {
        case .serviceNotConfigured:
            return "API服务未正确配置，请检查网络连接和API密钥"
        case .analysisError(let message):
            return "分析失败: \(message)"
        }
    }
}

// ProcessingResult is defined in Models/ProcessingTypes.swift

#Preview {
    ImageProcessingView(
        processingManager: ProcessingManager(),
        image: UIImage(systemName: "photo")!,
        onComplete: { _ in },
        onCancel: { }
    )
} 