//
//  OCRProcessingManager.swift
//  MenuReader
//
//  Created by MenuReader on 2025-06-13.
//

import Foundation
import UIKit
import Combine

/// OCR处理管理器 - 协调整个OCR流程的状态管理
@MainActor
final class OCRProcessingManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = OCRProcessingManager()
    
    // MARK: - Published Properties
    
    /// 当前处理状态
    @Published private(set) var currentStatus: OCRProcessingStatus = .preparing
    
    /// 处理进度 (0.0 - 1.0)
    @Published private(set) var progress: Double = 0.0
    
    /// 当前处理的图片
    @Published private(set) var currentImage: UIImage?
    
    /// 处理后的图片
    @Published private(set) var processedImage: UIImage?
    
    /// OCR结果
    @Published private(set) var ocrResult: OCRProcessingResult?
    
    /// 错误信息
    @Published private(set) var errorMessage: String?
    
    /// 是否正在处理
    var isProcessing: Bool {
        switch currentStatus {
        case .preparing, .uploading, .processing, .analyzing:
            return true
        case .completed, .failed:
            return false
        }
    }
    
    // MARK: - Configuration
    
    @Published var processingPreferences: OCRProcessingPreferences = OCRProcessingPreferences()
    
    // MARK: - Services
    
    private let ocrService: OCRService
    
    // MARK: - Initialization
    
    private init() {
        self.ocrService = OCRService()
    }
    
    // MARK: - Language Settings
    
    /// 获取智能默认语言设置
    private func getDefaultTargetLanguage() -> SupportedOCRLanguage {
        let deviceLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        
        switch deviceLanguage {
        case "zh", "zh-Hans", "zh-Hant":
            return .english  // 中文设备默认翻译为英文
        case "ja":
            return .english  // 日文设备默认翻译为英文
        case "ko":
            return .english  // 韩文设备默认翻译为英文
        default:
            return .chinese  // 其他语言设备默认翻译为中文
        }
    }
    
    /// 根据用户偏好获取目标语言
    private func getTargetLanguage() -> SupportedOCRLanguage {
        // 从用户偏好读取，如果没有则使用智能默认设置
        if let savedLanguage = UserDefaults.standard.string(forKey: "target_language"),
           let language = SupportedOCRLanguage(rawValue: savedLanguage) {
            return language
        }
        
        return getDefaultTargetLanguage()
    }
    
    // MARK: - OCR Processing
    
    /// 开始OCR处理
    func startOCRProcessing(image: UIImage, preferences: OCRProcessingPreferences? = nil) async {
        // 重置状态
        await resetProcessingState()
        
        // 设置初始状态
        currentImage = image
        if let preferences = preferences {
            processingPreferences = preferences
        }
        
        do {
            // 阶段1: 图片预处理
            await updateStatus(.preparing, progress: 0.1)
            
            // 简化的图片预处理
            processedImage = image
            await updateStatus(.uploading, progress: 0.3)
            
            // 阶段2: OCR处理
            await updateStatus(.processing, progress: 0.6)
            
            // 获取目标语言
            let targetLanguage = getTargetLanguage()
            print("🌍 使用目标语言: \(targetLanguage.displayName)")
            
            let result = try await ocrService.processImage(
                image,
                targetLanguage: targetLanguage,
                preferences: processingPreferences
            )
            
            // 阶段3: 结果分析
            await updateStatus(.analyzing, progress: 0.8)
            
            // 模拟分析延迟
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            // 完成处理
            ocrResult = result
            await updateStatus(.completed, progress: 1.0)
            
        } catch {
            await handleError("OCR处理失败: \(error.localizedDescription)")
        }
    }
    
    /// 开始模拟处理（用于测试UI）
    func startMockProcessing(image: UIImage) async {
        await resetProcessingState()
        currentImage = image
        
        // 模拟处理步骤
        let steps: [(OCRProcessingStatus, Double, TimeInterval)] = [
            (.preparing, 0.2, 0.5),
            (.uploading, 0.4, 1.0),
            (.processing, 0.7, 1.5),
            (.analyzing, 0.9, 0.5),
            (.completed, 1.0, 0.3)
        ]
        
        for (status, progress, delay) in steps {
            await updateStatus(status, progress: progress)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // 创建模拟结果
        let mockResult = OCRProcessingResult(
            requestId: UUID().uuidString,
            success: true,
            confidence: 0.92,
            processingTime: 3.5,
            detectedLanguage: "zh",
            menuItems: createMockMenuItems(),
            rawText: "宫保鸡丁 - ¥28\n麻婆豆腐 - ¥18\n红烧肉 - ¥32",
            error: nil
        )
        
        ocrResult = mockResult
    }
    
    // MARK: - Public Methods
    
    /// 设置用户语言偏好
    func setTargetLanguage(_ language: SupportedOCRLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: "target_language")
        print("🌍 已保存目标语言偏好: \(language.displayName)")
    }
    
    /// 重置处理状态
    func resetProcessingState() async {
        currentStatus = .preparing
        progress = 0.0
        currentImage = nil
        processedImage = nil
        ocrResult = nil
        errorMessage = nil
    }
    
    /// 取消当前处理
    func cancelProcessing() async {
        await resetProcessingState()
    }
    
    // MARK: - Private Methods
    
    /// 更新状态和进度
    private func updateStatus(_ status: OCRProcessingStatus, progress: Double) async {
        currentStatus = status
        self.progress = progress
    }
    
    /// 处理错误
    private func handleError(_ message: String) async {
        errorMessage = message
        currentStatus = .failed
        progress = 0.0
        print("❌ OCR处理错误: \(message)")
    }
    
    // MARK: - Mock Data
    
    private func createMockMenuItems() -> [MenuItemAnalysis] {
        return [
            MenuItemAnalysis(
                originalName: "宫保鸡丁",
                translatedName: "Kung Pao Chicken",
                description: "经典川菜，鸡肉配花生米",
                price: "¥28",
                confidence: 0.95,
                category: "主菜",
                imageSearchQuery: "kung pao chicken"
            ),
            MenuItemAnalysis(
                originalName: "麻婆豆腐",
                translatedName: "Mapo Tofu",
                description: "四川传统豆腐菜",
                price: "¥18",
                confidence: 0.88,
                category: "主菜",
                imageSearchQuery: "mapo tofu"
            ),
            MenuItemAnalysis(
                originalName: "红烧肉",
                translatedName: "Braised Pork Belly",
                description: "传统红烧肉，肥瘦相间",
                price: "¥32",
                confidence: 0.88,
                category: "主菜",
                imageSearchQuery: "braised pork belly"
            )
        ]
    }
} 