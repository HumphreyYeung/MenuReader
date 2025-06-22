//
//  MenuAnalysisService.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import Foundation
import UIKit

@MainActor
class MenuAnalysisService: ObservableObject {
    static let shared = MenuAnalysisService()
    
    private let geminiService: GeminiService
    private let googleSearchService: GoogleSearchService
    
    @Published var isAnalyzing: Bool = false
    @Published var analysisProgress: Double = 0.0
    @Published var currentStage: AnalysisStage = .idle
    @Published var lastAnalysisResult: MenuAnalysisResult?
    @Published var lastSearchResults: [String: [ImageSearchResult]] = [:]
    @Published var lastDishImages: [String: [DishImage]] = [:]
    
    private init() {
        self.geminiService = GeminiService.shared
        self.googleSearchService = GoogleSearchService.shared
    }
    
    // MARK: - Analysis Stages
    enum AnalysisStage {
        case idle
        case preprocessing
        case textRecognition
        case menuExtraction
        case imageSearch
        case completed
        case error(String)
        
        var description: String {
            switch self {
            case .idle:
                return "准备中"
            case .preprocessing:
                return "预处理图片"
            case .textRecognition:
                return "识别文字内容"
            case .menuExtraction:
                return "分析菜品信息"
            case .imageSearch:
                return "搜索菜品图片"
            case .completed:
                return "分析完成"
            case .error(let message):
                return "错误: \(message)"
            }
        }
        
        var progress: Double {
            switch self {
            case .idle:
                return 0.0
            case .preprocessing:
                return 0.1
            case .textRecognition:
                return 0.3
            case .menuExtraction:
                return 0.6
            case .imageSearch:
                return 0.8
            case .completed:
                return 1.0
            case .error:
                return 0.0
            }
        }
    }
    
    // MARK: - Complete Analysis
    func analyzeMenu(_ image: UIImage) async throws -> (MenuAnalysisResult, [String: [ImageSearchResult]]) {
        guard !isAnalyzing else {
            throw AnalysisError.alreadyInProgress
        }
        
        isAnalyzing = true
        analysisProgress = 0.0
        
        defer {
            isAnalyzing = false
        }
        
        do {
            // Stage 1: 预处理
            await updateStage(.preprocessing)
            let processedImage = preprocessImage(image)
            
            // Stage 2-4: Gemini 分析
            await updateStage(.textRecognition)
            let analysisResult = try await geminiService.analyzeMenuImage(processedImage)
            lastAnalysisResult = analysisResult
            
            await updateStage(.menuExtraction)
            // 菜品提取已在Gemini分析中完成
            
            // Stage 5: 图片搜索
            await updateStage(.imageSearch)
            // 批量获取菜品图片（处理所有识别的菜品）
            var searchResults: [String: [ImageSearchResult]] = [:]
            let limitedItems = analysisResult.items
            
            for menuItem in limitedItems {
                do {
                    let dishImages = try await googleSearchService.getDishImages(for: menuItem, count: 2)
                    // 转换DishImage为ImageSearchResult
                    let imageSearchResults = dishImages.map { dishImage in
                        ImageSearchResult(
                            id: dishImage.id,
                            title: dishImage.title,
                            imageURL: dishImage.imageURL,
                            thumbnailURL: dishImage.thumbnailURL,
                            sourceURL: dishImage.sourceURL,
                            width: dishImage.width,
                            height: dishImage.height
                        )
                    }
                    searchResults[menuItem.originalName] = imageSearchResults
                } catch {
                    print("⚠️ \(menuItem.originalName) 图片获取失败: \(error)")
                    searchResults[menuItem.originalName] = []
                }
            }
            lastSearchResults = searchResults
            
            // 完成
            await updateStage(.completed)
            
            return (analysisResult, searchResults)
            
        } catch {
            await updateStage(.error(error.localizedDescription))
            throw error
        }
    }
    
