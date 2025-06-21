//
//  UserProfile.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import Foundation

// MARK: - User Profile Model
struct UserProfile: Codable {
    var targetLanguage: String
    var allergens: [String]
    
    init(targetLanguage: String? = nil, allergens: [String] = []) {
        // 默认跟随系统语言设置
        self.targetLanguage = targetLanguage ?? Self.getSystemLanguage()
        self.allergens = allergens
    }
    
    // 获取系统语言并映射到支持的语言
    private static func getSystemLanguage() -> String {
        let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        
        // 映射系统语言到支持的语言
        switch systemLanguage {
        case "zh": return SupportedLanguage.chinese.rawValue
        case "ja": return SupportedLanguage.japanese.rawValue
        case "ko": return SupportedLanguage.korean.rawValue
        case "fr": return SupportedLanguage.french.rawValue
        case "de": return SupportedLanguage.german.rawValue
        case "it": return SupportedLanguage.italian.rawValue
        case "es": return SupportedLanguage.spanish.rawValue
        default: return SupportedLanguage.english.rawValue
        }
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
    
    // 获取语言的ISO代码用于OCR识别比较
    var isoCode: String {
        switch self {
        case .english: return "en"
        case .chinese: return "zh"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .french: return "fr"
        case .german: return "de"
        case .italian: return "it"
        case .spanish: return "es"
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
