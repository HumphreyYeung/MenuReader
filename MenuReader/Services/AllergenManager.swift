//
//  AllergenManager.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import Foundation

// MARK: - Allergen Manager Protocol
protocol AllergenManagerProtocol {
    func addAllergen(_ allergen: String)
    func removeAllergen(_ allergen: String)
    func getAllergens() -> [String]
    func hasAllergen(_ allergen: String) -> Bool
    func addCustomAllergen(_ allergen: String) -> Bool
    func getCustomAllergens() -> [String]
    func validateAllergenName(_ name: String) -> ValidationResult
}

// MARK: - Validation Result
enum ValidationResult {
    case valid
    case empty
    case tooLong
    case alreadyExists
    case invalid
    
    var errorMessage: String {
        switch self {
        case .valid:
            return ""
        case .empty:
            return "过敏原名称不能为空"
        case .tooLong:
            return "过敏原名称过长（最多20个字符）"
        case .alreadyExists:
            return "该过敏原已存在"
        case .invalid:
            return "过敏原名称包含无效字符"
        }
    }
}

// MARK: - Allergen Manager Implementation
class AllergenManager: AllergenManagerProtocol, @unchecked Sendable {
    static let shared = AllergenManager()
    
    private let storageService: StorageServiceProtocol
    private let maxAllergenNameLength = 20
    
    init(storageService: StorageServiceProtocol = StorageService.shared) {
        self.storageService = storageService
    }
    
    // MARK: - Core Allergen Management
    func addAllergen(_ allergen: String) {
        var profile = storageService.loadUserProfile()
        if !profile.allergens.contains(allergen) {
            profile.allergens.append(allergen)
            storageService.saveUserProfile(profile)
        }
    }
    
    func removeAllergen(_ allergen: String) {
        var profile = storageService.loadUserProfile()
        profile.allergens.removeAll { $0 == allergen }
        storageService.saveUserProfile(profile)
    }
    
    func getAllergens() -> [String] {
        return storageService.loadUserProfile().allergens
    }
    
    func hasAllergen(_ allergen: String) -> Bool {
        return getAllergens().contains(allergen)
    }
    
    // MARK: - Custom Allergen Management
    func addCustomAllergen(_ allergen: String) -> Bool {
        let validation = validateAllergenName(allergen)
        guard validation == .valid else {
            return false
        }
        
        let normalizedAllergen = allergen.trimmingCharacters(in: .whitespacesAndNewlines)
        addAllergen(normalizedAllergen)
        return true
    }
    
    func getCustomAllergens() -> [String] {
        let allAllergens = getAllergens()
        let commonAllergenValues = CommonAllergen.allCases.map { $0.rawValue }
        return allAllergens.filter { !commonAllergenValues.contains($0) }
    }
    
    // MARK: - Validation
    func validateAllergenName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if empty
        if trimmedName.isEmpty {
            return .empty
        }
        
        // Check length
        if trimmedName.count > maxAllergenNameLength {
            return .tooLong
        }
        
        // Check if already exists
        if hasAllergen(trimmedName) {
            return .alreadyExists
        }
        
        // Check for invalid characters (only allow letters, numbers, spaces, hyphens)
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet.whitespaces).union(CharacterSet(charactersIn: "-"))
        if trimmedName.unicodeScalars.contains(where: { !allowedCharacters.contains($0) }) {
            return .invalid
        }
        
        return .valid
    }
    
    // MARK: - Helper Methods
    func getAllCommonAllergens() -> [CommonAllergen] {
        return CommonAllergen.allCases
    }
    
    func isCommonAllergen(_ allergen: String) -> Bool {
        return CommonAllergen.allCases.contains { $0.rawValue == allergen }
    }
} 