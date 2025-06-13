//
//  UserProfile.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import Foundation

// MARK: - User Profile Model
struct UserProfile: Codable {
    var preferredLanguage: String
    var allergens: [String]
    var targetLanguage: String
    
    init(preferredLanguage: String = "en", targetLanguage: String = "en", allergens: [String] = []) {
        self.preferredLanguage = preferredLanguage
        self.targetLanguage = targetLanguage
        self.allergens = allergens
    }
}

// MARK: - Supported Languages
enum SupportedLanguage: String, CaseIterable {
    case english = "en"
    case chinese = "zh"
    case japanese = "ja"
    case korean = "ko"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case spanish = "es"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .spanish: return "Español"
        }
    }
}

// MARK: - Common Allergens
enum CommonAllergen: String, CaseIterable {
    case peanuts = "peanuts"
    case treeNuts = "tree_nuts"
    case milk = "milk"
    case eggs = "eggs"
    case wheat = "wheat"
    case soy = "soy"
    case fish = "fish"
    case shellfish = "shellfish"
    case sesame = "sesame"
    
    var displayName: String {
        switch self {
        case .peanuts: return "花生"
        case .treeNuts: return "坚果"
        case .milk: return "牛奶"
        case .eggs: return "鸡蛋"
        case .wheat: return "小麦"
        case .soy: return "大豆"
        case .fish: return "鱼类"
        case .shellfish: return "贝类"
        case .sesame: return "芝麻"
        }
    }
} 