    /// 完整分析（包含菜品图片）- Task005增强版本
    func analyzeMenuWithDishImages(_ image: UIImage) async throws -> (MenuAnalysisResult, [String: [DishImage]]) {
        print("🎯 [MenuAnalysisService] analyzeMenuWithDishImages 开始执行")
        print("🔄 MenuAnalysisService.analyzeMenuWithDishImages 开始...")
        
        guard !isAnalyzing else {
            print("❌ 分析已在进行中，抛出错误")
            throw AnalysisError.alreadyInProgress
        }
        
        print("✅ 设置分析状态...")
        isAnalyzing = true
        analysisProgress = 0.0
        
        defer {
            print("🔚 分析结束，重置状态")
            isAnalyzing = false
        }
        
        do {
            // Stage 1: 预处理
            print("📝 Stage 1: 图片预处理...")
            await updateStage(.preprocessing)
            let processedImage = preprocessImage(image)
            print("✅ 图片预处理完成")
            
            // Stage 2-4: Gemini 分析
            print("🤖 Stage 2-4: Gemini 分析...")
            await updateStage(.textRecognition)
            print("📞 调用 geminiService.analyzeMenuImage...")
            let analysisResult = try await geminiService.analyzeMenuImage(processedImage)
            print("✅ Gemini 分析完成，识别到 \(analysisResult.items.count) 个菜品")
            lastAnalysisResult = analysisResult
            
            await updateStage(.menuExtraction)
            print("✅ 菜品提取完成")
            print("✅ [MenuAnalysisService] Gemini 分析完成，准备进入图片搜索阶段")
            print("🧩 [MenuAnalysisService] 当前 analysisResult.items.count = \(analysisResult.items.count)")
            
            // Stage 5: 菜品图片获取（通过GoogleSearchService状态管理）
            print("🖼️ [MenuAnalysisService] Stage 5: 准备开始图片搜索...")
            print("📝 [MenuAnalysisService] 分析结果菜品列表:")
            for (index, item) in analysisResult.items.enumerated() {
                print("   \(index + 1). \(item.originalName)")
            }
            
            await updateStage(.imageSearch)
            print("📞 [MenuAnalysisService] 开始批量获取菜品图片...")
            print("📝 [MenuAnalysisService] 待搜索菜品数量: \(analysisResult.items.count)")
            
            // 批量获取菜品图片并同步状态到GoogleSearchService
            var dishImages: [String: [DishImage]] = [:]
            let limitedItems = analysisResult.items  // 处理所有识别到的菜品
            print("🔢 [MenuAnalysisService] 处理所有菜品数量: \(limitedItems.count)")
            
            for (index, menuItem) in limitedItems.enumerated() {
                let menuItemName = menuItem.originalName
                print("🔄 [MenuAnalysisService] 处理第 \(index + 1)/\(limitedItems.count) 个菜品: \(menuItemName)")
                
                do {
                    print("🔍 [MenuAnalysisService] 开始获取: \(menuItemName)")
                    
                    // 1. 立即更新状态为加载中
                    print("📤 [MenuAnalysisService] 更新状态为加载中: \(menuItemName)")
                    googleSearchService.updateState(for: menuItemName, to: .loading)
                    
                    // 验证状态是否更新成功  
                    let currentState = googleSearchService.getLoadingState(for: menuItem)
                    print("📋 [MenuAnalysisService] 状态更新验证: \(menuItemName) -> \(currentState)")
                    
                    // 2. 获取图片数据
                    print("🌐 [MenuAnalysisService] 调用 getDishImages...")
                    let images = try await googleSearchService.getDishImages(for: menuItem, count: 2)
                    print("📸 [MenuAnalysisService] 获取图片成功: \(images.count) 张")
                    
                    // 3. 检查是否需要生成图片（搜索成功但无结果）
                    var finalImages = images
                    if images.isEmpty {
                        print("🎨 [MenuAnalysisService] 搜索无结果，尝试生成图片: \(menuItemName)")
                        do {
                            let generatedImage = try await geminiService.generateDishImage(for: menuItem)
                            finalImages = [generatedImage]
                            print("✅ [MenuAnalysisService] 图片生成成功: \(menuItemName)")
                        } catch {
                            print("❌ [MenuAnalysisService] 图片生成失败: \(menuItemName) - \(error)")
                            // 生成失败时保持空数组，不影响主流程
                        }
                    }
                    
                    dishImages[menuItemName] = finalImages
                    
                    // 4. 更新状态为加载完成
                    print("📤 [MenuAnalysisService] 更新状态为已加载: \(menuItemName)")
                    googleSearchService.updateState(for: menuItemName, to: .loaded(finalImages))
                    
                    print("  ✅ \(menuItemName): \(finalImages.count) 张图片，状态已同步")
                    
                } catch {
                    print("  ❌ \(menuItemName) 图片获取失败: \(error)")
                    print("📤 [MenuAnalysisService] 更新状态为失败: \(menuItemName)")
                    dishImages[menuItemName] = []
                    
                    // 更新状态为失败
                    googleSearchService.updateState(for: menuItemName, to: .failed(error))
                }
                
                // 添加延迟避免API限制
                print("⏱️ [MenuAnalysisService] 等待 0.3 秒...")
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
            }
            
            lastDishImages = dishImages
            print("✅ 菜品图片获取完成，总计 \(dishImages.values.flatMap { $0 }.count) 张图片")
            print("🔄 所有状态已同步到 GoogleSearchService")
            
            // 完成
            await updateStage(.completed)
            print("🎉 完整分析流程完成！")
            
            return (analysisResult, dishImages)
            
        } catch {
            print("❌ 分析过程出错: \(error)")
            await updateStage(.error(error.localizedDescription))
            throw error
        }
    }
    
