//
//  MenuItem.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import Foundation

// MARK: - MenuItem Model
struct MenuItem: Identifiable, Codable {
    let id = UUID()
    let originalName: String
    let translatedName: String?
    let imageURL: String?
    let category: String?
    let description: String?
    let price: String?
    let confidence: Double
    let hasAllergens: Bool
    let allergenTypes: [String]
    let imageResults: [String] // URLs of related images
    
    enum CodingKeys: String, CodingKey {
        case originalName, translatedName, imageURL, category, description, price, confidence, hasAllergens, allergenTypes, imageResults
    }
    
    init(originalName: String, 
         translatedName: String? = nil, 
         imageURL: String? = nil, 
         category: String? = nil,
         description: String? = nil,
         price: String? = nil,
         confidence: Double = 0.0,
         hasAllergens: Bool = false, 
         allergenTypes: [String] = [],
         imageResults: [String] = []) {
        self.originalName = originalName
        self.translatedName = translatedName
        self.imageURL = imageURL
        self.category = category
        self.description = description
        self.price = price
        self.confidence = confidence
        self.hasAllergens = hasAllergens
        self.allergenTypes = allergenTypes
        self.imageResults = imageResults
    }
}



// MARK: - Cart Item
struct CartItem: Identifiable, Codable {
    let id = UUID()
    let menuItem: MenuItem
    var quantity: Int  // 改为var使其可以修改
    let addedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case menuItem, quantity, addedAt
    }
    
    init(menuItem: MenuItem, quantity: Int = 1) {
        self.menuItem = menuItem
        self.quantity = quantity
        self.addedAt = Date()
    }
}

// MARK: - Cart Manager

@MainActor
class CartManager: ObservableObject {
    @Published var cartItems: [CartItem] = []
    
    static let shared = CartManager()
    
    private init() {}
    
    var totalQuantity: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }
    
    var totalPrice: String {
        let total = cartItems.compactMap { item in
            // 简单的价格解析（假设格式为 ¥XX 或 $XX）
            let priceString = item.menuItem.price ?? "¥0"
            let numberString = priceString.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            let price = Double(numberString) ?? 0.0
            return price * Double(item.quantity)  // 乘以数量
        }.reduce(0.0) { $0 + $1 }
        
        return "¥\(String(format: "%.0f", total))"
    }
    
    func addItem(_ menuItem: MenuItem) {
        if let existingIndex = cartItems.firstIndex(where: { $0.menuItem.originalName == menuItem.originalName }) {
            cartItems[existingIndex].quantity += 1
        } else {
            let newItem = CartItem(menuItem: menuItem, quantity: 1)
            cartItems.append(newItem)
        }
    }
    
    func removeItem(at index: Int) {
        if index < cartItems.count {
            cartItems.remove(at: index)
        }
    }
    
    func updateQuantity(at index: Int, to newQuantity: Int) {
        if index < cartItems.count {
            if newQuantity <= 0 {
                cartItems.remove(at: index)
            } else {
                cartItems[index].quantity = newQuantity
            }
        }
    }
    
    func clearAll() {
        cartItems.removeAll()
    }
} 