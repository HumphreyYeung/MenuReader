//
//  StorageManagementView.swift
//  MenuReader
//
//  Created by MenuReader on 2025-01-16.
//

import SwiftUI

struct StorageManagementView: View {
    @StateObject private var storageService = StorageService.shared
    @StateObject private var offlineManager = OfflineManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStorageSize: Int64 = 0
    @State private var maxStorageLimit: Int64 = 0
    @State private var cleanupDays: Int = 30
    @State private var showingCleanupConfirmation = false
    @State private var showingLimitAlert = false
    @State private var newLimitMB: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - 网络状态
                Section("网络状态") {
                    HStack {
                        Image(systemName: offlineManager.isOfflineMode ? "wifi.slash" : "wifi")
                            .foregroundColor(offlineManager.isOfflineMode ? .red : .green)
                        
                        VStack(alignment: .leading) {
                            Text(offlineManager.offlineStatusDescription)
                                .font(.headline)
                            
                            if offlineManager.isOfflineMode {
                                Text("离线模式下扫描的数据将保存在本地，网络恢复后可选择同步")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if offlineManager.isProcessingQueue {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    if offlineManager.pendingUploadsCount > 0 {
                        HStack {
                            Text("待上传数据")
                            Spacer()
                            Text("\(offlineManager.pendingUploadsCount) 项")
                                .foregroundColor(.secondary)
                        }
                        
                        if !offlineManager.isOfflineMode {
                            Button("立即同步") {
                                offlineManager.processQueue()
                            }
                            .disabled(offlineManager.isProcessingQueue)
                        }
                        
                        Button("清空队列", role: .destructive) {
                            offlineManager.clearQueue()
                        }
                    }
                }
                
                // MARK: - 存储信息
                Section("存储使用情况") {
                    HStack {
                        Text("当前使用")
                        Spacer()
                        Text(formatBytes(currentStorageSize))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("存储限制")
                        Spacer()
                        Text(formatBytes(maxStorageLimit))
                            .foregroundColor(.secondary)
                    }
                    
                    // 存储使用进度条
                    let usagePercentage = maxStorageLimit > 0 ? Double(currentStorageSize) / Double(maxStorageLimit) : 0
                    VStack(alignment: .leading, spacing: 4) {
                        Text("使用率: \(Int(usagePercentage * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ProgressView(value: usagePercentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: usagePercentage > 0.8 ? .red : .blue))
                    }
                    
                    Button("修改存储限制") {
                        newLimitMB = String(maxStorageLimit / 1024 / 1024)
                        showingLimitAlert = true
                    }
                }
                
                // MARK: - 清理选项
                Section("数据清理") {
                    Stepper("保留最近 \(cleanupDays) 天的数据", value: $cleanupDays, in: 7...90)
                    
                    Button("清理旧数据") {
                        showingCleanupConfirmation = true
                    }
                    .foregroundColor(.orange)
                    
                    Button("清空所有历史数据", role: .destructive) {
                        clearAllData()
                    }
                }
                
                // MARK: - 离线模式说明
                Section("离线模式说明") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("功能说明")
                                .font(.headline)
                        }
                        
                        Text("• 离线模式下可以查看历史扫描记录")
                        Text("• 新扫描的数据会保存到本地")
                        Text("• 网络恢复后可选择同步待上传数据")
                        Text("• 离线模式下无法使用图片搜索等在线功能")
                        
                        Text("存储管理")
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• 应用会自动管理存储空间")
                        Text("• 收藏的记录不会被自动清理")
                        Text("• 达到存储限制时会提示清理旧数据")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("存储管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadStorageInfo()
            }
            .alert("清理确认", isPresented: $showingCleanupConfirmation) {
                Button("取消", role: .cancel) { }
                Button("清理", role: .destructive) {
                    cleanupOldData()
                }
            } message: {
                Text("将删除 \(cleanupDays) 天前的数据（收藏的记录不会被删除）。此操作无法撤销。")
            }
            .alert("设置存储限制", isPresented: $showingLimitAlert) {
                TextField("大小 (MB)", text: $newLimitMB)
                    .keyboardType(.numberPad)
                Button("取消", role: .cancel) { }
                Button("确定") {
                    setNewStorageLimit()
                }
            } message: {
                Text("请输入新的存储限制大小（MB）")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadStorageInfo() {
        currentStorageSize = storageService.getStorageSize()
        maxStorageLimit = storageService.getMaxStorageLimit()
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func cleanupOldData() {
        storageService.cleanupOldData(keepRecentDays: cleanupDays)
        loadStorageInfo()
    }
    
    private func clearAllData() {
        // 清空所有历史数据
        let allHistory = storageService.loadMenuHistory()
        for item in allHistory {
            storageService.deleteMenuHistoryItem(withId: item.id)
        }
        
        // 清空待上传队列
        offlineManager.clearQueue()
        
        loadStorageInfo()
    }
    
    private func setNewStorageLimit() {
        guard let limitMB = Int64(newLimitMB), limitMB > 0 else { return }
        let limitBytes = limitMB * 1024 * 1024
        storageService.setMaxStorageLimit(limitBytes)
        loadStorageInfo()
    }
}

#Preview {
    StorageManagementView()
} 