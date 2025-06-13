//
//  ImageService.swift
//  MenuReader
//
//  Created by MenuReader on 2025-06-13.
//

import Foundation
import UIKit
import SDWebImage

/// 菜品图片检索服务 - Task005实现
@MainActor
final class ImageService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ImageService()
    
    // MARK: - Published Properties
    
    /// 图片加载状态
    @Published private(set) var loadingStates: [String: ImageLoadingState] = [:]
    
    /// 缓存的图片
    @Published private(set) var cachedImages: [String: UIImage] = [:]
    
    // MARK: - Private Properties
    
    private let googleSearchService: GoogleSearchService
    private let imageCache: NSCache<NSString, UIImage>
    private let urlCache: URLCache
    private let maxCacheSize: Int = 100 * 1024 * 1024 // 100MB
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7天
    
    // MARK: - Initialization
    
    private init() {
        self.googleSearchService = GoogleSearchService.shared
        
        // 配置图片缓存
        self.imageCache = NSCache<NSString, UIImage>()
        self.imageCache.totalCostLimit = maxCacheSize
        self.imageCache.countLimit = 200 // 最多缓存200张图片
        
        // 配置URL缓存
        self.urlCache = URLCache(
            memoryCapacity: 20 * 1024 * 1024, // 20MB内存缓存
            diskCapacity: 100 * 1024 * 1024,  // 100MB磁盘缓存
            diskPath: "MenuReaderImageCache"
        )
        
        // 配置SDWebImage
        configureSDWebImage()
    }
    
    // MARK: - Public Methods
    
    /// 获取菜品图片（主要方法）
    func getDishImages(for menuItem: MenuItemAnalysis, count: Int = 3) async throws -> [DishImage] {
        let cacheKey = generateCacheKey(for: menuItem)
        
        // 更新加载状态
        loadingStates[cacheKey] = .loading
        
        do {
            // 1. 检查缓存
            if let cachedImages = getCachedDishImages(for: cacheKey) {
                loadingStates[cacheKey] = .loaded(cachedImages)
                return cachedImages
            }
            
            // 2. 从API获取图片
            let searchResults = try await googleSearchService.searchImages(
                for: menuItem.imageSearchQuery ?? menuItem.translatedName ?? menuItem.originalName,
                count: count
            )
            
            // 3. 转换为DishImage并预加载缩略图
            let dishImages = try await convertToDishImages(searchResults, for: menuItem)
            
            // 4. 缓存结果
            cacheDishImages(dishImages, for: cacheKey)
            
            // 5. 更新状态
            loadingStates[cacheKey] = .loaded(dishImages)
            
            return dishImages
            
        } catch {
            loadingStates[cacheKey] = .failed(error)
            throw ImageServiceError.loadingFailed(error.localizedDescription)
        }
    }
    
    /// 批量获取菜品图片
    func getDishImagesForMenuItems(_ menuItems: [MenuItemAnalysis]) async throws -> [String: [DishImage]] {
        var results: [String: [DishImage]] = [:]
        
        // 并发处理，但限制并发数量以避免过载
        try await withThrowingTaskGroup(of: (String, [DishImage]).self) { group in
            for item in menuItems.prefix(5) { // 限制并发数量
                group.addTask {
                    let images = try await self.getDishImages(for: item, count: 2)
                    return (item.originalName, images)
                }
            }
            
            for try await (itemName, images) in group {
                results[itemName] = images
            }
        }
        
        return results
    }
    
    /// 预加载图片（懒加载支持）
    func preloadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        
        // 检查内存缓存
        let cacheKey = NSString(string: urlString)
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // 使用SDWebImage加载
        return await withCheckedContinuation { continuation in
            SDWebImageManager.shared.loadImage(
                with: url,
                options: [.retryFailed, .scaleDownLargeImages],
                progress: nil
            ) { [weak self] image, _, error, _, _, _ in
                if let image = image {
                    // 缓存到内存
                    self?.imageCache.setObject(image, forKey: cacheKey)
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    /// 获取加载状态
    func getLoadingState(for menuItem: MenuItemAnalysis) -> ImageLoadingState {
        let cacheKey = generateCacheKey(for: menuItem)
        return loadingStates[cacheKey] ?? .idle
    }
    
    /// 清理缓存
    func clearCache() {
        imageCache.removeAllObjects()
        urlCache.removeAllCachedResponses()
        cachedImages.removeAll()
        loadingStates.removeAll()
        
        // 清理SDWebImage缓存
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()
    }
    
    /// 清理过期缓存
    func clearExpiredCache() {
        // SDWebImage会自动处理过期缓存
        SDImageCache.shared.deleteOldFiles()
    }
    
    // MARK: - Private Methods
    
    private func configureSDWebImage() {
        // 配置SDWebImage缓存策略
        let cache = SDImageCache.shared
        cache.config.maxMemoryCost = 50 * 1024 * 1024 // 50MB内存缓存
        cache.config.maxDiskSize = 200 * 1024 * 1024   // 200MB磁盘缓存
        cache.config.maxDiskAge = maxCacheAge           // 7天过期
        cache.config.shouldCacheImagesInMemory = true
        
        // 配置下载器
        let downloader = SDWebImageDownloader.shared
        downloader.config.downloadTimeout = 30.0
        downloader.config.maxConcurrentDownloads = 3
    }
    
    private func generateCacheKey(for menuItem: MenuItemAnalysis) -> String {
        let name = menuItem.translatedName ?? menuItem.originalName
        return "dish_images_\(name.hash)"
    }
    
    private func getCachedDishImages(for cacheKey: String) -> [DishImage]? {
        // 这里可以实现更复杂的缓存逻辑
        // 目前简单返回nil，让系统重新获取
        return nil
    }
    
    private func cacheDishImages(_ images: [DishImage], for cacheKey: String) {
        // 缓存图片信息（不包括实际图片数据，那些由SDWebImage处理）
        // 这里可以保存图片元数据到UserDefaults或Core Data
    }
    
    private func convertToDishImages(_ searchResults: [ImageSearchResult], for menuItem: MenuItemAnalysis) async throws -> [DishImage] {
        var dishImages: [DishImage] = []
        
        for result in searchResults {
            // 验证图片URL
            let isValid = await googleSearchService.validateImageURL(result.imageURL)
            guard isValid else { continue }
            
            let dishImage = DishImage(
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
            
            dishImages.append(dishImage)
        }
        
        return dishImages
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
    case cacheError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "图片加载失败: \(message)"
        case .invalidURL:
            return "无效的图片URL"
        case .cacheError:
            return "缓存错误"
        case .networkError:
            return "网络连接错误"
        }
    }
} 