//
//  NetworkService.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import Foundation
import SwiftUI



// MARK: - Network Service Protocol
protocol NetworkServiceProtocol {
    func processMenu(imageData: Data, targetLanguage: String) async throws -> MenuProcessResult
}

// MARK: - Network Service Implementation
class NetworkService: NetworkServiceProtocol, @unchecked Sendable {
    static let shared = NetworkService()
    
    private let baseURL = "https://api.menureader.com" // Mock URL for now
    private let session = URLSession.shared
    private let useMockData = true // 设置为true使用mock数据
    
    private init() {}
    
    func processMenu(imageData: Data, targetLanguage: String) async throws -> MenuProcessResult {
        // 目前使用mock数据进行开发
        if useMockData {
            return try await mockProcessMenu(targetLanguage: targetLanguage)
        }
        
        // 真实API调用的实现（后续实现）
        return try await realProcessMenu(imageData: imageData, targetLanguage: targetLanguage)
    }
    
    // MARK: - Mock Implementation
    private func mockProcessMenu(targetLanguage: String) async throws -> MenuProcessResult {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
        
        // Mock菜单数据
        let mockItems = [
            MenuItemAnalysis(
                originalName: "麻婆豆腐",
                translatedName: "Mapo Tofu",
                confidence: 0.95,
                category: "主菜"
            ),
            MenuItemAnalysis(
                originalName: "宫保鸡丁",
                translatedName: "Kung Pao Chicken",
                confidence: 0.95,
                category: "主菜"
            ),
            MenuItemAnalysis(
                originalName: "蛋炒饭",
                translatedName: "Fried Rice with Egg",
                confidence: 0.95,
                category: "主食"
            ),
            MenuItemAnalysis(
                originalName: "酸辣汤",
                translatedName: "Hot and Sour Soup",
                confidence: 0.95,
                category: "汤类"
            )
        ]
        
        return MenuProcessResult(items: mockItems)
    }
    
    // MARK: - Real API Implementation (To be implemented)
    private func realProcessMenu(imageData: Data, targetLanguage: String) async throws -> MenuProcessResult {
        guard let url = URL(string: "\(baseURL)/process-menu") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // TODO: 实现真实的API调用
        // 1. 将图片转换为base64或multipart/form-data
        // 2. 构建请求体
        // 3. 发送请求并处理响应
        
        throw NetworkError.unknown(NSError(domain: "NetworkService", code: -1, userInfo: [NSLocalizedDescriptionKey: "API调用尚未实现"]))
    }
} 