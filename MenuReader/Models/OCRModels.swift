//
//  OCRModels.swift
//  MenuReader
//
//  Created by MenuReader on 2025-06-13.
//

import Foundation
import UIKit

// MARK: - OCR Request Models

/// OCR请求结构
struct OCRRequest: Codable, Sendable {
    let image: Data
    let targetLanguage: String
    let preferences: OCRProcessingPreferences?
    
    init(image: Data, targetLanguage: String, preferences: OCRProcessingPreferences? = nil) {
        self.image = image
        self.targetLanguage = targetLanguage
        self.preferences = preferences
    }
}

/// OCR响应结构
struct OCRResponse: Codable, Sendable {
    let requestId: String
    let success: Bool
    let confidence: Double
    let processingTime: Double
    let language: DetectedLanguage
    let menuItems: [MenuItemAnalysis]
    let extractedText: String
    let error: OCRError?
    
    init(requestId: String, success: Bool, confidence: Double, processingTime: Double, detectedLanguage: String, menuItems: [MenuItemAnalysis], rawText: String, error: String?) {
        self.requestId = requestId
        self.success = success
        self.confidence = confidence
        self.processingTime = processingTime
        self.language = DetectedLanguage(code: detectedLanguage, name: detectedLanguage, confidence: confidence)
        self.menuItems = menuItems
        self.extractedText = rawText
        self.error = error != nil ? OCRError(code: "API_ERROR", message: error!) : nil
    }
}

// MARK: - OCR Processing Models

/// OCR处理偏好设置
struct OCRProcessingPreferences: Codable, Sendable {
    let imageQuality: ImageQuality
    let processingMode: ProcessingMode
    let enableTextEnhancement: Bool
    let targetLanguages: [String]
    
    init(imageQuality: ImageQuality = .high, 
         processingMode: ProcessingMode = .accurate,
         enableTextEnhancement: Bool = true,
         targetLanguages: [String] = ["en", "zh"]) {
        self.imageQuality = imageQuality
        self.processingMode = processingMode
        self.enableTextEnhancement = enableTextEnhancement
        self.targetLanguages = targetLanguages
    }
}

/// 图片质量设置
enum ImageQuality: String, Codable, CaseIterable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case ultra = "ultra"
    
    var compressionQuality: CGFloat {
        switch self {
        case .low: return 0.3
        case .medium: return 0.5
        case .high: return 0.7
        case .ultra: return 0.9
        }
    }
    
    var maxDimension: CGFloat {
        switch self {
        case .low: return 800
        case .medium: return 1200
        case .high: return 1600
        case .ultra: return 2400
        }
    }
    
    var displayName: String {
        switch self {
        case .low: return "低质量"
        case .medium: return "中等质量"
        case .high: return "高质量"
        case .ultra: return "超高质量"
        }
    }
}

/// 处理模式
enum ProcessingMode: String, Codable, CaseIterable, Sendable {
    case fast = "fast"
    case balanced = "balanced"
    case accurate = "accurate"
    
    var displayName: String {
        switch self {
        case .fast: return "快速模式"
        case .balanced: return "平衡模式"
        case .accurate: return "精确模式"
        }
    }
}

// MARK: - OCR Status and Results

/// OCR处理状态
enum OCRProcessingStatus: String, Codable, CaseIterable, Sendable {
    case preparing = "preparing"
    case uploading = "uploading"
    case processing = "processing"
    case analyzing = "analyzing"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .preparing: return "准备中"
        case .uploading: return "上传图片"
        case .processing: return "识别文字"
        case .analyzing: return "分析菜单"
        case .completed: return "处理完成"
        case .failed: return "处理失败"
        }
    }
    
    var progressValue: Double {
        switch self {
        case .preparing: return 0.1
        case .uploading: return 0.3
        case .processing: return 0.6
        case .analyzing: return 0.8
        case .completed: return 1.0
        case .failed: return 0.0
        }
    }
}

/// OCR处理结果
struct OCRProcessingResult: Sendable {
    let requestId: String
    let success: Bool
    let confidence: Double
    let processingTime: TimeInterval
    let detectedLanguage: String
    let menuItems: [MenuItemAnalysis]
    let rawText: String
    let error: String?
    
    /// 转换为现有的ProcessingResult类型
    func toProcessingResult(originalImage: UIImage) -> ProcessingResult {
        return ProcessingResult(
            originalImage: originalImage,
            extractedText: rawText,
            menuItems: menuItems.map { $0.toMenuItem() },
            confidence: confidence,
            language: detectedLanguage,
            processingTime: processingTime
        )
    }
}

