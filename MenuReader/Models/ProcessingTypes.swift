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
    
    enum CodingKeys: String, CodingKey {
        case originalName, translatedName, description, price, confidence, category, imageSearchQuery
    }
    
    init(originalName: String, 
         translatedName: String? = nil,
         description: String? = nil,
         price: String? = nil,
         confidence: Double = 0.95,
         category: String? = nil,
         imageSearchQuery: String? = nil) {
        self.originalName = originalName
        self.translatedName = translatedName
        self.description = description
        self.price = price
        self.confidence = confidence
        self.category = category
        self.imageSearchQuery = imageSearchQuery
    }
}

// MARK: - Image Search Result
struct ImageSearchResult: Codable, Identifiable {
    let id = UUID()
    let title: String
    let imageURL: String
    let thumbnailURL: String?
    let sourceURL: String?
    let width: Int?
    let height: Int?
    
    enum CodingKeys: String, CodingKey {
        case title, imageURL, thumbnailURL, sourceURL, width, height
    }
    
    init(title: String,
         imageURL: String,
         thumbnailURL: String? = nil,
         sourceURL: String? = nil,
         width: Int? = nil,
         height: Int? = nil) {
        self.title = title
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.sourceURL = sourceURL
        self.width = width
        self.height = height
    }
}

// MARK: - Google Search Response
struct GoogleSearchResponse: Codable {
    let items: [GoogleSearchItem]?
    let searchInformation: GoogleSearchInformation?
}

struct GoogleSearchItem: Codable {
    let title: String
    let link: String
    let image: GoogleImageInfo?
}

struct GoogleImageInfo: Codable {
    let contextLink: String?
    let height: Int?
    let width: Int?
    let byteSize: Int?
    let thumbnailLink: String?
    let thumbnailHeight: Int?
    let thumbnailWidth: Int?
}

struct GoogleSearchInformation: Codable {
    let searchTime: Double?
    let formattedSearchTime: String?
    let totalResults: String?
    let formattedTotalResults: String?
}

// MARK: - Menu Process Result (for NetworkService compatibility)
// Note: MenuItem is defined in MenuItem.swift
struct MenuProcessResult: Codable {
    let items: [MenuItemAnalysis]
    
    init(items: [MenuItemAnalysis]) {
        self.items = items
    }
} 
