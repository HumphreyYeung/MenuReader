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
} 