// MARK: - Language Support

/// 支持的OCR语言
enum SupportedOCRLanguage: String, Codable, CaseIterable, Sendable {
    case english = "en"
    case chinese = "zh"
    case japanese = "ja"
    case korean = "ko"
    case french = "fr"
    case spanish = "es"
    case german = "de"
    case italian = "it"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .french: return "Français"
        case .spanish: return "Español"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .chinese: return "🇨🇳"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .french: return "🇫🇷"
        case .spanish: return "🇪🇸"
        case .german: return "🇩🇪"
        case .italian: return "🇮🇹"
        }
    }
}

/// 检测到的语言信息
struct DetectedLanguage: Codable, Sendable {
    let code: String
    let name: String
    let confidence: Double
}

// MARK: - MenuItemAnalysis Extension for OCR

extension MenuItemAnalysis {
    /// 转换为现有的MenuItem类型
    func toMenuItem() -> MenuItem {
        return MenuItem(
            originalName: originalName,
            translatedName: translatedName,
            imageURL: nil,
            category: category,
            description: description,
            price: price,
            confidence: confidence,
            hasAllergens: false,
            allergenTypes: [],
            imageResults: []
        )
    }
}

// MARK: - Error Models

/// OCR错误信息
struct OCRError: Codable, Sendable {
    let code: String
    let message: String
}

// MARK: - Mock Data (Removed for clean implementation)

// MARK: - OCR API Response Models

/// OCR API响应结构（OCR.space API格式）
struct OCRAPIResponse: Codable, Sendable {
    let parsedResults: [OCRParsedResult]?
    let ocrExitCode: Int?
    let isErroredOnProcessing: Bool?
    let errorMessage: [String]?
    let errorDetails: String?
    let processingTimeInMilliseconds: Int?
    
    enum CodingKeys: String, CodingKey {
        case parsedResults = "ParsedResults"
        case ocrExitCode = "OCRExitCode"
        case isErroredOnProcessing = "IsErroredOnProcessing"
        case errorMessage = "ErrorMessage"
        case errorDetails = "ErrorDetails"
        case processingTimeInMilliseconds = "ProcessingTimeInMilliseconds"
    }
}

/// OCR解析结果
struct OCRParsedResult: Codable, Sendable {
    let textOverlay: OCRTextOverlay?
    let textOrientation: String?
    let fileParseExitCode: Int?
    let parsedText: String?
    let errorMessage: String?
    let errorDetails: String?
    
    enum CodingKeys: String, CodingKey {
        case textOverlay = "TextOverlay"
        case textOrientation = "TextOrientation"
        case fileParseExitCode = "FileParseExitCode"
        case parsedText = "ParsedText"
        case errorMessage = "ErrorMessage"
        case errorDetails = "ErrorDetails"
    }
}

/// OCR文本覆盖信息
struct OCRTextOverlay: Codable, Sendable {
    let lines: [OCRLine]?
    let hasOverlay: Bool?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case lines = "Lines"
        case hasOverlay = "HasOverlay"
        case message = "Message"
    }
}

/// OCR文本行
struct OCRLine: Codable, Sendable {
    let words: [OCRWord]?
    let maxHeight: Double?
    let minTop: Double?
    
    enum CodingKeys: String, CodingKey {
        case words = "Words"
        case maxHeight = "MaxHeight"
        case minTop = "MinTop"
    }
}

/// OCR单词
struct OCRWord: Codable, Sendable {
    let wordText: String?
    let left: Double?
    let top: Double?
    let height: Double?
    let width: Double?
    
    enum CodingKeys: String, CodingKey {
        case wordText = "WordText"
        case left = "Left"
        case top = "Top"
        case height = "Height"
        case width = "Width"
    }
}

// MARK: - OCR Service Error Types

/// OCR服务错误类型
enum OCRServiceError: Error, LocalizedError {
    case configurationError(String)
    case networkError(String)
    case processingError(String)
    case invalidResponse(String)
    case timeout
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .configurationError(let message):
            return "配置错误: \(message)"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .processingError(let message):
            return "处理错误: \(message)"
        case .invalidResponse(let message):
            return "响应无效: \(message)"
        case .timeout:
            return "请求超时"
        case .unknown(let error):
            return "未知错误: \(error.localizedDescription)"
        }
    }
} 