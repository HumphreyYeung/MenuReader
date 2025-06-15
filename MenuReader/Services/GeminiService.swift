//
//  GeminiService.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import Foundation
import UIKit

// MARK: - Gemini Request Models
struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig?
    let safetySettings: [GeminiSafetySetting]?
    
    init(contents: [GeminiContent], 
         generationConfig: GeminiGenerationConfig? = nil,
         safetySettings: [GeminiSafetySetting]? = nil) {
        self.contents = contents
        self.generationConfig = generationConfig
        self.safetySettings = safetySettings
    }
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
    let role: String?
    
    init(parts: [GeminiPart], role: String? = "user") {
        self.parts = parts
        self.role = role
    }
}

struct GeminiPart: Codable {
    let text: String?
    let inlineData: GeminiInlineData?
    
    init(text: String) {
        self.text = text
        self.inlineData = nil
    }
    
    init(inlineData: GeminiInlineData) {
        self.text = nil
        self.inlineData = inlineData
    }
}

struct GeminiInlineData: Codable {
    let mimeType: String
    let data: String
    
    init(mimeType: String, data: String) {
        self.mimeType = mimeType
        self.data = data
    }
}

struct GeminiGenerationConfig: Codable {
    let temperature: Double?
    let topK: Int?
    let topP: Double?
    let maxOutputTokens: Int?
    let stopSequences: [String]?
    
    static let `default` = GeminiGenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
        stopSequences: nil
    )
}

struct GeminiSafetySetting: Codable {
    let category: String
    let threshold: String
    
