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
struct MenuItemAnalysis: Codable, Identifiable {
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
struct MenuProcessResult: Codable, Identifiable {
    let id: UUID
    let items: [MenuItemAnalysis]
    let scanDate: Date
    let isFavorite: Bool
    let thumbnailData: Data? // Compressed image data for thumbnail
    
    enum CodingKeys: String, CodingKey {
        case id, items, scanDate, isFavorite, thumbnailData
    }
    
    init(items: [MenuItemAnalysis], scanDate: Date = Date(), isFavorite: Bool = false, thumbnailData: Data? = nil, id: UUID = UUID()) {
        self.id = id
        self.items = items
        self.scanDate = scanDate
        self.isFavorite = isFavorite
        self.thumbnailData = thumbnailData
    }
}

// MARK: - 注释：以下类型已移动到GoogleSearchService.swift避免重复定义
// - ImageSearchResult
// - GoogleSearchResponse  
// - GoogleSearchItem
// - GoogleImageInfo 
