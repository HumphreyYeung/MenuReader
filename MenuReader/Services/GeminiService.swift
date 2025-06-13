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

// MARK: - Convenience Methods
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
    
    static func menuAnalysis(image: UIImage) -> GeminiRequest? {
        let prompt = """
        Please analyze this menu image and extract the following information in JSON format:
        {
          "items": [
            {
              "originalName": "original dish name",
              "translatedName": "English translation if not in English",
              "description": "brief description",
              "price": "price if visible",
              "confidence": 0.95,
              "category": "category if identifiable"
            }
          ]
        }
        """
        
        return textWithImage(prompt, image: image)
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

// MARK: - Gemini Service
class GeminiService: ObservableObject, @unchecked Sendable {
    static let shared = GeminiService()
    
    private let apiClient = APIClient.shared
    // 移除硬编码的baseURL，使用APIConfig中的动态配置
    
    private init() {}
    
    // MARK: - Menu Analysis
    func analyzeMenuImage(_ image: UIImage) async throws -> MenuAnalysisResult {
        return try await analyzeMenuImageWithLanguage(image, targetLanguage: .english)
    }
    
    func analyzeMenuImageWithLanguage(_ image: UIImage, targetLanguage: SupportedOCRLanguage) async throws -> MenuAnalysisResult {
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
        
        let endpoint = GeminiEndpoint.generateContent(request: request)
        let response: GeminiResponse = try await apiClient.request(
            endpoint,
            responseType: GeminiResponse.self
        )
        
        return try parseMenuAnalysisResponse(response, targetLanguage: targetLanguage)
    }
    
    private func createMenuAnalysisPrompt(for targetLanguage: SupportedOCRLanguage) -> String {
        let targetLangName = targetLanguage.displayName
        
        return """
        请分析这张菜单图片，提取菜品信息并按以下JSON格式返回：
        {
          "items": [
            {
              "originalName": "原始菜品名称",
              "translatedName": "翻译为\(targetLangName)的名称",
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
        3. 将菜品名称翻译为\(targetLangName)
        4. 提供简要的菜品描述
        5. 对每个识别项给出信心度评分
        
        请确保返回有效的JSON格式。
        """
    }
    
    // MARK: - Text Analysis
    func analyzeText(_ text: String) async throws -> MenuAnalysisResult {
        let request = GeminiRequest(
            contents: [GeminiContent(parts: [GeminiPart(text: text)])],
            generationConfig: GeminiGenerationConfig.default,
            safetySettings: GeminiSafetySetting.defaultSettings
        )
        
        let endpoint = GeminiEndpoint.generateContent(request: request)
        let response: GeminiResponse = try await apiClient.request(
            endpoint,
            responseType: GeminiResponse.self
        )
        
        return try parseMenuAnalysisResponse(response)
    }
    
    // MARK: - Helper Methods
    private func extractTextFromResponse(_ response: GeminiResponse) -> String {
        guard let candidate = response.candidates?.first,
              let content = candidate.content,
              let part = content.parts.first,
              let text = part.text else {
            return ""
        }
        
        return text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    private func parseMenuAnalysisResponse(_ response: GeminiResponse, targetLanguage: SupportedOCRLanguage = .english) throws -> MenuAnalysisResult {
        let extractedText = extractTextFromResponse(response)
        
        // 增强调试信息
        print("🔍 Gemini API 完整调试信息:")
        print("=== API配置检查 ===")
        print("API Key长度: \(APIConfig.geminiAPIKey.count)")
        print("使用模型: \(APIConfig.geminiModel)")
        print("Base URL: \(APIConfig.geminiBaseURL)")
        
        print("=== 响应分析 ===")
        print("Response candidates count: \(response.candidates?.count ?? 0)")
        
        // 检查是否有错误响应
        if let promptFeedback = response.promptFeedback {
            print("Prompt feedback: \(promptFeedback)")
        }
        
        print("Extracted text: '\(extractedText)'")
        print("Text length: \(extractedText.count)")
        
        // 如果响应为空，详细检查原因
        if extractedText.isEmpty {
            print("❌ API响应为空，检查原因:")
            
            if response.candidates?.isEmpty == true {
                print("  - 没有候选结果")
                throw GeminiError.networkError("API没有返回任何候选结果，请检查API密钥和配置")
            }
            
            if let candidate = response.candidates?.first {
                print("  - Finish reason: \(candidate.finishReason ?? "nil")")
                
                if let safetyRatings = candidate.safetyRatings {
                    print("  - Safety ratings:")
                    for rating in safetyRatings {
                        print("    \(rating.category): \(rating.probability)")
                    }
                    
                    // 检查是否被安全过滤器阻止
                    let blockedReasons = safetyRatings.filter { 
                        $0.probability == "HIGH" || $0.probability == "MEDIUM" 
                    }
                    if !blockedReasons.isEmpty {
                        print("  ⚠️ 内容被安全过滤器阻止")
                        throw GeminiError.networkError("内容被安全过滤器阻止，请尝试其他图片")
                    }
                }
                
                if candidate.finishReason == "SAFETY" {
                    throw GeminiError.networkError("内容被安全策略阻止")
                }
            }
            
            throw GeminiError.invalidResponse
        }
        
        // 检查是否有安全过滤或其他问题
        if let candidate = response.candidates?.first {
            print("Finish reason: \(candidate.finishReason ?? "nil")")
            if let safetyRatings = candidate.safetyRatings {
                print("Safety ratings: \(safetyRatings)")
            }
        }
        
        // 尝试不同的JSON提取方法
        var jsonText = extractedText
        
        // 方法1: 寻找完整的JSON块
        if let jsonRange = findJSONRange(in: extractedText) {
            jsonText = String(extractedText[jsonRange])
            print("📋 提取的JSON: \(jsonText)")
        } else {
            // 方法2: 清理文本中的markdown标记
            jsonText = cleanTextForJSON(extractedText)
            print("🧹 清理后的文本: \(jsonText)")
        }
        
        // 尝试解析JSON
        if let jsonData = jsonText.data(using: .utf8) {
            do {
                let decoder = JSONDecoder()
                let menuData = try decoder.decode(MenuAnalysisResponse.self, from: jsonData)
                print("✅ JSON解析成功，识别到 \(menuData.items.count) 个菜品")
                
                for item in menuData.items {
                    print("🍽️ \(item.originalName) -> \(item.translatedName ?? "无翻译")")
                }
                
                return MenuAnalysisResult(
                    items: menuData.items,
                    processingTime: 0,
                    confidence: menuData.items.isEmpty ? 0.0 : 0.95,
                    language: "zh"
                )
            } catch {
                print("❌ JSON解析失败: \(error)")
                print("📄 失败的JSON文本: \(jsonText)")
            }
        }
        
        // 如果JSON解析失败，先尝试简单文本解析
        let simpleTextItems = parseSimpleTextResponse(extractedText, targetLanguage: targetLanguage)
        if !simpleTextItems.isEmpty {
            print("📝 使用简单文本解析，识别到 \(simpleTextItems.count) 个菜品")
            return MenuAnalysisResult(
                items: simpleTextItems,
                processingTime: 0,
                confidence: 0.8,
                language: "zh"
            )
        }
        
        // 如果简单解析也失败，尝试增强文本模式解析
        let textItems = parseTextResponse(extractedText, targetLanguage: targetLanguage)
        if !textItems.isEmpty {
            print("📝 使用增强文本解析模式，识别到 \(textItems.count) 个菜品")
            return MenuAnalysisResult(
                items: textItems,
                processingTime: 0,
                confidence: 0.8,
                language: "zh"
            )
        }
        
        print("⚠️ 所有解析方法都失败，返回空结果")
        return MenuAnalysisResult(
            items: [],
            processingTime: 0,
            confidence: 0.0,
            language: "unknown"
        )
    }
    
    // MARK: - JSON处理辅助方法
    private func findJSONRange(in text: String) -> Range<String.Index>? {
        guard let start = text.firstIndex(of: "{") else { return nil }
        
        var braceCount = 0
        var currentIndex = start
        
        while currentIndex < text.endIndex {
            let char = text[currentIndex]
            if char == "{" {
                braceCount += 1
            } else if char == "}" {
                braceCount -= 1
                if braceCount == 0 {
                    return start..<text.index(after: currentIndex)
                }
            }
            currentIndex = text.index(after: currentIndex)
        }
        
        return nil
    }
    
    private func cleanTextForJSON(_ text: String) -> String {
        // 移除markdown代码块标记
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果没有找到JSON结构，返回空的items结构
        if !cleaned.contains("items") {
            return """
            {
              "items": []
            }
            """
        }
        
        return cleaned
    }
    
    // 添加简单文本解析方法
    private func parseSimpleTextResponse(_ text: String, targetLanguage: SupportedOCRLanguage) -> [MenuItemAnalysis] {
        var items: [MenuItemAnalysis] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 跳过空行和无关内容
            if trimmed.isEmpty || trimmed.count < 2 {
                continue
            }
            
            // 简单的菜品识别逻辑
            if let item = extractMenuItemFromLine(trimmed) {
                items.append(item)
            }
        }
        
        return items
    }
    
    private func extractMenuItemFromLine(_ line: String) -> MenuItemAnalysis? {
        // 使用正则表达式匹配常见的菜品格式
        let patterns = [
            #"(.+?)[：:]\s*([¥￥$]\d+)"#,  // 菜品名：价格
            #"(.+?)\s+([¥￥$]\d+)"#,      // 菜品名 价格
            #"^[^：:¥￥$]+$"#              // 纯菜品名
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(location: 0, length: line.utf16.count)
                if let match = regex.firstMatch(in: line, options: [], range: range) {
                    
                    if match.numberOfRanges > 2 {
                        // 有价格的情况
                        let nameRange = match.range(at: 1)
                        let priceRange = match.range(at: 2)
                        
                        if let nameNSRange = Range(nameRange, in: line),
                           let priceNSRange = Range(priceRange, in: line) {
                            let name = String(line[nameNSRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                            let price = String(line[priceNSRange])
                            
                            return MenuItemAnalysis(
                                originalName: name,
                                translatedName: name,
                                description: nil,
                                price: price,
                                confidence: 0.8,
                                category: nil,
                                imageSearchQuery: name
                            )
                        }
                    } else if match.range.location != NSNotFound {
                        // 只有菜品名的情况
                        let name = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        return MenuItemAnalysis(
                            originalName: name,
                            translatedName: name,
                            description: nil,
                            price: nil,
                            confidence: 0.7,
                            category: nil,
                            imageSearchQuery: name
                        )
                    }
                }
            }
        }
        
        return nil
    }
    
    private func parseTextResponse(_ text: String, targetLanguage: SupportedOCRLanguage) -> [MenuItemAnalysis] {
        // 简单的文本解析作为fallback
        let lines = text.components(separatedBy: .newlines)
        var items: [MenuItemAnalysis] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.hasPrefix("{") && !trimmed.hasPrefix("}") && !trimmed.hasPrefix("请分析") {
                // 尝试解析菜品信息
                if let item = parseMenuItemFromLine(trimmed, targetLanguage: targetLanguage) {
                    items.append(item)
                }
            }
        }
        
        return items
    }
    
    private func parseMenuItemFromLine(_ line: String, targetLanguage: SupportedOCRLanguage) -> MenuItemAnalysis? {
        // 简单的行解析逻辑 - 寻找可能的菜品名称
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 跳过明显不是菜品的行
        if trimmed.count < 2 || trimmed.contains("分析") || trimmed.contains("格式") || trimmed.contains("JSON") {
            return nil
        }
        
        // 尝试分割价格
        var dishName = trimmed
        var price: String? = nil
        
        // 寻找价格模式 (¥, $, 等)
        if let priceMatch = trimmed.range(of: #"[¥$￥]\d+"#, options: .regularExpression) {
            price = String(trimmed[priceMatch])
            dishName = trimmed.replacingCharacters(in: priceMatch, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return MenuItemAnalysis(
            originalName: dishName,
            translatedName: dishName, // 简化处理
            description: nil,
            price: price,
            confidence: 0.7,
            category: nil,
            imageSearchQuery: nil
        )
    }
}

// MARK: - Supporting Types
struct MenuAnalysisResponse: Codable {
    let items: [MenuItemAnalysis]
}

enum GeminiError: Error {
    case invalidImage
    case invalidResponse
    case networkError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidImage:
            return "Invalid image data"
        case .invalidResponse:
            return "Invalid response from Gemini API"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Extensions
extension GeminiService {
    // 验证API配置
    func validateConfiguration() -> (isValid: Bool, error: String?) {
        print("🔧 验证API配置...")
        
        if APIConfig.geminiAPIKey.isEmpty {
            return (false, "Gemini API密钥未设置")
        }
        
        if APIConfig.geminiAPIKey.count < 30 {
            return (false, "Gemini API密钥格式可能不正确（长度过短）")
        }
        
        print("✅ API配置验证通过")
        return (true, nil)
    }
    
    // 简单图片测试方法
    func testWithSimplePrompt(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.invalidImage
        }
        
        let base64String = imageData.base64EncodedString()
        let imagePart = GeminiPart(inlineData: GeminiInlineData(mimeType: "image/jpeg", data: base64String))
        let textPart = GeminiPart(text: "这张图片里有什么？请简单描述一下。")
        let content = GeminiContent(parts: [textPart, imagePart])
        
        let request = GeminiRequest(
            contents: [content],
            generationConfig: GeminiGenerationConfig.default,
            safetySettings: GeminiSafetySetting.defaultSettings
        )
        
        let endpoint = GeminiEndpoint.generateContent(request: request)
        let response: GeminiResponse = try await apiClient.request(
            endpoint,
            responseType: GeminiResponse.self
        )
        
        return extractTextFromResponse(response)
    }
    
    // 完整的连接测试
    func fullConnectionTest() async -> (success: Bool, message: String) {
        // 1. 配置验证
        let configResult = validateConfiguration()
        if !configResult.isValid {
            return (false, configResult.error ?? "配置无效")
        }
        
        // 2. 简单文本测试
        do {
            let testRequest = GeminiRequest(
                contents: [
                    GeminiContent(parts: [
                        GeminiPart(text: "请回复：测试成功")
                    ])
                ]
            )
            
            let endpoint = GeminiEndpoint.generateContent(request: testRequest)
            let response = try await apiClient.request(endpoint, responseType: GeminiResponse.self)
            
            let responseText = extractTextFromResponse(response)
            if responseText.contains("测试成功") {
                return (true, "✅ API连接正常")
            } else {
                return (false, "❌ API响应异常：\(responseText)")
            }
            
        } catch {
            return (false, "❌ API连接失败：\(error.localizedDescription)")
        }
    }
    
    // 测试API连接
    func testConnection() async throws -> Bool {
        let testRequest = GeminiRequest(
            contents: [
                GeminiContent(parts: [
                    GeminiPart(text: "请回复'连接成功'")
                ])
            ]
        )
        
        let endpoint = GeminiEndpoint.generateContent(request: testRequest)
        let response = try await apiClient.request(endpoint, responseType: GeminiResponse.self)
        
        return response.candidates?.first?.content?.parts.first?.text?.contains("连接成功") ?? false
    }
    
    // 简化提示词的菜单分析方法
    func analyzeMenuWithSimplePrompt(_ image: UIImage) async throws -> MenuAnalysisResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.invalidImage
        }
        
        let base64String = imageData.base64EncodedString()
        let imagePart = GeminiPart(inlineData: GeminiInlineData(mimeType: "image/jpeg", data: base64String))
        
        // 使用简化的提示词
        let simplePrompt = """
        分析这张菜单图片，识别出所有菜品名称和价格。请用简单易懂的方式列出：

        菜品名称：价格
        菜品名称：价格
        ...

        如果看不清价格，就只写菜品名称。
        请用中文回答。
        """
        
        let textPart = GeminiPart(text: simplePrompt)
        let content = GeminiContent(parts: [textPart, imagePart])
        
        let request = GeminiRequest(
            contents: [content],
            generationConfig: GeminiGenerationConfig.default,
            safetySettings: GeminiSafetySetting.defaultSettings
        )
        
        let endpoint = GeminiEndpoint.generateContent(request: request)
        let response: GeminiResponse = try await apiClient.request(
            endpoint,
            responseType: GeminiResponse.self
        )
        
        return try parseMenuAnalysisResponse(response, targetLanguage: .chinese)
    }
} 


