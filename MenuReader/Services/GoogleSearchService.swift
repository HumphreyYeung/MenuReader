//
//  GoogleSearchService.swift
//  MenuReader
//
//  Created by MenuReader on 2025-06-13.
//

import Foundation
import UIKit

/// 统一的图片搜索和管理服务 - 整合了ImageService功能
@MainActor
final class GoogleSearchService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = GoogleSearchService()
    
    // MARK: - Published Properties
    
    /// 图片加载状态
    @Published private(set) var loadingStates: [String: ImageLoadingState] = [:]
    
    // MARK: - Private Properties
    
    private let apiClient: NetworkService
    
    // MARK: - Initialization
    
    private init() {
        self.apiClient = NetworkService.shared
    }
    
    // MARK: - Public Methods - 菜品图片获取（整合自ImageService）
    
    /// 获取菜品图片（主要方法）
    func getDishImages(for menuItem: MenuItemAnalysis, count: Int = 3) async throws -> [DishImage] {
        let cacheKey = generateCacheKey(for: menuItem)
        let searchQuery = menuItem.imageSearchQuery ?? menuItem.translatedName ?? menuItem.originalName
        
        print("🖼️ GoogleSearchService.getDishImages - 开始获取图片")
        print("📝 菜品名称: \(menuItem.originalName)")
        print("🔍 搜索查询: \(searchQuery)")
        
        // 更新加载状态
        loadingStates[cacheKey] = .loading
        
        do {
            // 从API获取图片
            let searchResults = try await searchImages(for: searchQuery, count: count)
            
            print("✅ 搜索返回 \(searchResults.count) 个搜索结果")
            
            // 转换为DishImage
            let dishImages = convertToDishImages(searchResults, for: menuItem)
            
            print("✅ 转换为 \(dishImages.count) 个 DishImage 对象")
            
            // 更新状态
            loadingStates[cacheKey] = .loaded(dishImages)
            
            return dishImages
            
        } catch {
            print("❌ GoogleSearchService.getDishImages 失败: \(error)")
            loadingStates[cacheKey] = .failed(error)
            throw ImageServiceError.loadingFailed(error.localizedDescription)
        }
    }
    
    /// 获取加载状态
    func getLoadingState(for menuItem: MenuItemAnalysis) -> ImageLoadingState {
        let cacheKey = generateCacheKey(for: menuItem)
        return loadingStates[cacheKey] ?? .idle
    }
    
    /// 清理状态
    func clearStates() {
        loadingStates.removeAll()
    }
    
    // MARK: - Public Methods - 图片搜索
    
    /// 搜索图片
    func searchImages(for query: String, count: Int = 5) async throws -> [ImageSearchResult] {
        print("🔍 GoogleSearchService.searchImages 开始搜索: \(query)")
        
        let endpoint = GoogleSearchEndpoint.searchImages(query: query, num: count)
        
        do {
            let response: GoogleSearchResponse = try await apiClient.request(
                endpoint,
                responseType: GoogleSearchResponse.self
            )
            
            let results = parseSearchResponse(response)
            print("✅ GoogleSearchService.searchImages 找到 \(results.count) 个结果")
            return results
            
        } catch {
            print("❌ GoogleSearchService.searchImages 失败: \(error)")
            throw GoogleSearchError.searchFailed(error.localizedDescription)
        }
    }
    
    /// 搜索菜品相关图片
    func searchDishImages(dishName: String, count: Int = 5) async throws -> [ImageSearchResult] {
        let query = "\(dishName) dish food recipe"
        return try await searchImages(for: query, count: count)
    }
    
    // MARK: - Service Health
    
    /// 测试搜索服务连接
    func testConnection() async throws -> Bool {
        let testResults = try await searchImages(for: "test food", count: 1)
        return !testResults.isEmpty
    }
    
    // MARK: - Private Methods
    
    private func generateCacheKey(for menuItem: MenuItemAnalysis) -> String {
        let name = menuItem.translatedName ?? menuItem.originalName
        return "dish_images_\(name.hash)"
    }
    
    private func convertToDishImages(_ searchResults: [ImageSearchResult], for menuItem: MenuItemAnalysis) -> [DishImage] {
        return searchResults.compactMap { result in
            // 基本验证
            guard !result.imageURL.isEmpty else { return nil }
            
            return DishImage(
                id: result.id,
                title: result.title,
                imageURL: result.imageURL,
                thumbnailURL: result.thumbnailURL ?? result.imageURL,
                sourceURL: result.sourceURL,
                width: result.width,
                height: result.height,
                menuItemName: menuItem.originalName,
                isLoaded: false
            )
        }
    }
    
    private func parseSearchResponse(_ response: GoogleSearchResponse) -> [ImageSearchResult] {
        return response.items?.compactMap { item in
            guard let imageInfo = item.image,
                  let link = item.link else {
                return nil
            }
            
            return ImageSearchResult(
                id: UUID(),
                title: item.title ?? "未知图片",
                imageURL: link,
                thumbnailURL: imageInfo.thumbnailLink,
                sourceURL: item.displayLink,
                width: imageInfo.width,
                height: imageInfo.height
            )
        } ?? []
    }
}

// MARK: - Supporting Types

/// 图片加载状态
enum ImageLoadingState: Equatable {
    case idle
    case loading
    case loaded([DishImage])
    case failed(Error)
    
    static func == (lhs: ImageLoadingState, rhs: ImageLoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading):
            return true
        case (.loaded(let lhsImages), .loaded(let rhsImages)):
            return lhsImages.count == rhsImages.count
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

/// 菜品图片模型
struct DishImage: Identifiable, Codable {
    let id: UUID
    let title: String
    let imageURL: String
    let thumbnailURL: String
    let sourceURL: String?
    let width: Int?
    let height: Int?
    let menuItemName: String
    var isLoaded: Bool
    
    init(id: UUID = UUID(),
         title: String,
         imageURL: String,
         thumbnailURL: String,
         sourceURL: String? = nil,
         width: Int? = nil,
         height: Int? = nil,
         menuItemName: String,
         isLoaded: Bool = false) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.sourceURL = sourceURL
        self.width = width
        self.height = height
        self.menuItemName = menuItemName
        self.isLoaded = isLoaded
    }
}

/// 图片服务错误
enum ImageServiceError: LocalizedError {
    case loadingFailed(String)
    case invalidURL
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "图片加载失败: \(message)"
        case .invalidURL:
            return "无效的图片URL"
        case .networkError:
            return "网络连接错误"
        }
    }
}

/// Google搜索错误
enum GoogleSearchError: LocalizedError {
    case searchFailed(String)
    case invalidResponse
    case apiKeyMissing
    
    var errorDescription: String? {
        switch self {
        case .searchFailed(let message):
            return "搜索失败: \(message)"
        case .invalidResponse:
            return "无效的响应格式"
        case .apiKeyMissing:
            return "缺少API密钥"
        }
    }
}

// MARK: - Google Search Response Models

struct GoogleSearchResponse: Codable {
    let items: [GoogleSearchItem]?
}

struct GoogleSearchItem: Codable {
    let title: String?
    let link: String?
    let displayLink: String?
    let image: GoogleImageInfo?
}

struct GoogleImageInfo: Codable {
    let width: Int?
    let height: Int?
    let thumbnailLink: String?
}

struct ImageSearchResult: Identifiable {
    let id: UUID
    let title: String
    let imageURL: String
    let thumbnailURL: String?
    let sourceURL: String?
    let width: Int?
    let height: Int?
} 
