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
        case "pt": return SupportedLanguage.portuguese.rawValue
        default: return SupportedLanguage.english.rawValue
        }
    }
}

// MARK: - Supported Languages
enum SupportedLanguage: String, CaseIterable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case italian = "it"
    case japanese = "ja"
    case german = "de"
    case portuguese = "pt"
    case chinese = "zh"
    case korean = "ko"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .italian: return "Italiano"
        case .japanese: return "日本語"
        case .german: return "Deutsch"
        case .portuguese: return "Português"
        case .chinese: return "中文"
        case .korean: return "한국어"
        }
    }
    
    // 获取语言的ISO代码用于OCR识别比较
    var isoCode: String {
        switch self {
        case .english: return "en"
        case .spanish: return "es"
        case .french: return "fr"
        case .italian: return "it"
        case .japanese: return "ja"
        case .german: return "de"
        case .portuguese: return "pt"
        case .chinese: return "zh"
        case .korean: return "ko"
        }
    }
}

// MARK: - Common Allergens
enum CommonAllergen: String, CaseIterable {
    case peanuts = "peanuts"
    case treeNuts = "tree_nuts"
    case eggs = "eggs"
    case milk = "milk"
    case wheat = "wheat"
    case soy = "soy"
    case fish = "fish"
    case shellfish = "shellfish"
    case sesame = "sesame"
    case pork = "pork"
    
    var displayName: String {
        switch self {
        case .peanuts: return "Peanut"
        case .treeNuts: return "Tree nuts"
        case .eggs: return "Egg"
        case .milk: return "Dairy"
        case .wheat: return "Gluten"
        case .soy: return "Soybean"
        case .fish: return "Fish"
        case .shellfish: return "Shellfish"
        case .sesame: return "Sesame"
        case .pork: return "Pork"
        }
    }
}

// MARK: - Profile View Model
class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile
    @Published var customAllergens: [String] = []
    @Published var customAllergenInput: String = ""
    @Published var validationError: String = ""
    
    init() {
        // 从UserDefaults加载用户配置
        if let data = UserDefaults.standard.data(forKey: "UserProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.userProfile = profile
        } else {
            self.userProfile = UserProfile()
        }
        
        // 分离常见过敏原和自定义过敏原
        let commonAllergenValues = CommonAllergen.allCases.map { $0.rawValue }
        self.customAllergens = userProfile.allergens.filter { !commonAllergenValues.contains($0) }
    }
    
    func hasAllergen(_ allergen: String) -> Bool {
        return userProfile.allergens.contains(allergen)
    }
    
    func toggleCommonAllergen(_ allergen: CommonAllergen) {
        if hasAllergen(allergen.rawValue) {
            userProfile.allergens.removeAll { $0 == allergen.rawValue }
        } else {
            userProfile.allergens.append(allergen.rawValue)
        }
        saveProfile()
    }
    
    func addCustomAllergenFromInput() {
        let allergen = customAllergenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if allergen.isEmpty {
            validationError = "请输入过敏原名称"
            return
        }
        
        if userProfile.allergens.contains(allergen) {
            validationError = "该过敏原已存在"
            return
        }
        
        userProfile.allergens.append(allergen)
        customAllergens.append(allergen)
        customAllergenInput = ""
        validationError = ""
        saveProfile()
    }
    
    func removeCustomAllergen(_ allergen: String) {
        removeAllergen(allergen)
    }
    
    func removeAllergen(_ allergen: String) {
        userProfile.allergens.removeAll { $0 == allergen }
        customAllergens.removeAll { $0 == allergen }
        saveProfile()
    }
    
    func saveProfile() {
        if let data = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(data, forKey: "UserProfile")
        }
    }
    
    func updateTargetLanguage(_ language: String) {
        userProfile.targetLanguage = language
        saveProfile()
    }
}
