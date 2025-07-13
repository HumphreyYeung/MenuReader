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
    let responseModalities: [String]?
    
    init(temperature: Double? = nil,
         topK: Int? = nil,
         topP: Double? = nil,
         maxOutputTokens: Int? = nil,
         stopSequences: [String]? = nil,
         responseModalities: [String]? = nil) {
        self.temperature = temperature
        self.topK = topK
        self.topP = topP
        self.maxOutputTokens = maxOutputTokens
        self.stopSequences = stopSequences
        self.responseModalities = responseModalities
    }
    
    static let `default` = GeminiGenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
        stopSequences: nil,
        responseModalities: nil
    )
    
    static let imageGeneration = GeminiGenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
        stopSequences: nil,
        responseModalities: ["TEXT", "IMAGE"]
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

// MARK: - Image Generation Models
struct GeminiImageGenerationRequest: Codable {
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

struct GeminiImageResponse: Codable {
    let candidates: [GeminiImageCandidate]?
    
    var imageData: String? {
        return candidates?.first?.content?.parts.first(where: { $0.inlineData != nil })?.inlineData?.data
    }
    
    var textDescription: String? {
        return candidates?.first?.content?.parts.first(where: { $0.text != nil })?.text
    }
}

struct GeminiImageCandidate: Codable {
    let content: GeminiContent?
    let finishReason: String?
}

// MARK: - Unified OCR & Menu Analysis Service
/// 统一的文字识别和菜单分析服务 - 整合了OCRService功能
class GeminiService: ObservableObject, @unchecked Sendable {
    static let shared = GeminiService()
    
    private let apiClient = NetworkService.shared
    
    private init() {}
    
    // MARK: - Menu Analysis (Primary Function)
    
    /// 分析菜单图片（主要方法）
    /// 分析菜单图片（主要方法）- 带智能语言检测
    func analyzeMenuImage(_ image: UIImage) async throws -> MenuAnalysisResult {
        print("🤖 [GeminiService] 开始智能菜单分析...")
        
        // 1. 获取用户目标语言设置
        let languageService = await LanguageService.shared
        let userTargetLanguage = await languageService.getUserTargetLanguage()
        print("🎯 [GeminiService] 用户目标语言: \(userTargetLanguage)")
        
        // 2. 获取用户过敏原设置
        let userAllergens = AllergenManager.shared.getAllergens()
        if !userAllergens.isEmpty {
            print("⚠️ [GeminiService] 用户过敏原: \(userAllergens.joined(separator: ", "))")
        } else {
            print("✅ [GeminiService] 用户无过敏原设置")
        }
        
        // 3. 首先进行OCR识别，检测菜单语言
        let ocrResult = try await performInitialOCR(image)
        let detectedLanguage = await languageService.detectLanguage(from: ocrResult.rawText)
        print("🔍 [GeminiService] 检测到菜单语言: \(detectedLanguage)")
        
        // 4. 判断是否需要翻译
        let needsTranslation = await languageService.shouldTranslate(
            detectedLanguage: detectedLanguage, 
            targetLanguage: userTargetLanguage
        )
        
        if needsTranslation {
            print("🌍 [GeminiService] 需要翻译：\(detectedLanguage) -> \(userTargetLanguage)")
            // 进行带翻译的分析
            return try await analyzeMenuImageWithTranslation(
                image, 
                sourceLanguage: detectedLanguage,
                targetLanguage: userTargetLanguage,
                userAllergens: userAllergens
            )
        } else {
            print("✅ [GeminiService] 语言一致，无需翻译")
            // 直接分析，不进行翻译
            return try await analyzeMenuImageWithoutTranslation(image, language: detectedLanguage, userAllergens: userAllergens)
        }
    }
    
    /// 执行初始OCR识别（用于语言检测）
    private func performInitialOCR(_ image: UIImage) async throws -> (rawText: String, confidence: Double) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.invalidImage
        }
        
