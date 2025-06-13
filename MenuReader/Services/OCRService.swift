//
//  OCRService.swift
//  MenuReader
//
//  Created by MenuReader on 2025-06-13.
//

import Foundation
import UIKit

// MARK: - OCR Service Protocol

/// OCR服务协议
protocol OCRServiceProtocol: Sendable {
    func processImage(_ image: UIImage, targetLanguage: SupportedOCRLanguage, preferences: OCRProcessingPreferences?) async throws -> OCRProcessingResult
}

// MARK: - OCR Service Implementation

/// OCR服务实现
@MainActor
final class OCRService: OCRServiceProtocol {
    
    // MARK: - Properties
    
    private let apiClient: APIClient
    private let geminiService = GeminiService.shared
    
    // MARK: - Initialization
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - Public Methods
    
    /// 处理图片进行OCR识别（协议要求的方法）
    func processImage(_ image: UIImage, targetLanguage: SupportedOCRLanguage = .english, preferences: OCRProcessingPreferences? = nil) async throws -> OCRProcessingResult {
        let requestId = UUID().uuidString
        let startTime = Date()
        
        // 创建OCR请求
        let imageData = image.jpegData(compressionQuality: preferences?.imageQuality.compressionQuality ?? 0.7) ?? Data()
        
        let request = OCRRequest(
            image: imageData,
            targetLanguage: targetLanguage.rawValue,
            preferences: preferences
        )
        
        do {
            // 使用真实的Gemini API进行OCR识别
            let response = try await processRealOCR(request: request, targetLanguage: targetLanguage)
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            if response.success {
                return OCRProcessingResult(
                    requestId: requestId,
                    success: true,
                    confidence: response.confidence,
                    processingTime: processingTime,
                    detectedLanguage: response.language.code,
                    menuItems: response.menuItems,
                    rawText: response.extractedText,
                    error: nil
                )
            } else {
                return OCRProcessingResult(
                    requestId: requestId,
                    success: false,
                    confidence: 0.0,
                    processingTime: processingTime,
                    detectedLanguage: targetLanguage.rawValue,
                    menuItems: [],
                    rawText: "",
                    error: response.error?.message ?? "OCR处理失败"
                )
            }
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
    
    // MARK: - Private Methods
    
    /// 使用Gemini API进行真实OCR处理
    private func processRealOCR(request: OCRRequest, targetLanguage: SupportedOCRLanguage) async throws -> OCRResponse {
        // 构建图片数据
        guard let image = UIImage(data: request.image) else {
            throw OCRServiceError.processingError("无法解析图片数据")
        }
        
        do {
            // 使用GeminiService进行菜单分析
            let result = try await geminiService.analyzeMenuImageWithLanguage(image, targetLanguage: targetLanguage)
            
            // 转换为OCRResponse格式
            return OCRResponse(
                requestId: UUID().uuidString,
                success: true,
                confidence: result.confidence,
                processingTime: result.processingTime,
                detectedLanguage: targetLanguage.rawValue,
                menuItems: result.items,
                rawText: result.items.map { "\($0.originalName) - \($0.price ?? "时价")" }.joined(separator: "\n"),
                error: nil
            )
            
        } catch {
            throw OCRServiceError.processingError("Gemini API处理失败: \(error.localizedDescription)")
        }
    }
    
    /// 模拟OCR处理（保留作为备用）
    private func processMockOCR(request: OCRRequest) async throws -> OCRResponse {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
        
        // 模拟90%成功率
        let isSuccess = Double.random(in: 0...1) > 0.1
        
        guard isSuccess else {
            throw OCRServiceError.processingError("模拟OCR处理失败")
        }
        
        // 返回模拟数据
        let mockMenuItems = [
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
        
        return OCRResponse(
            requestId: UUID().uuidString,
            success: true,
            confidence: Double.random(in: 0.85...0.98),
            processingTime: Double.random(in: 1.5...3.0),
            detectedLanguage: request.targetLanguage,
            menuItems: mockMenuItems,
            rawText: mockMenuItems.map { "\($0.originalName) - \($0.price ?? "时价")" }.joined(separator: "\n"),
            error: nil
        )
    }
    
    /// 转换API响应为内部格式
    private func convertAPIResponse(_ apiResponse: OCRAPIResponse, requestId: String) throws -> OCRResponse {
        guard let parsedResults = apiResponse.parsedResults,
              let firstResult = parsedResults.first,
              let extractedText = firstResult.parsedText else {
            throw OCRServiceError.invalidResponse("无法解析OCR响应")
        }
        
        // 这里应该有更复杂的文本解析逻辑来提取菜单项
        // 目前使用简化版本
        let menuItems = parseMenuItems(from: extractedText)
        
        return OCRResponse(
            requestId: requestId,
            success: true,
            confidence: 0.85,
            processingTime: Double(apiResponse.processingTimeInMilliseconds ?? 1000) / 1000.0,
            detectedLanguage: "zh",
            menuItems: menuItems,
            rawText: extractedText,
            error: nil
        )
    }
    
    /// 从文本中解析菜单项（简化版本）
    private func parseMenuItems(from text: String) -> [MenuItemAnalysis] {
        // 简化的解析逻辑
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        return lines.prefix(10).map { line in
            let parts = line.components(separatedBy: "¥")
            let name = parts.first?.trimmingCharacters(in: .whitespaces) ?? line
            let price = parts.count > 1 ? "¥\(parts[1])" : nil
            
            return MenuItemAnalysis(
                originalName: name,
                translatedName: nil,
                description: nil,
                price: price,
                confidence: 0.8,
                category: "未分类",
                imageSearchQuery: name
            )
        }
    }
}

 