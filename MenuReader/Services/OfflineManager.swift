//
//  OfflineManager.swift
//  MenuReader
//
//  Created by MenuReader on 2025-01-16.
//

import Foundation
import Combine
import UIKit

/// 离线模式管理服务
@MainActor
class OfflineManager: ObservableObject {
    static let shared = OfflineManager()
    
    @Published var isOfflineMode: Bool = false
    @Published var pendingUploadsCount: Int = 0
    @Published var isProcessingQueue: Bool = false
    
    private let networkMonitor = NetworkMonitor.shared
    private let storageService = StorageService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNetworkMonitoring()
        setupNotificationObservers()
        updatePendingUploadsCount()
    }
    
    // MARK: - Setup
    
    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isOfflineMode = !isConnected
                if isConnected {
                    self?.processQueueWhenOnline()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .networkDidReconnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleNetworkReconnection()
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 保存菜单结果（根据网络状态决定是否加入队列）
    func saveMenuResult(_ result: MenuProcessResult) {
        print("💾 [OfflineManager] 正在离线保存菜单结果...")
        storageService.saveMenuHistory(result)
        
        // 如果离线，添加到待上传队列
        if isOfflineMode {
            storageService.addToPendingUploadQueue(result)
            updatePendingUploadsCount()
            print("📱 [OfflineManager] 离线模式：已加入待上传队列")
        } else {
            // 在线时可以直接处理
            print("🌐 [OfflineManager] 在线模式：数据已保存")
        }
    }
    
    /// 获取离线模式状态描述
    var offlineStatusDescription: String {
        if isOfflineMode {
            if pendingUploadsCount > 0 {
                return "离线模式 • \(pendingUploadsCount) 项待上传"
            } else {
                return "离线模式"
            }
        } else {
            return networkMonitor.connectionType.displayName
        }
    }
    
    /// 手动处理待上传队列
    func processQueue() {
        guard !isOfflineMode && !isProcessingQueue else {
            print("⚠️ [OfflineManager] 无法处理队列：离线或正在处理中")
            return
        }
        
        processQueueWhenOnline()
    }
    
    /// 清空待上传队列
    func clearQueue() {
        storageService.clearPendingUploadQueue()
        updatePendingUploadsCount()
    }
    
    // MARK: - Private Methods
    
    private func handleNetworkReconnection() {
        print("🔄 [OfflineManager] 网络重新连接，开始处理待上传队列")
        processQueueWhenOnline()
    }
    
    private func processQueueWhenOnline() {
        guard !isOfflineMode && !isProcessingQueue else { return }
        
        let queue = storageService.getPendingUploadQueue()
        guard !queue.isEmpty else { return }
        
        isProcessingQueue = true
        
        Task {
            print("📤 [OfflineManager] 开始处理 \(queue.count) 项待上传数据")
            
            for item in queue {
                // 这里可以添加实际的上传逻辑
                // 目前只是模拟处理
                await simulateUpload(item)
                
                // 上传成功后从队列中移除
                storageService.removePendingUploadItem(withId: item.id)
            }
            
            await MainActor.run {
                isProcessingQueue = false
                updatePendingUploadsCount()
                print("✅ [OfflineManager] 队列处理完成")
            }
        }
    }
    
    private func simulateUpload(_ item: MenuProcessResult) async {
        // 模拟上传延迟
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        print("📤 [OfflineManager] 模拟上传: \(item.id)")
    }
    
    private func updatePendingUploadsCount() {
        pendingUploadsCount = storageService.getPendingUploadQueue().count
    }
} 