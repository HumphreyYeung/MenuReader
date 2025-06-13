//
//  APIClient.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import Foundation

// MARK: - API Client
class APIClient: ObservableObject, @unchecked Sendable {
    static let shared = APIClient()
    
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
        
        // 调试日志
        if ProcessInfo.processInfo.environment["ENABLE_DEBUG_LOGGING"] == "true" {
            print("🌐 API Request: \(request.url?.absoluteString ?? "unknown")")
            if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
                print("📦 Request Body: \(bodyString)")
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // 检查HTTP状态码
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // 调试响应
            if ProcessInfo.processInfo.environment["ENABLE_DEBUG_LOGGING"] == "true" {
                print("📡 Response Status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 Response Data: \(responseString)")
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
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = endpoint.method.rawValue
        
        // 设置headers
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 设置请求体
        if let body = endpoint.body {
            request.httpBody = try encoder.encode(body)
        }
        
        return request
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

 