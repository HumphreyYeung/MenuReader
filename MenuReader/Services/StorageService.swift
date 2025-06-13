//
//  StorageService.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import Foundation

// MARK: - Storage Service Protocol
protocol StorageServiceProtocol {
    func saveUserProfile(_ profile: UserProfile)
    func loadUserProfile() -> UserProfile
    func saveCartItems(_ items: [CartItem])
    func loadCartItems() -> [CartItem]
    func clearCart()
    func saveMenuHistory(_ result: MenuProcessResult)
    func loadMenuHistory() -> [MenuProcessResult]
}

// MARK: - Storage Service Implementation
class StorageService: StorageServiceProtocol, @unchecked Sendable {
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
        var history = loadMenuHistory()
        history.insert(result, at: 0) // Add to beginning
        
        // Keep only last 50 items
        if history.count > 50 {
            history = Array(history.prefix(50))
        }
        
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
} 