        let base64String = imageData.base64EncodedString()
        let imagePart = GeminiPart(inlineData: GeminiInlineData(mimeType: "image/jpeg", data: base64String))
        
        let prompt = """
        请识别这张图片中的所有文字内容，直接输出原始文字，不要进行翻译或格式化：
        """
        
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
        
        return (rawText: responseText, confidence: 0.9)
    }
    
    /// 带翻译的菜单分析
    private func analyzeMenuImageWithTranslation(_ image: UIImage, sourceLanguage: String, targetLanguage: String, userAllergens: [String] = []) async throws -> MenuAnalysisResult {
        let startTime = Date()
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.invalidImage
        }
        
        let base64String = imageData.base64EncodedString()
        let imagePart = GeminiPart(inlineData: GeminiInlineData(mimeType: "image/jpeg", data: base64String))
        
        let prompt = createMenuAnalysisPromptWithTranslation(sourceLanguage: sourceLanguage, targetLanguage: targetLanguage, userAllergens: userAllergens)
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
        let result = try parseMenuAnalysisResponse(responseText, processingTime: processingTime)
        return result
    }
    
    /// 不带翻译的菜单分析
    private func analyzeMenuImageWithoutTranslation(_ image: UIImage, language: String, userAllergens: [String] = []) async throws -> MenuAnalysisResult {
        let startTime = Date()
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.invalidImage
        }
        
        let base64String = imageData.base64EncodedString()
        let imagePart = GeminiPart(inlineData: GeminiInlineData(mimeType: "image/jpeg", data: base64String))
        
        let prompt = createMenuAnalysisPromptWithoutTranslation(language: language, userAllergens: userAllergens)
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
        let result = try parseMenuAnalysisResponse(responseText, processingTime: processingTime)
        return result
    }
    
    /// 创建带翻译的分析提示词
    private func createMenuAnalysisPromptWithTranslation(sourceLanguage: String, targetLanguage: String, userAllergens: [String] = []) -> String {
        let sourceLangName = getLanguageName(sourceLanguage)
        let targetLangName = getLanguageName(targetLanguage)
        
        // 基础JSON结构
        var jsonStructure = """
        {
          "items": [
            {
              "originalName": "原始菜品名称（\(sourceLangName)）",
              "translatedName": "翻译为\(targetLangName)的名称",
              "description": "简要描述（\(targetLangName)）",
              "price": "价格（如果可见）",
              "confidence": 0.95,
              "category": "菜品分类"
        """
        
        // 条件性添加过敏原分析字段
        if !userAllergens.isEmpty {
            jsonStructure += """
            ,
              "allergens": ["检测到的过敏原（仅限：\(userAllergens.joined(separator: "、"))）"],
              "hasUserAllergens": false,
              "isVegetarian": false,
              "isVegan": false,
              "spicyLevel": "辣度等级(0-5)"
            """
        }
        
        jsonStructure += """
            }
          ],
          "confidence": 0.9,
          "processingTime": 1.5,
          "detectedLanguage": "\(sourceLanguage)",
          "translationApplied": true
        }
        """
        
        var prompt = """
        请分析这张菜单图片，提取菜品信息并按以下JSON格式返回。菜单原文是\(sourceLangName)，请翻译为\(targetLangName)：
        \(jsonStructure)
        
        请确保：
        1. originalName保持原文不变
        2. translatedName提供准确的\(targetLangName)翻译
        3. description用\(targetLangName)描述菜品特色
        """
        
        // 条件性添加过敏原分析指令
        if !userAllergens.isEmpty {
            prompt += """
            4. 重要：仅分析是否包含用户关心的过敏原：\(userAllergens.joined(separator: "、"))
            5. allergens字段只包含检测到的用户过敏原，如无则为空数组
            6. hasUserAllergens设为true如果包含任何用户过敏原
            7. 如果能判断，标记isVegetarian和isVegan
            8. spicyLevel标记辣度等级(0-5)
            """
        }
        
        prompt += "\n\(userAllergens.isEmpty ? "4" : "9"). 只返回有效的JSON格式，不要添加额外文字"
        
        return prompt
    }
    
    /// 创建不带翻译的分析提示词
    private func createMenuAnalysisPromptWithoutTranslation(language: String, userAllergens: [String] = []) -> String {
        let langName = getLanguageName(language)
        
        // 基础JSON结构
        var jsonStructure = """
        {
          "items": [
            {
              "originalName": "菜品名称（\(langName)）",
              "translatedName": "菜品名称（\(langName)）",
              "description": "简要描述（\(langName)）",
              "price": "价格（如果可见）",
              "confidence": 0.95,
              "category": "菜品分类"
        """
        
        // 条件性添加过敏原分析字段
        if !userAllergens.isEmpty {
            jsonStructure += """
            ,
              "allergens": ["检测到的过敏原（仅限：\(userAllergens.joined(separator: "、"))）"],
              "hasUserAllergens": false,
              "isVegetarian": false,
              "isVegan": false,
              "spicyLevel": "辣度等级(0-5)"
            """
        }
        
        jsonStructure += """
            }
          ],
          "confidence": 0.9,
          "processingTime": 1.5,
          "detectedLanguage": "\(language)",
          "translationApplied": false
        }
        """
        
        var prompt = """
        请分析这张菜单图片，提取菜品信息并按以下JSON格式返回。菜单和输出都使用\(langName)：
        \(jsonStructure)
        
        请确保：
        1. 所有文字都使用\(langName)
        2. originalName和translatedName相同（因为无需翻译）
        """
        
        // 条件性添加过敏原分析指令
        if !userAllergens.isEmpty {
            prompt += """
            3. 重要：仅分析是否包含用户关心的过敏原：\(userAllergens.joined(separator: "、"))
            4. allergens字段只包含检测到的用户过敏原，如无则为空数组
            5. hasUserAllergens设为true如果包含任何用户过敏原
            6. 如果能判断，标记isVegetarian和isVegan
            7. spicyLevel标记辣度等级(0-5)
            """
        }
        
        prompt += "\n\(userAllergens.isEmpty ? "3" : "8"). 只返回有效的JSON格式，不要添加额外文字"
        
        return prompt
    }
    
    /// 获取语言的显示名称
    private func getLanguageName(_ code: String) -> String {
        switch code.lowercased() {
        case "zh": return "中文"
        case "en": return "英文"
        case "ja": return "日文"
        case "ko": return "韩文"
        case "fr": return "法文"
        case "de": return "德文"
        case "it": return "意大利文"
        case "es": return "西班牙文"
        case "pt": return "葡萄牙文"
        default: return "未知语言"
        }
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
    
    // MARK: - Image Generation
    
    /// 生成菜品图片（新功能）
    func generateDishImage(for menuItem: MenuItemAnalysis) async throws -> DishImage {
        print("🎨 [GeminiService] 开始生成菜品图片: \(menuItem.originalName)")
        
        // 检查API密钥
        guard EnvironmentLoader.shared.geminiAPIKey != nil else {
            throw GeminiError.apiKeyMissing
        }
        
        let prompt = createDishImagePrompt(for: menuItem)
        let textPart = GeminiPart(text: prompt)
        let content = GeminiContent(parts: [textPart])
        
        print("🔤 [GeminiService] 图像生成提示词已创建")
        
        // 使用图像生成专用配置（包含responseModalities）
        let request = GeminiImageGenerationRequest(
            contents: [content],
            generationConfig: GeminiGenerationConfig.imageGeneration,
            safetySettings: GeminiSafetySetting.defaultSettings
        )
        
        print("📡 [GeminiService] 发送图像生成请求到 Gemini 2.0 Flash...")
        
        do {
            let endpoint = apiClient.createGeminiImageGenerationEndpoint(request: request)
            let response: GeminiImageResponse = try await apiClient.request(
                endpoint,
                responseType: GeminiImageResponse.self
            )
            
            print("✅ [GeminiService] 收到图像生成响应")
            
            guard let imageData = response.imageData, !imageData.isEmpty else {
                print("❌ [GeminiService] 响应中无图像数据")
                throw GeminiError.imageGenerationFailed("API响应中未包含图像数据")
            }
            
            print("📸 [GeminiService] 图像数据获取成功，长度: \(imageData.count) 字符")
            
            // 将Base64图像数据转换为本地可用的DishImage
            let dishImage = createDishImageFromGeneratedData(
                imageData: imageData,
                menuItem: menuItem,
                description: response.textDescription
            )
            
            print("✅ [GeminiService] 菜品图片生成完成: \(menuItem.originalName)")
            return dishImage
            
        } catch {
            print("❌ [GeminiService] 图像生成失败: \(error)")
            throw GeminiError.imageGenerationFailed(error.localizedDescription)
        }
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
                        imageSearchQuery: generateImageSearchQuery(for: item),
                        allergens: item.allergens,
                        hasUserAllergens: item.hasUserAllergens,
                        isVegetarian: item.isVegetarian,
                        isVegan: item.isVegan,
                        spicyLevel: item.spicyLevel
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
        // 优化：优先使用原始名称而不是翻译名称
        let searchTerm = item.originalName
        return "\(searchTerm) dish food"
    }
    
    private func calculateOverallConfidence(_ items: [MenuItemAnalysis]) -> Double {
        guard !items.isEmpty else { return 0.0 }
        let totalConfidence = items.reduce(0.0) { $0 + $1.confidence }
        return totalConfidence / Double(items.count)
    }
    
    // MARK: - Image Generation Helper Methods
    
    /// 创建菜品图像生成提示词
    private func createDishImagePrompt(for menuItem: MenuItemAnalysis) -> String {
        let dishName = menuItem.translatedName ?? menuItem.originalName
        let description = menuItem.description ?? ""
        let category = menuItem.category ?? ""
        
        return """
        App Bundle ID: io.github.HumphreyYeung.MenuReader
        
        Generate a high-quality, photorealistic image of the dish: \(dishName)
        
        Dish Details:
        - Name: \(dishName)
        - Original Name: \(menuItem.originalName)
        \(description.isEmpty ? "" : "- Description: \(description)")
        \(category.isEmpty ? "" : "- Category: \(category)")
        
        Requirements:
        - Show a close-up view of the dish that highlights its key ingredients and presentation
        - Use clean, neutral background (white or light colored)
        - Professional food photography style with good lighting
        - The dish should look appetizing and fresh
        - Focus on authentic appearance typical of this cuisine
        - Avoid any text, labels, or watermarks in the image
        - High resolution and sharp details
        - The dish should be the main focal point, taking up most of the frame
        
        Style: Professional food photography, clean presentation, appetizing appearance
        """
    }
    
    /// 从生成的图像数据创建DishImage对象
    private func createDishImageFromGeneratedData(
        imageData: String, 
        menuItem: MenuItemAnalysis, 
        description: String?
    ) -> DishImage {
        // 创建本地数据URL用于图像显示
        let base64Prefix = "data:image/png;base64,"
        let dataURL = base64Prefix + imageData
        
        let title = description ?? "生成的\(menuItem.translatedName ?? menuItem.originalName)图片"
        
        return DishImage(
            id: UUID(),
            title: title,
            imageURL: dataURL, // 使用data URL作为图像源
            thumbnailURL: dataURL, // 缩略图使用同样的数据
            sourceURL: "Generated by Gemini 2.0 Flash",
            width: 1024, // 默认生成尺寸
            height: 1024,
            menuItemName: menuItem.originalName,
            isLoaded: true // 生成的图像视为已加载
        )
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
    case imageGenerationFailed(String)
    case apiKeyMissing
    
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
        case .imageGenerationFailed(let message):
            return "图片生成失败: \(message)"
        case .apiKeyMissing:
            return "缺少Gemini API密钥"
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


