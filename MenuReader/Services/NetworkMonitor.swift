//
//  NetworkMonitor.swift
//  MenuReader
//
//  Created by MenuReader on 2025-01-16.
//

import Foundation
import Network
import Combine

/// 网络连接监控服务
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
        case none
        
        var displayName: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "蜂窝网络"
            case .ethernet: return "以太网"
            case .unknown: return "未知网络"
            case .none: return "无网络"
            }
        }
    }
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateNetworkStatus(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    // MARK: - Private Methods
    
    private func updateNetworkStatus(_ path: NWPath) {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied
        
        // 确定连接类型
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else if isConnected {
            connectionType = .unknown
        } else {
            connectionType = .none
        }
        
        // 网络状态变化时的处理
        if wasConnected != isConnected {
            handleNetworkStateChange(from: wasConnected, to: isConnected)
        }
        
        print("🌐 [NetworkMonitor] 网络状态: \(isConnected ? "已连接" : "已断开") - \(connectionType.displayName)")
    }
    
    private func handleNetworkStateChange(from wasConnected: Bool, to isConnected: Bool) {
        if !wasConnected && isConnected {
            // 网络恢复，通知相关服务
            print("✅ [NetworkMonitor] 网络已恢复")
            NotificationCenter.default.post(name: .networkDidReconnect, object: nil)
        } else if wasConnected && !isConnected {
            // 网络断开
            print("❌ [NetworkMonitor] 网络已断开")
            NotificationCenter.default.post(name: .networkDidDisconnect, object: nil)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let networkDidReconnect = Notification.Name("networkDidReconnect")
    static let networkDidDisconnect = Notification.Name("networkDidDisconnect")
} 