    static let defaultSettings = [
        GeminiSafetySetting(category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
        GeminiSafetySetting(category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
        GeminiSafetySetting(category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
        GeminiSafetySetting(category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_MEDIUM_AND_ABOVE")
    ]
}

// MARK: - Gemini Response Models
struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
    let promptFeedback: GeminiPromptFeedback?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent?
    let finishReason: String?
    let index: Int?
    let safetyRatings: [GeminiSafetyRating]?
}

struct GeminiPromptFeedback: Codable {
    let safetyRatings: [GeminiSafetyRating]?
}

struct GeminiSafetyRating: Codable {
    let category: String
    let probability: String
}

// MARK: - Unified OCR & Menu Analysis Service
/// 统一的文字识别和菜单分析服务 - 整合了OCRService功能
class GeminiService: ObservableObject, @unchecked Sendable {
    static let shared = GeminiService()
    
    private let apiClient = NetworkService.shared
    
    private init() {}
    
    // MARK: - Menu Analysis (Primary Function)
    
    /// 分析菜单图片（主要方法）
    func analyzeMenuImage(_ image: UIImage) async throws -> MenuAnalysisResult {
        return try await analyzeMenuImageWithLanguage(image, targetLanguage: .chinese)
    }
    
    /// 带语言参数的菜单分析
    func analyzeMenuImageWithLanguage(_ image: UIImage, targetLanguage: SupportedOCRLanguage) async throws -> MenuAnalysisResult {
        let startTime = Date()
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.invalidImage
        }
        
        let base64String = imageData.base64EncodedString()
        let imagePart = GeminiPart(inlineData: GeminiInlineData(mimeType: "image/jpeg", data: base64String))
        
        // 根据目标语言创建提示词
        let prompt = createMenuAnalysisPrompt(for: targetLanguage)
        let textPart = GeminiPart(text: prompt)
        let content = GeminiContent(parts: [textPart, imagePart])
        
        let request = GeminiRequest(
            contents: [content],
            generationConfig: GeminiGenerationConfig.default,
            safetySettings: GeminiSafetySetting.defaultSettings
        )
        
        let endpoint = apiClient.createGeminiEndpoint(request: request)
        let response: GeminiResponse = try await apiClient.request(
            endpoint,
            responseType: GeminiResponse.self
        )
        
        guard let responseText = response.text, response.isSuccess else {
            throw GeminiError.invalidResponse
        }
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        // 解析JSON响应
        let result = try parseMenuAnalysisResponse(responseText, processingTime: processingTime)
        return result
    }
    
    // MARK: - OCR Processing (Integrated from OCRService)
    
    /// OCR图片处理（整合自OCRService）
    func processImageOCR(_ image: UIImage, targetLanguage: SupportedOCRLanguage = .chinese, preferences: OCRProcessingPreferences? = nil) async throws -> OCRProcessingResult {
        let requestId = UUID().uuidString
        let startTime = Date()
        
        do {
            // 使用菜单分析功能进行OCR
            let menuResult = try await analyzeMenuImageWithLanguage(image, targetLanguage: targetLanguage)
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            return OCRProcessingResult(
                requestId: requestId,
                success: true,
                confidence: menuResult.confidence,
                processingTime: processingTime,
                detectedLanguage: targetLanguage.rawValue,
                menuItems: menuResult.items,
                rawText: menuResult.items.map { "\($0.originalName) - \($0.price ?? "时价")" }.joined(separator: "\n"),
                error: nil
            )
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            return OCRProcessingResult(
                requestId: requestId,
                success: false,
                confidence: 0.0,
                processingTime: processingTime,
                detectedLanguage: targetLanguage.rawValue,
                menuItems: [],
                rawText: "",
                error: error.localizedDescription
            )
        }
    }
    
    // MARK: - Text Analysis
    
    /// 纯文本分析
    func analyzeText(_ text: String) async throws -> String {
        let textPart = GeminiPart(text: text)
        let content = GeminiContent(parts: [textPart])
        
        let request = GeminiRequest(
            contents: [content],
            generationConfig: GeminiGenerationConfig.default,
            safetySettings: GeminiSafetySetting.defaultSettings
        )
        
        let endpoint = apiClient.createGeminiEndpoint(request: request)
        let response: GeminiResponse = try await apiClient.request(
            endpoint,
            responseType: GeminiResponse.self
        )
        
        guard let responseText = response.text, response.isSuccess else {
            throw GeminiError.invalidResponse
        }
        
        return responseText
    }
    
    // MARK: - Service Health
    
    /// 测试连接
    func testConnection() async throws -> Bool {
        let testText = "Hello, this is a test message."
        let _ = try await analyzeText(testText)
        return true
    }
    
    // MARK: - Private Methods
    
    private func createMenuAnalysisPrompt(for language: SupportedOCRLanguage) -> String {
        let targetLang = language == .chinese ? "中文" : "英文"
        
        return """
        请分析这张菜单图片，提取菜品信息并按以下JSON格式返回：
        {
          "items": [
            {
              "originalName": "原始菜品名称",
              "translatedName": "翻译为\(targetLang)的名称",
              "description": "简要描述",
              "price": "价格（如果可见）",
              "confidence": 0.95,
              "category": "菜品类别（如果可识别）"
            }
          ]
        }
        
        要求：
        1. 识别所有可见的菜品名称
        2. 如果有价格信息，请提取
        3. 将菜品名称翻译为\(targetLang)
        4. 提供简要的菜品描述
        5. 对每个识别项给出信心度评分
        
        请确保返回有效的JSON格式。
        """
    }
    
    private func parseMenuAnalysisResponse(_ responseText: String, processingTime: TimeInterval) throws -> MenuAnalysisResult {
        // 尝试提取JSON部分
        let jsonString = extractJSONFromResponse(responseText)
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw GeminiError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(MenuAnalysisResponse.self, from: jsonData)
            
            // 为每个菜品添加图片搜索查询
            let enhancedItems = response.items.map { item in
                if item.imageSearchQuery == nil {
                    return MenuItemAnalysis(
                        originalName: item.originalName,
                        translatedName: item.translatedName,
                        description: item.description,
                        price: item.price,
                        confidence: item.confidence,
                        category: item.category,
                        imageSearchQuery: generateImageSearchQuery(for: item)
                    )
                }
                return item
            }
            
            return MenuAnalysisResult(
                items: enhancedItems,
                processingTime: processingTime,
                confidence: calculateOverallConfidence(enhancedItems),
                language: "auto"
            )
            
        } catch {
            print("❌ JSON解析失败: \(error)")
            print("📄 响应文本: \(responseText)")
            throw GeminiError.parseError(error.localizedDescription)
        }
    }
    
    private func extractJSONFromResponse(_ response: String) -> String {
        // 查找JSON代码块
        if let jsonStart = response.range(of: "```json"),
           let jsonEnd = response.range(of: "```", range: jsonStart.upperBound..<response.endIndex) {
            let jsonContent = String(response[jsonStart.upperBound..<jsonEnd.lowerBound])
            return jsonContent.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 查找花括号包围的JSON
        if let start = response.firstIndex(of: "{"),
           let end = response.lastIndex(of: "}") {
            return String(response[start...end])
        }
        
        // 如果都没找到，返回原始响应
        return response
    }
    
    private func generateImageSearchQuery(for item: MenuItemAnalysis) -> String {
        // 优先使用翻译名称，其次使用原始名称
        let searchTerm = item.translatedName ?? item.originalName
        return "\(searchTerm) dish food"
    }
    
    private func calculateOverallConfidence(_ items: [MenuItemAnalysis]) -> Double {
        guard !items.isEmpty else { return 0.0 }
        let totalConfidence = items.reduce(0.0) { $0 + $1.confidence }
        return totalConfidence / Double(items.count)
    }
}

// MARK: - Supporting Types

struct MenuAnalysisResponse: Codable {
    let items: [MenuItemAnalysis]
}

// MARK: - Error Types

enum GeminiError: LocalizedError {
    case invalidImage
    case invalidResponse
    case parseError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无效的图片格式"
        case .invalidResponse:
            return "无效的API响应"
        case .parseError(let message):
            return "解析错误: \(message)"
        case .networkError(let message):
            return "网络错误: \(message)"
        }
    }
}

// MARK: - Convenience Extensions

extension GeminiRequest {
    static func textOnly(_ text: String) -> GeminiRequest {
        let part = GeminiPart(text: text)
        let content = GeminiContent(parts: [part])
        return GeminiRequest(contents: [content])
    }
    
    static func textWithImage(_ text: String, image: UIImage) -> GeminiRequest? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        let base64String = imageData.base64EncodedString()
        let imagePart = GeminiPart(inlineData: GeminiInlineData(mimeType: "image/jpeg", data: base64String))
        let textPart = GeminiPart(text: text)
        let content = GeminiContent(parts: [textPart, imagePart])
        
        return GeminiRequest(contents: [content])
    }
}

extension GeminiResponse {
    var text: String? {
        return candidates?.first?.content?.parts.first?.text
    }
    
    var isSuccess: Bool {
        return candidates?.first?.finishReason != "SAFETY"
    }
} 