    // MARK: - Individual Operations
    
    /// 仅进行菜单分析（不包含图片搜索）
    func analyzeMenuOnly(_ image: UIImage) async throws -> MenuAnalysisResult {
        print("🔄 MenuAnalysisService.analyzeMenuOnly 开始...")
        
        guard !isAnalyzing else {
            throw AnalysisError.alreadyInProgress
        }
        
        isAnalyzing = true
        analysisProgress = 0.0
        
        defer {
            isAnalyzing = false
        }
        
        do {
            // Stage 1: 预处理
            await updateStage(.preprocessing)
            let processedImage = preprocessImage(image)
            
            // Stage 2-4: Gemini 分析
            await updateStage(.textRecognition)
            let analysisResult = try await geminiService.analyzeMenuImage(processedImage)
            lastAnalysisResult = analysisResult
            
            await updateStage(.completed)
            
            return analysisResult
            
        } catch {
            await updateStage(.error(error.localizedDescription))
            throw error
        }
    }
    
    /// 为菜品项目搜索图片
    func searchImagesForMenuItem(_ menuItem: MenuItemAnalysis) async throws -> [ImageSearchResult] {
        let dishImages = try await googleSearchService.getDishImages(for: menuItem, count: 3)
        
        // 转换DishImage为ImageSearchResult
        return dishImages.map { dishImage in
            ImageSearchResult(
                id: dishImage.id,
                title: dishImage.title,
                imageURL: dishImage.imageURL,
                thumbnailURL: dishImage.thumbnailURL,
                sourceURL: dishImage.sourceURL,
                width: dishImage.width,
                height: dishImage.height
            )
        }
    }
    
    /// 批量获取菜品图片
    func getDishImagesForMenuItems(_ menuItems: [MenuItemAnalysis], imagesPerItem: Int = 2) async throws -> [String: [DishImage]] {
        print("🔄 MenuAnalysisService.getDishImagesForMenuItems 开始...")
        print("📝 菜品数量: \(menuItems.count), 每个菜品图片数: \(imagesPerItem)")
        
        var dishImages: [String: [DishImage]] = [:]
        
        // 处理所有菜品，不再限制数量
        let limitedItems = menuItems
        
        for menuItem in limitedItems {
            let menuItemName = menuItem.originalName
            
            do {
                print("🔍 [MenuAnalysisService] 搜索菜品图片: \(menuItemName)")
                
                // 1. 立即更新状态为加载中
                googleSearchService.updateState(for: menuItemName, to: .loading)
                
                // 2. 获取图片数据
                let images = try await googleSearchService.getDishImages(for: menuItem, count: imagesPerItem)
                
                // 3. 检查是否需要生成图片（搜索成功但无结果）
                var finalImages = images
                if images.isEmpty {
                    print("🎨 [MenuAnalysisService] 搜索无结果，尝试生成图片: \(menuItemName)")
                    do {
                        let generatedImage = try await geminiService.generateDishImage(for: menuItem)
                        finalImages = [generatedImage]
                        print("✅ [MenuAnalysisService] 图片生成成功: \(menuItemName)")
                    } catch {
                        print("❌ [MenuAnalysisService] 图片生成失败: \(menuItemName) - \(error)")
                        // 生成失败时保持空数组，不影响主流程
                    }
                }
                
                dishImages[menuItemName] = finalImages
                
                // 4. 更新状态为加载完成
                googleSearchService.updateState(for: menuItemName, to: .loaded(finalImages))
                
                print("  ✅ \(menuItemName): 获取到 \(finalImages.count) 张图片，状态已同步")
                
                // 添加延迟避免API限制
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
                
            } catch {
                print("  ❌ \(menuItemName) 图片获取失败: \(error)")
                dishImages[menuItemName] = []
                
                // 更新状态为失败
                googleSearchService.updateState(for: menuItemName, to: .failed(error))
            }
        }
        
        lastDishImages = dishImages
        print("✅ 批量图片获取完成，总计 \(dishImages.values.flatMap { $0 }.count) 张图片")
        print("🔄 所有状态已同步到 GoogleSearchService")
        
        return dishImages
    }
    
    // MARK: - Helper Methods
    
    private func updateStage(_ stage: AnalysisStage) async {
        await MainActor.run {
            currentStage = stage
            analysisProgress = stage.progress
        }
    }
    
