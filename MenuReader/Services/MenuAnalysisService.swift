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
            let searchResults = try await googleSearchService.searchImagesForMenuItems(analysisResult.items)
            lastSearchResults = searchResults
            
            // 完成
            await updateStage(.completed)
            
            return (analysisResult, searchResults)
            
        } catch {
            await updateStage(.error(error.localizedDescription))
            throw error
        }
    }
    
    // MARK: - Individual Steps
    func analyzeTextOnly(_ image: UIImage) async throws -> MenuAnalysisResult {
        guard !isAnalyzing else {
            throw AnalysisError.alreadyInProgress
        }
        
        isAnalyzing = true
        
        defer {
            isAnalyzing = false
        }
        
        do {
            await updateStage(.preprocessing)
            let processedImage = preprocessImage(image)
            
            await updateStage(.textRecognition)
            let result = try await geminiService.analyzeMenuImage(processedImage)
            lastAnalysisResult = result
            
            await updateStage(.completed)
            return result
            
        } catch {
            await updateStage(.error(error.localizedDescription))
            throw error
        }
    }
    
    func searchImagesForMenuItem(_ menuItem: MenuItemAnalysis) async throws -> [ImageSearchResult] {
        let query = googleSearchService.enhanceSearchQuery(for: menuItem)
        return try await googleSearchService.searchImages(for: query, count: 5)
    }
    
    // MARK: - Helper Methods
    private func preprocessImage(_ image: UIImage) -> UIImage {
        // 简单的预处理：确保图片方向正确
        guard image.imageOrientation != .up else {
            return image
        }
        
        let renderer = UIGraphicsImageRenderer(size: image.size, format: UIGraphicsImageRendererFormat.default())
        let orientedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        
        return orientedImage
    }
    
    private func updateStage(_ stage: AnalysisStage) async {
        currentStage = stage
        analysisProgress = stage.progress
    }
    
    // MARK: - Service Health Check
    func checkServiceHealth() async -> ServiceHealthStatus {
        var status = ServiceHealthStatus()
        
        // 检查API配置
        status.isConfigured = APIConfig.isConfigured
        
        if status.isConfigured {
            // 测试Gemini连接
            do {
                status.geminiConnected = try await geminiService.testConnection()
            } catch {
                status.geminiError = error.localizedDescription
            }
            
            // 测试Google Search连接
            do {
                status.searchConnected = try await googleSearchService.testConnection()
            } catch {
                status.searchError = error.localizedDescription
            }
        }
        
        return status
    }
    
    // MARK: - Reset
    func resetAnalysis() {
        currentStage = .idle
        analysisProgress = 0.0
        lastAnalysisResult = nil
        lastSearchResults = [:]
    }
}

// MARK: - Supporting Types
enum AnalysisError: LocalizedError {
    case alreadyInProgress
    case invalidImage
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .alreadyInProgress:
            return "分析已在进行中"
        case .invalidImage:
            return "无效的图片"
        case .serviceUnavailable:
            return "服务暂不可用"
        }
    }
}

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
