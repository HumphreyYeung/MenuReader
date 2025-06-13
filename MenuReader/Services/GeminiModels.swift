//
//  GeminiModels.swift
//  MenuReader
//
//  Created by Assistant on 25/1/2025.
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