    private func preprocessImage(_ image: UIImage) -> UIImage {
        // 简单的图片预处理：调整大小以优化API调用
        let maxSize: CGFloat = 1024
        let size = image.size
        
        if size.width <= maxSize && size.height <= maxSize {
            return image
        }
        
        let scale = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    // MARK: - Error Handling & Recovery
    
    @Published var lastError: AppError?
    @Published var retryAttempts: Int = 0
    
    private let maxRetryAttempts = 3
    private let baseRetryDelay: TimeInterval = 1.0
    
    /// 通用错误处理和重试机制
    private func handleErrorWithRetry<T: Sendable>(
        operation: @Sendable () async throws -> T,
        errorContext: String,
        canRetry: Bool = true
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<(canRetry ? maxRetryAttempts : 1) {
            do {
                let result = try await operation()
                // 成功时重置重试计数
                if attempt > 0 {
                    await MainActor.run {
                        retryAttempts = 0
                    }
                }
                return result
            } catch {
                lastError = error
                await MainActor.run {
                    retryAttempts = attempt + 1
                }
                
                // 记录错误
                logError(error, context: errorContext, attempt: attempt + 1)
                
                // 如果不是最后一次尝试，等待后重试
                if attempt < maxRetryAttempts - 1 && canRetry {
                    let delay = baseRetryDelay * pow(2.0, Double(attempt)) // 指数退避
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // 所有重试都失败，抛出包装后的错误
        let wrappedError = AppError.fromError(lastError!, context: errorContext)
        await MainActor.run {
            self.lastError = wrappedError
        }
        throw wrappedError
    }
    
    /// 错误日志记录
    private func logError(_ error: Error, context: String, attempt: Int) {
        let errorInfo = [
            "Context": context,
            "Attempt": "\(attempt)/\(maxRetryAttempts)",
            "Error": error.localizedDescription,
            "Type": String(describing: type(of: error)),
            "Timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        print("❌ [MenuAnalysisService] 错误详情: \(errorInfo)")
        
        // 在实际应用中，这里可以发送到崩溃报告服务
        // crashReporter.recordError(error, userInfo: errorInfo)
    }
    
    /// 清除错误状态
    func clearError() {
        lastError = nil
        retryAttempts = 0
    }
    
    // MARK: - Error Types
    enum AnalysisError: LocalizedError {
        case alreadyInProgress
        case imageProcessingFailed
        case analysisTimeout
        case networkError(Error)
        case invalidResponse
        case serviceUnavailable
        case rateLimitExceeded
        
        var errorDescription: String? {
            switch self {
            case .alreadyInProgress:
                return "分析已在进行中，请等待当前分析完成"
            case .imageProcessingFailed:
                return "图片处理失败，请检查图片是否损坏或格式不支持"
            case .analysisTimeout:
                return "分析超时，请检查网络连接并重试"
            case .networkError(let error):
                return "网络连接失败: \(error.localizedDescription)"
            case .invalidResponse:
                return "服务器返回无效数据，请稍后重试"
            case .serviceUnavailable:
                return "服务暂时不可用，请稍后重试"
            case .rateLimitExceeded:
                return "请求过于频繁，请稍后重试"
            }
        }
        
        var recoveryOptions: [String] {
            switch self {
            case .alreadyInProgress:
                return ["等待完成"]
            case .imageProcessingFailed:
                return ["选择其他图片", "检查图片格式"]
            case .analysisTimeout, .networkError:
                return ["检查网络连接", "重试", "使用离线模式"]
            case .invalidResponse, .serviceUnavailable:
                return ["重试", "联系客服"]
            case .rateLimitExceeded:
                return ["稍后重试", "减少请求频率"]
            }
        }
        
        var canRetry: Bool {
            switch self {
            case .alreadyInProgress:
                return false
            case .imageProcessingFailed:
                return false
            default:
                return true
            }
        }
    }
}

// MARK: - Supporting Types
struct ServiceHealthStatus {
    var isConfigured: Bool = false
    var geminiConnected: Bool = false
    var searchConnected: Bool = false
    var geminiError: String?
    var searchError: String?
    
    var isHealthy: Bool {
        return isConfigured && geminiConnected && searchConnected
    }
    
    var statusMessage: String {
        if !isConfigured {
            return "❌ API未配置"
        } else if !geminiConnected && !searchConnected {
            return "❌ 所有服务离线"
        } else if !geminiConnected {
            return "⚠️ Gemini服务离线"
        } else if !searchConnected {
            return "⚠️ 搜索服务离线"
        } else {
            return "✅ 所有服务正常"
        }
    }
} 
