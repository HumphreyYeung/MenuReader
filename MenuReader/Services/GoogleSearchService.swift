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
    
    /// 图片加载状态 - 作为唯一真实来源
    @Published private(set) var loadingStates: [String: ImageLoadingState] = [:]
    
    // MARK: - Private Properties
    
    private let apiClient: NetworkService
    
    // MARK: - Initialization
    
    private init() {
        self.apiClient = NetworkService.shared
    }
    
    // MARK: - Public State Management Methods
    
    /// 公共方法：更新菜品的图片加载状态
    func updateState(for menuItemName: String, to state: ImageLoadingState) {
        print("🔄 [GoogleSearchService] 更新状态: \(menuItemName) -> \(stateDescription(state))")
        loadingStates[menuItemName] = state
    }
    
    /// 公共方法：获取菜品的图片加载状态
    func getLoadingState(for menuItem: MenuItemAnalysis) -> ImageLoadingState {
        // 修复：统一使用 originalName 作为键，确保一致性
        let cacheKey = menuItem.originalName
        let state = loadingStates[cacheKey] ?? .idle
        print("📊 [GoogleSearchService] 查询状态: \(menuItem.originalName) -> \(stateDescription(state))")
        return state
    }
    
    /// 清理所有状态
    func clearStates() {
        loadingStates.removeAll()
        print("🧹 [GoogleSearchService] 清理所有状态")
    }
    
    // MARK: - Public Methods - 菜品图片获取
    
    /// 获取菜品图片（核心方法）- 现在专注于数据获取，状态管理由调用方负责
    func getDishImages(for menuItem: MenuItemAnalysis, count: Int = 3) async throws -> [DishImage] {
        let searchQuery = menuItem.imageSearchQuery ?? menuItem.translatedName ?? menuItem.originalName
        
        print("🖼️ [GoogleSearchService.getDishImages] 开始获取图片")
        print("📝 菜品名称: \(menuItem.originalName)")
        print("🔍 搜索查询: \(searchQuery)")
        
        do {
            // 从API获取图片
            let searchResults = try await searchImages(for: searchQuery, count: count)
            
            print("✅ 搜索返回 \(searchResults.count) 个搜索结果")
            
            // 转换为DishImage
            let dishImages = convertToDishImages(searchResults, for: menuItem)
            
            print("✅ 转换为 \(dishImages.count) 个 DishImage 对象")
            
            return dishImages
            
        } catch {
            print("❌ GoogleSearchService.getDishImages 失败: \(error)")
            throw ImageServiceError.loadingFailed(error.localizedDescription)
        }
    }
    
    /// 获取菜品图片（带状态管理）- 兼容现有代码的方法
    func getDishImagesWithStateManagement(for menuItem: MenuItemAnalysis, count: Int = 3) async throws -> [DishImage] {
        let menuItemName = menuItem.originalName
        
        // 更新状态为加载中
        updateState(for: menuItemName, to: .loading)
        
        do {
            // 获取图片数据
            let dishImages = try await getDishImages(for: menuItem, count: count)
            
            // 更新状态为加载完成
            updateState(for: menuItemName, to: .loaded(dishImages))
            
            return dishImages
            
        } catch {
            // 更新状态为失败
            updateState(for: menuItemName, to: .failed(error))
            throw error
        }
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
    
    // MARK: - Debug & Testing Methods
    
    /// 调试方法：打印当前所有状态
    func printAllStates() {
        print("🔍 [GoogleSearchService] 当前所有状态:")
        if loadingStates.isEmpty {
            print("   - 无状态记录")
        } else {
            for (key, state) in loadingStates {
                print("   - \(key): \(stateDescription(state))")
            }
        }
    }
    
    /// 调试方法：检查指定菜品的状态
    func debugState(for menuItemName: String) {
        let state = loadingStates[menuItemName] ?? .idle
        print("🔍 [GoogleSearchService] \(menuItemName) 状态: \(stateDescription(state))")
    }
    

    
    // MARK: - Private Methods
    
    private func generateCacheKey(for menuItem: MenuItemAnalysis) -> String {
        // 修复：统一使用 originalName 确保一致性
        let name = menuItem.originalName
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
    
    /// 状态描述方法，用于调试
    private func stateDescription(_ state: ImageLoadingState) -> String {
        switch state {
        case .idle:
            return "空闲"
        case .loading:
            return "加载中"
        case .loaded(let images):
            return "已加载(\(images.count)张图片)"
        case .failed(let error):
            return "失败(\(error.localizedDescription))"
        }
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
