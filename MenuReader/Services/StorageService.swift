//
//  StorageService.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import Foundation
import Combine
import UIKit

// MARK: - Storage Service Protocol
protocol StorageServiceProtocol {
    func saveUserProfile(_ profile: UserProfile)
    func loadUserProfile() -> UserProfile
    func saveCartItems(_ items: [CartItem])
    func loadCartItems() -> [CartItem]
    func clearCart()
    func saveMenuHistory(_ result: MenuProcessResult)
    func saveMenuHistory(_ result: MenuProcessResult, originalImage: UIImage?)
    func loadMenuHistory() -> [MenuProcessResult]
    func deleteMenuHistoryItem(withId id: UUID)
    func toggleFavoriteHistoryItem(withId id: UUID)
    func getMenuHistoryPaginated(page: Int, pageSize: Int) -> [MenuProcessResult]
    func getMenuHistoryCount() -> Int
    
    // MARK: - Offline Queue Management
    func addToPendingUploadQueue(_ result: MenuProcessResult)
    func getPendingUploadQueue() -> [MenuProcessResult]
    func removePendingUploadItem(withId id: UUID)
    func clearPendingUploadQueue()
    
    // MARK: - Storage Management
    func getStorageSize() -> Int64
    func cleanupOldData(keepRecentDays: Int)
    func getMaxStorageLimit() -> Int64
    func setMaxStorageLimit(_ limit: Int64)
}

// MARK: - Storage Service Implementation
class StorageService: ObservableObject, StorageServiceProtocol, @unchecked Sendable {
    static let shared = StorageService()
    
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // Storage Keys
    private enum Keys {
        static let userProfile = "userProfile"
        static let cartItems = "cartItems"
        static let menuHistory = "menuHistory"
        static let pendingUploadQueue = "pendingUploadQueue"
        static let maxStorageLimit = "maxStorageLimit"
    }
    
    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - User Profile
    func saveUserProfile(_ profile: UserProfile) {
        do {
            let data = try encoder.encode(profile)
            userDefaults.set(data, forKey: Keys.userProfile)
        } catch {
            print("Failed to save user profile: \(error)")
        }
    }
    
    func loadUserProfile() -> UserProfile {
        guard let data = userDefaults.data(forKey: Keys.userProfile),
              let profile = try? decoder.decode(UserProfile.self, from: data) else {
            return UserProfile() // Return default profile
        }
        return profile
    }
    
    // MARK: - Cart Items
    func saveCartItems(_ items: [CartItem]) {
        do {
            let data = try encoder.encode(items)
            userDefaults.set(data, forKey: Keys.cartItems)
        } catch {
            print("Failed to save cart items: \(error)")
        }
    }
    
    func loadCartItems() -> [CartItem] {
        guard let data = userDefaults.data(forKey: Keys.cartItems),
              let items = try? decoder.decode([CartItem].self, from: data) else {
            return []
        }
        return items
    }
    
    func clearCart() {
        userDefaults.removeObject(forKey: Keys.cartItems)
    }
    
    // MARK: - Menu History
    func saveMenuHistory(_ result: MenuProcessResult) {
        saveMenuHistory(result, originalImage: nil)
    }
    
    func saveMenuHistory(_ result: MenuProcessResult, originalImage: UIImage?) {
        var updatedResult = result
        
        // Generate thumbnail if original image is provided
        if let image = originalImage, result.thumbnailData == nil {
            let thumbnailData = ImageUtils.generateThumbnailData(from: image)
            updatedResult = MenuProcessResult(
                items: result.items,
                scanDate: result.scanDate,
                isFavorite: result.isFavorite,
                thumbnailData: thumbnailData,
                id: result.id
            )
        }
        
        var history = loadMenuHistory()
        history.insert(updatedResult, at: 0) // Add to beginning
        
        // Remove 50-item limit as requested - keep all items
        do {
            let data = try encoder.encode(history)
            userDefaults.set(data, forKey: Keys.menuHistory)
        } catch {
            print("Failed to save menu history: \(error)")
        }
    }
    
    func loadMenuHistory() -> [MenuProcessResult] {
        guard let data = userDefaults.data(forKey: Keys.menuHistory),
              let history = try? decoder.decode([MenuProcessResult].self, from: data) else {
            return []
        }
        return history
    }
    
    func deleteMenuHistoryItem(withId id: UUID) {
        var history = loadMenuHistory()
        history.removeAll { $0.id == id }
        
        do {
            let data = try encoder.encode(history)
            userDefaults.set(data, forKey: Keys.menuHistory)
        } catch {
            print("Failed to delete menu history item: \(error)")
        }
    }
    
