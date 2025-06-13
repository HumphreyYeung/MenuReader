//
//  EnvironmentLoader.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import Foundation

// MARK: - Environment Loader
class EnvironmentLoader {
    nonisolated(unsafe) static let shared = EnvironmentLoader()
    
    private init() {}
    
    // MARK: - Environment Variable Loading
    func loadEnvironmentVariable(_ key: String) -> String? {
        // First check system environment
        if let value = ProcessInfo.processInfo.environment[key], !value.isEmpty {
            return value
        }
        
        // Check Info.plist
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty {
            return value
        }
        
        return nil
    }
    
    // MARK: - Compatibility Methods
    func getValue(for key: String) -> String? {
        return loadEnvironmentVariable(key)
    }
    
    func printConfiguration() {
        print("Environment Configuration:")
        print("GEMINI_API_KEY: \(geminiAPIKey != nil ? "Set" : "Not Set")")
        print("GOOGLE_SEARCH_API_KEY: \(googleSearchAPIKey != nil ? "Set" : "Not Set")")
        print("GOOGLE_SEARCH_ENGINE_ID: \(googleSearchEngineID != nil ? "Set" : "Not Set")")
    }
    
    // MARK: - Convenience Methods
    var geminiAPIKey: String? {
        return loadEnvironmentVariable("GEMINI_API_KEY")
    }
    
    var googleSearchAPIKey: String? {
        return loadEnvironmentVariable("GOOGLE_SEARCH_API_KEY")
    }
    
    var googleSearchEngineID: String? {
        return loadEnvironmentVariable("GOOGLE_SEARCH_ENGINE_ID")
    }
} 