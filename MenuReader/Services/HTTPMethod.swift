//
//  HTTPMethod.swift
//  MenuReader
//
//  Created by Assistant on 25/1/2025.
//

import Foundation

// MARK: - HTTP Method Enum
enum HTTPMethod: String, CaseIterable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
    case HEAD = "HEAD"
    case OPTIONS = "OPTIONS"
}

// MARK: - Network Error Types
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case httpError(Int)
    case networkUnavailable
    case timeout
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL地址"
        case .noData:
            return "没有接收到数据"
        case .decodingError(let error):
            return "数据解析失败: \(error.localizedDescription)"
        case .httpError(let statusCode):
            return "HTTP错误: \(statusCode)"
        case .networkUnavailable:
            return "网络不可用"
        case .timeout:
            return "请求超时"
        case .unknown(let error):
            return "未知错误: \(error.localizedDescription)"
        }
    }
}

// MARK: - Request Configuration
struct RequestConfig {
    let timeout: TimeInterval = 30.0
    let retryCount: Int = 3
    let retryDelay: TimeInterval = 1.0
} 