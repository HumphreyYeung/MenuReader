//
//  ProcessingTypes.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import Foundation
import UIKit

// MARK: - Processing Result
struct ProcessingResult {
    let originalImage: UIImage
    let extractedText: String
    let menuItems: [MenuItem]
    let confidence: Double
    let language: String
    let processingTime: TimeInterval
    
    init(originalImage: UIImage,
         extractedText: String,
         menuItems: [MenuItem],
         confidence: Double,
         language: String = "unknown",
         processingTime: TimeInterval = 0.0) {
        self.originalImage = originalImage
        self.extractedText = extractedText
        self.menuItems = menuItems
        self.confidence = confidence
        self.language = language
        self.processingTime = processingTime
    }
}

// MARK: - Menu Analysis Result
struct MenuAnalysisResult: Codable {
    let items: [MenuItemAnalysis]
    let processingTime: TimeInterval
    let confidence: Double
    let language: String
    
    init(items: [MenuItemAnalysis], processingTime: TimeInterval = 0, confidence: Double = 0.95, language: String = "zh") {
        self.items = items
        self.processingTime = processingTime
        self.confidence = confidence
        self.language = language
    }
}

// MARK: - Menu Item Analysis
struct MenuItemAnalysis: Codable, Identifiable, Hashable {
    let id = UUID()
    let originalName: String
    let translatedName: String?
    let description: String?
    let price: String?
    let confidence: Double
    let category: String?
    let imageSearchQuery: String?
    let allergens: [String]?       // 检测到的过敏原（仅用户关心的）
    let hasUserAllergens: Bool     // 是否包含用户过敏原
    let isVegetarian: Bool?        // 素食标识（可选）
    let isVegan: Bool?            // 纯素标识（可选）
    let spicyLevel: String?       // 辣度等级（可选）
    
    enum CodingKeys: String, CodingKey {
        case originalName, translatedName, description, price, confidence, category, imageSearchQuery, allergens, hasUserAllergens, isVegetarian, isVegan, spicyLevel
    }
    
    init(originalName: String, 
         translatedName: String? = nil,
         description: String? = nil,
         price: String? = nil,
         confidence: Double = 0.95,
         category: String? = nil,
         imageSearchQuery: String? = nil,
         allergens: [String]? = nil,
         hasUserAllergens: Bool = false,
         isVegetarian: Bool? = nil,
         isVegan: Bool? = nil,
         spicyLevel: String? = nil) {
        self.originalName = originalName
        self.translatedName = translatedName
        self.description = description
        self.price = price
        self.confidence = confidence
        self.category = category
        self.imageSearchQuery = imageSearchQuery
        self.allergens = allergens
        self.hasUserAllergens = hasUserAllergens
        self.isVegetarian = isVegetarian
        self.isVegan = isVegan
        self.spicyLevel = spicyLevel
    }
}

// MARK: - Search Information (不与GoogleSearchService重复的类型)
struct GoogleSearchInformation: Codable {
    let searchTime: Double?
    let formattedSearchTime: String?
    let totalResults: String?
    let formattedTotalResults: String?
}

// MARK: - Menu Process Result (for NetworkService compatibility)
// Note: MenuItem is defined in MenuItem.swift
struct MenuProcessResult: Codable, Identifiable, Hashable {
    public var id: UUID
    var scanDate: Date
    var thumbnailData: Data?
    var items: [MenuItemAnalysis]
    var dishImages: [String: [DishImage]]? // 存储菜品图片，可选以兼容旧数据
    
    // 实现Hashable协议，确保NavigationLink可用
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MenuProcessResult, rhs: MenuProcessResult) -> Bool {
        lhs.id == rhs.id
    }
    
    init(id: UUID = UUID(), scanDate: Date = Date(), thumbnailData: Data? = nil, items: [MenuItemAnalysis], dishImages: [String : [DishImage]]? = nil) {
        self.id = id
        self.scanDate = scanDate
        self.thumbnailData = thumbnailData
        self.items = items
        self.dishImages = dishImages
    }
}

// MARK: - Error Handling Types

/// 统一的应用错误类型
struct AppError: LocalizedError, Identifiable {
    let id = UUID()
    let type: ErrorType
    let context: String
    let underlyingError: Error?
    let timestamp: Date = Date()
    
    enum ErrorType {
        case network
        case parsing
        case validation
        case service
        case user
        case system
        case unknown
    }
    
    var errorDescription: String? {
        if let underlyingError = underlyingError {
            return "\(context): \(underlyingError.localizedDescription)"
        }
        return context
    }
    
    var userFriendlyMessage: String {
        switch type {
        case .network:
            return "网络连接出现问题，请检查网络设置"
        case .parsing:
            return "数据处理失败，请重试"
        case .validation:
            return "输入数据有误，请检查后重试"
        case .service:
            return "服务暂时不可用，请稍后重试"
        case .user:
            return "操作失败，请重试"
        case .system:
            return "系统错误，请重启应用"
        case .unknown:
            return "未知错误，请重试"
        }
    }
    
    var canRetry: Bool {
        switch type {
        case .network, .service, .parsing, .unknown:
            return true
        case .validation, .user, .system:
            return false
        }
    }
    
    var recoveryOptions: [String] {
        switch type {
        case .network:
            return ["检查网络", "重试", "使用离线模式"]
        case .service:
            return ["重试", "稍后再试", "联系客服"]
        case .parsing, .unknown:
            return ["重试", "重新开始"]
        case .validation:
            return ["检查输入", "重新输入"]
        case .user:
            return ["重试", "查看帮助"]
        case .system:
            return ["重启应用", "联系客服"]
        }
    }
    
    static func fromError(_ error: Error, context: String) -> AppError {
        let errorType: ErrorType
        
        // 根据错误类型推断分类
        if error.localizedDescription.contains("network") || 
           error.localizedDescription.contains("连接") {
            errorType = .network
        } else if error.localizedDescription.contains("parse") ||
                  error.localizedDescription.contains("解析") {
            errorType = .parsing
        } else if error.localizedDescription.contains("service") ||
                  error.localizedDescription.contains("服务") {
            errorType = .service
        } else {
            errorType = .unknown
        }
        
        return AppError(
            type: errorType,
            context: context,
            underlyingError: error
        )
    }
}

// MARK: - 注释：以下类型已移动到GoogleSearchService.swift避免重复定义
// - ImageSearchResult
// - GoogleSearchResponse  
// - GoogleSearchItem
// - GoogleImageInfo 
