//
//  NetworkService.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//  整合了APIClient的网络层功能

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

// MARK: - API Endpoint
struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]?
    let queryParameters: [String: String]?
    let url: URL?
    let body: Data?
    
    init(path: String, method: HTTPMethod = .GET, headers: [String: String]? = nil, queryParameters: [String: String]? = nil, url: URL? = nil, body: Data? = nil) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryParameters = queryParameters
        self.url = url
        self.body = body
    }
    
    enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
    }
}

// MARK: - API Error
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case rateLimitExceeded
    case serverError
    case networkError(Error)
    case unknownError(Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .invalidResponse:
            return "无效的响应"
        case .unauthorized:
            return "未授权访问"
        case .forbidden:
            return "访问被禁止"
        case .notFound:
            return "资源未找到"
        case .rateLimitExceeded:
            return "请求频率过高，请稍后重试"
        case .serverError:
            return "服务器错误"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .unknownError(let code):
            return "未知错误，状态码: \(code)"
        case .decodingError(let error):
            return "数据解析错误: \(error.localizedDescription)"
        }
    }
}

// MARK: - Network Service (整合后的主要服务)
class NetworkService: ObservableObject, @unchecked Sendable {
    static let shared = NetworkService()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // Configuration
    private let timeout: TimeInterval = 30.0
    private let maxRetries = 3
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        
        // 配置日期格式
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Generic Request Method
    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type,
        retryCount: Int = 0
    ) async throws -> T {
        
        // 构建URL请求
        guard let request = try? buildRequest(from: endpoint) else {
            throw APIError.invalidURL
        }
        
        // 调试日志（总是开启以便调试图片服务）
        print("🌐 API Request: \(request.url?.absoluteString ?? "unknown")")
        print("📋 Request Headers:")
        for (key, value) in request.allHTTPHeaderFields ?? [:] {
            print("  \(key): \(value)")
        }
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("📦 Request Body: \(bodyString)")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // 检查HTTP状态码
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // 调试响应（总是开启以便调试图片服务）
            print("📡 Response Status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                // 对于长响应，只显示前500个字符
                let truncatedResponse = responseString.prefix(500)
                print("📥 Response Data (前500字符): \(truncatedResponse)")
                if responseString.count > 500 {
                    print("📄 响应数据已截断，总长度: \(responseString.count) 字符")
                }
            }
            
            // 处理不同的状态码
            switch httpResponse.statusCode {
            case 200...299:
                // 成功响应，解析数据
                let result = try decoder.decode(T.self, from: data)
                return result
                
            case 429:
                // 速率限制，重试
                if retryCount < maxRetries {
                    let delay = pow(2.0, Double(retryCount)) // 指数退避
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await self.request(endpoint, responseType: responseType, retryCount: retryCount + 1)
                } else {
                    throw APIError.rateLimitExceeded
                }
                
            case 401:
                throw APIError.unauthorized
            case 403:
                throw APIError.forbidden
            case 404:
                throw APIError.notFound
            case 500...599:
                throw APIError.serverError
            default:
                throw APIError.unknownError(httpResponse.statusCode)
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            // 网络错误重试
            if retryCount < maxRetries && !Task.isCancelled {
                let delay = pow(2.0, Double(retryCount))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await self.request(endpoint, responseType: responseType, retryCount: retryCount + 1)
            } else {
                throw APIError.networkError(error)
            }
        }
    }
    
    // MARK: - Request Builder
    private func buildRequest(from endpoint: APIEndpoint) throws -> URLRequest {
        guard let url = endpoint.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // 设置headers
        if let headers = endpoint.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // 设置请求体
        if let body = endpoint.body {
            request.httpBody = body
        }
        
        return request
    }
}

// MARK: - Generic Endpoint Builders
extension NetworkService {
    /// 创建Gemini API endpoint
    func createGeminiEndpoint<T: Codable>(request: T) -> APIEndpoint {
        let apiKey = EnvironmentLoader.shared.geminiAPIKey ?? ""
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)")
        
        let encoder = JSONEncoder()
        let body = try? encoder.encode(request)
        
        // 添加Bundle ID到请求头，用于API访问限制
        let headers = [
            "Content-Type": "application/json",
            "X-Ios-Bundle-Identifier": "io.github.HumphreyYeung.MenuReader"
        ]
        
        return APIEndpoint(
            path: "/v1beta/models/gemini-1.5-flash:generateContent",
            method: .POST,
            headers: headers,
            queryParameters: nil,
            url: url,
            body: body
        )
    }
}

// MARK: - Google Search Endpoint
struct GoogleSearchEndpoint {
    static func searchImages(query: String, num: Int = 10) -> APIEndpoint {
        let apiKey = EnvironmentLoader.shared.googleSearchAPIKey ?? ""
        let searchEngineId = EnvironmentLoader.shared.googleSearchEngineID ?? ""
        
        let queryParams = [
            "key": apiKey,
            "cx": searchEngineId,
            "q": query,
            "searchType": "image",
            "num": "\(num)",
            "safe": "active"
        ]
        
        var components = URLComponents(string: "https://www.googleapis.com/customsearch/v1")
        components?.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        // 添加Bundle ID到请求头，用于API访问限制
        let headers = [
            "X-Ios-Bundle-Identifier": "io.github.HumphreyYeung.MenuReader"
        ]
        
        return APIEndpoint(
            path: "/customsearch/v1",
            method: .GET,
            headers: headers,
            queryParameters: queryParams,
            url: components?.url,
            body: nil
        )
    }
}

// MARK: - 向后兼容的类型别名
typealias APIClient = NetworkService 