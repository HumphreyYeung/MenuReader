//
//  GoogleSearchService.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import Foundation
import UIKit

class GoogleSearchService: ObservableObject, @unchecked Sendable {
    static let shared = GoogleSearchService()
    
    private let apiClient: APIClient
    private let maxResults = 10
    
    private init() {
        self.apiClient = APIClient.shared
    }
    
    // MARK: - Image Search
    func searchImages(for query: String, count: Int = 5) async throws -> [ImageSearchResult] {
        // 清理搜索查询
        let cleanQuery = cleanSearchQuery(query)
        
        let endpoint = GoogleSearchEndpoint.searchImages(query: cleanQuery, num: min(count, maxResults))
        
        do {
            let response = try await apiClient.request(endpoint, responseType: GoogleSearchResponse.self)
            return parseImageSearchResults(response)
        } catch {
            throw error
        }
    }
    
    // MARK: - Batch Search
    func searchImagesForMenuItems(_ menuItems: [MenuItemAnalysis]) async throws -> [String: [ImageSearchResult]] {
        var results: [String: [ImageSearchResult]] = [:]
        
        // 并发搜索多个菜品
        try await withThrowingTaskGroup(of: (String, [ImageSearchResult]).self) { group in
            for item in menuItems.prefix(5) { // 限制并发数量
                group.addTask {
                    let query = item.imageSearchQuery ?? item.translatedName ?? item.originalName
                    let images = try await self.searchImages(for: query, count: 3)
                    return (item.originalName, images)
                }
            }
            
            for try await (itemName, images) in group {
                results[itemName] = images
            }
        }
        
        return results
    }
    
    // MARK: - Helper Methods
    
    private func cleanSearchQuery(_ query: String) -> String {
        // 移除价格和特殊字符，保留菜品名称
        var cleanQuery = query
        
        // 移除常见的价格模式
        let pricePatterns = [
            "\\$[0-9]+(\\.[0-9]{2})?", // $12.99
            "[0-9]+\\.[0-9]{2}", // 12.99
            "¥[0-9]+", // ¥100
            "€[0-9]+(\\.[0-9]{2})?", // €12.99
            "£[0-9]+(\\.[0-9]{2})?", // £12.99
            "[0-9]+元", // 100元
            "[0-9]+円" // 100円
        ]
        
        for pattern in pricePatterns {
            cleanQuery = cleanQuery.replacingOccurrences(
                of: pattern,
                with: "",
                options: .regularExpression
            )
        }
        
        // 移除特殊字符，保留字母、数字、空格和中文字符
        let allowedCharacters = CharacterSet.alphanumerics
            .union(.whitespacesAndNewlines)
            .union(CharacterSet(charactersIn: "一二三四五六七八九十"))
        
        cleanQuery = String(cleanQuery.unicodeScalars.filter { allowedCharacters.contains($0) })
        
        // 清理多余空格
        cleanQuery = cleanQuery
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // 添加 "food" 关键词以提高搜索准确性
        if !cleanQuery.isEmpty {
            cleanQuery += " food dish"
        }
        
        return cleanQuery
    }
    
    private func parseImageSearchResults(_ response: GoogleSearchResponse) -> [ImageSearchResult] {
        guard let items = response.items else {
            return []
        }
        
        return items.compactMap { item in
            // 确保有有效的图片链接
            guard !item.link.isEmpty else { return nil }
            
            let result = ImageSearchResult(
                title: item.title,
                imageURL: item.link,
                thumbnailURL: item.image?.thumbnailLink,
                sourceURL: item.image?.contextLink,
                width: item.image?.width,
                height: item.image?.height
            )
            
            return result
        }
    }
    
    // MARK: - Image Validation
    func validateImageURL(_ urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else {
            return false
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            
            // 检查状态码和内容类型
            let isValidStatus = (200...299).contains(httpResponse.statusCode)
            let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? ""
            let isImage = contentType.hasPrefix("image/")
            
            return isValidStatus && isImage
        } catch {
            return false
        }
    }
    
    // MARK: - Testing
    func testConnection() async throws -> Bool {
        let testResults = try await searchImages(for: "pizza", count: 1)
        return !testResults.isEmpty
    }
}

// MARK: - Search Query Enhancement
extension GoogleSearchService {
    // 根据菜品分析结果优化搜索查询
    func enhanceSearchQuery(for menuItem: MenuItemAnalysis) -> String {
        var queryComponents: [String] = []
        
        // 优先使用翻译后的名称
        if let translatedName = menuItem.translatedName, !translatedName.isEmpty {
            queryComponents.append(translatedName)
        } else {
            queryComponents.append(menuItem.originalName)
        }
        
        // 添加分类信息
        if let category = menuItem.category, !category.isEmpty {
            queryComponents.append(category)
        }
        
        // 添加描述关键词
        if let description = menuItem.description, !description.isEmpty {
            let keywords = extractKeywords(from: description)
            queryComponents.append(contentsOf: keywords.prefix(2))
        }
        
        let query = queryComponents.joined(separator: " ")
        return cleanSearchQuery(query)
    }
    
    private func extractKeywords(from description: String) -> [String] {
        let commonWords = ["with", "and", "or", "the", "a", "an", "in", "on", "at", "to", "for", "of", "by"]
        
        return description
            .lowercased()
            .components(separatedBy: .punctuationCharacters)
            .joined(separator: " ")
            .components(separatedBy: .whitespaces)
            .filter { word in
                word.count > 2 && !commonWords.contains(word)
            }
    }
} 
