//
//  APIEndpoints.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import Foundation

// MARK: - API Endpoint Protocol
protocol APIEndpoint {
    var url: URL { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: (any Encodable)? { get }
}

// MARK: - Environment Configuration
struct APIConfig {
    private nonisolated(unsafe) static let envLoader = EnvironmentLoader.shared
    
    static let geminiAPIKey = envLoader.getValue(for: "GEMINI_API_KEY") ?? ""
    static let geminiModel = envLoader.getValue(for: "GEMINI_MODEL") ?? "gemini-2.0-flash"
    static let geminiBaseURL = envLoader.getValue(for: "GEMINI_API_URL") ?? "https://generativelanguage.googleapis.com/v1beta/models"
    
    static let googleSearchAPIKey = envLoader.getValue(for: "GOOGLE_SEARCH_API_KEY") ?? ""
    static let googleSearchEngineId = envLoader.getValue(for: "GOOGLE_SEARCH_ENGINE_ID") ?? ""
    static let googleSearchBaseURL = envLoader.getValue(for: "GOOGLE_SEARCH_URL") ?? "https://www.googleapis.com/customsearch/v1"
    
    // 验证配置
    static var isConfigured: Bool {
        return !geminiAPIKey.isEmpty && 
               !googleSearchAPIKey.isEmpty && 
               !googleSearchEngineId.isEmpty
    }
    
    // 打印配置状态
    static func printConfiguration() {
        envLoader.printConfiguration()
        print("📊 配置状态: \(isConfigured ? "✅ 完整" : "❌ 不完整")")
    }
}

// MARK: - Gemini API Endpoints
enum GeminiEndpoint: APIEndpoint {
    case generateContent(request: GeminiRequest)
    
    var url: URL {
        switch self {
        case .generateContent:
            let urlString = "\(APIConfig.geminiBaseURL)/\(APIConfig.geminiModel):generateContent"
            var components = URLComponents(string: urlString)!
            components.queryItems = [
                URLQueryItem(name: "key", value: APIConfig.geminiAPIKey)
            ]
            return components.url!
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .generateContent:
            return .POST
        }
    }
    
    var headers: [String: String] {
        return [
            "Content-Type": "application/json"
        ]
    }
    
    var body: (any Encodable)? {
        switch self {
        case .generateContent(let request):
            return request
        }
    }
}

// MARK: - Google Search Endpoints
enum GoogleSearchEndpoint: APIEndpoint {
    case searchImages(query: String, num: Int = 5)
    
    var url: URL {
        switch self {
        case .searchImages(let query, let num):
            var components = URLComponents(string: APIConfig.googleSearchBaseURL)!
            components.queryItems = [
                URLQueryItem(name: "key", value: APIConfig.googleSearchAPIKey),
                URLQueryItem(name: "cx", value: APIConfig.googleSearchEngineId),
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "searchType", value: "image"),
                URLQueryItem(name: "num", value: String(num)),
                URLQueryItem(name: "safe", value: "active"), // 安全搜索
                URLQueryItem(name: "imgType", value: "photo"), // 只要照片类型
                URLQueryItem(name: "imgSize", value: "medium") // 中等尺寸图片
            ]
            return components.url!
        }
    }
    
    var method: HTTPMethod {
        return .GET
    }
    
    var headers: [String: String] {
        return [:]
    }
    
    var body: (any Encodable)? {
        return nil
    }
} 