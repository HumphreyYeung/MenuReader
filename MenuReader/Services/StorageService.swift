//
//  StorageService.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 2025-01-16.
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
    func loadMenuHistory() -> [MenuProcessResult]
    func deleteMenuHistoryItem(withId id: UUID)
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
        var history = loadMenuHistory()
        history.insert(result, at: 0) // Add to beginning
        
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
        // 1. 获取所有历史记录
        let history = loadMenuHistory()
        
        // 2. 计算截止日期
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -keepRecentDays, to: Date()) else {
            print("❌ [StorageService] 无法计算截止日期")
            return
        }
        
        // 3. 过滤需要保留的项
        let itemsToKeep = history.filter { $0.scanDate >= cutoffDate }
        
        // 4. 保存过滤后的历史记录
        do {
            let data = try encoder.encode(itemsToKeep)
            userDefaults.set(data, forKey: Keys.menuHistory)
            print("✅ [StorageService] 已清理旧数据，保留了最近 \(keepRecentDays) 天的 \(itemsToKeep.count) 条记录")
        } catch {
            print("❌ [StorageService] 保存清理后的历史记录失败: \(error)")
        }
    }
    
    func getMaxStorageLimit() -> Int64 {
        let defaultLimit: Int64 = 100 * 1024 * 1024 // 100MB 默认限制
        return userDefaults.object(forKey: Keys.maxStorageLimit) as? Int64 ?? defaultLimit
    }
    
    func setMaxStorageLimit(_ limit: Int64) {
        userDefaults.set(limit, forKey: Keys.maxStorageLimit)
        print("📏 [StorageService] 存储限制已设置为: \(limit / 1024 / 1024)MB")
    }
} 