    func toggleFavoriteHistoryItem(withId id: UUID) {
        var history = loadMenuHistory()
        
        if let index = history.firstIndex(where: { $0.id == id }) {
            let item = history[index]
            history[index] = MenuProcessResult(
                items: item.items,
                scanDate: item.scanDate,
                isFavorite: !item.isFavorite,
                thumbnailData: item.thumbnailData,
                id: item.id
            )
        }
        
        do {
            let data = try encoder.encode(history)
            userDefaults.set(data, forKey: Keys.menuHistory)
        } catch {
            print("Failed to toggle favorite menu history item: \(error)")
        }
    }
    
    func getMenuHistoryPaginated(page: Int, pageSize: Int) -> [MenuProcessResult] {
        let history = loadMenuHistory()
        let startIndex = page * pageSize
        let endIndex = min(startIndex + pageSize, history.count)
        
        guard startIndex < history.count else { return [] }
        return Array(history[startIndex..<endIndex])
    }
    
    func getMenuHistoryCount() -> Int {
        return loadMenuHistory().count
    }
    
    // MARK: - Offline Queue Management
    
    func addToPendingUploadQueue(_ result: MenuProcessResult) {
        var queue = getPendingUploadQueue()
        
        // 避免重复添加
        if !queue.contains(where: { $0.id == result.id }) {
            queue.append(result)
            
            do {
                let data = try encoder.encode(queue)
                userDefaults.set(data, forKey: Keys.pendingUploadQueue)
                print("💾 [StorageService] 已添加到待上传队列: \(result.id)")
            } catch {
                print("❌ [StorageService] 保存待上传队列失败: \(error)")
            }
        }
    }
    
    func getPendingUploadQueue() -> [MenuProcessResult] {
        guard let data = userDefaults.data(forKey: Keys.pendingUploadQueue),
              let queue = try? decoder.decode([MenuProcessResult].self, from: data) else {
            return []
        }
        return queue
    }
    
    func removePendingUploadItem(withId id: UUID) {
        var queue = getPendingUploadQueue()
        queue.removeAll { $0.id == id }
        
        do {
            let data = try encoder.encode(queue)
            userDefaults.set(data, forKey: Keys.pendingUploadQueue)
            print("🗑️ [StorageService] 已从待上传队列移除: \(id)")
        } catch {
            print("❌ [StorageService] 更新待上传队列失败: \(error)")
        }
    }
    
    func clearPendingUploadQueue() {
        userDefaults.removeObject(forKey: Keys.pendingUploadQueue)
        print("🧹 [StorageService] 已清空待上传队列")
    }
    
    // MARK: - Storage Management
    
    func getStorageSize() -> Int64 {
        var totalSize: Int64 = 0
        
        // 计算菜单历史大小
        if let data = userDefaults.data(forKey: Keys.menuHistory) {
            totalSize += Int64(data.count)
        }
        
        // 计算用户配置文件大小
        if let data = userDefaults.data(forKey: Keys.userProfile) {
            totalSize += Int64(data.count)
        }
        
        // 计算购物车数据大小
        if let data = userDefaults.data(forKey: Keys.cartItems) {
            totalSize += Int64(data.count)
        }
        
        // 计算待上传队列大小
        if let data = userDefaults.data(forKey: Keys.pendingUploadQueue) {
            totalSize += Int64(data.count)
        }
        
        return totalSize
    }
    
    func cleanupOldData(keepRecentDays: Int = 30) {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(keepRecentDays * 24 * 60 * 60))
        var history = loadMenuHistory()
        let originalCount = history.count
        
        // 保留最近的数据和收藏的数据
        history = history.filter { result in
            result.scanDate > cutoffDate || result.isFavorite
        }
        
        let removedCount = originalCount - history.count
        
        if removedCount > 0 {
            do {
                let data = try encoder.encode(history)
                userDefaults.set(data, forKey: Keys.menuHistory)
                print("🧹 [StorageService] 清理完成，移除了 \(removedCount) 条旧记录")
            } catch {
                print("❌ [StorageService] 清理数据失败: \(error)")
            }
        }
    }
    
    func getMaxStorageLimit() -> Int64 {
        let defaultLimit: Int64 = 100 * 1024 * 1024 // 100MB 默认限制
        return userDefaults.object(forKey: Keys.maxStorageLimit) as? Int64 ?? defaultLimit
    }
    
    func setMaxStorageLimit(_ limit: Int64) {
        userDefaults.set(limit, forKey: Keys.maxStorageLimit)
        print("📏 [StorageService] 存储限制已设置为: \(limit / 1024 / 1024)MB")
        
        // 检查是否需要立即清理
        let currentSize = getStorageSize()
        if currentSize > limit {
            let targetDays = max(7, Int(Double(limit) / Double(currentSize) * 30))
            cleanupOldData(keepRecentDays: targetDays)
        }
    }
} 