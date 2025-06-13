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
    let quantity: Int
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