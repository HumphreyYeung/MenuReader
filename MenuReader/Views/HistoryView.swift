//
//  HistoryView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var storageService = StorageService.shared
    @StateObject private var offlineManager = OfflineManager.shared
    @State private var historyItems: [MenuProcessResult] = []
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    var filteredItems: [MenuProcessResult] {
        if searchText.isEmpty {
            return historyItems
        } else {
            return historyItems.filter { result in
                result.items.contains { item in
                    item.originalName.localizedCaseInsensitiveContains(searchText) ||
                    (item.translatedName?.localizedCaseInsensitiveContains(searchText) ?? false)
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Search bar and filter
            VStack {
                HStack {
                    Image(systemName: AppIcons.search)
                        .foregroundColor(AppColors.secondaryText)
                    TextField("搜索菜品...", text: $searchText)
                        .foregroundColor(AppColors.primary)
                }
                .padding(.horizontal, AppSpacing.m)
                .padding(.vertical, AppSpacing.s)
                .background(AppColors.contentBackground)
                .cornerRadius(AppSpacing.standardCorner)
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.standardCorner)
                        .stroke(AppColors.separator, lineWidth: 1)
                )
                .padding(.horizontal, AppSpacing.screenMargin)
            }
            .padding(.vertical, AppSpacing.m)
            .background(AppColors.background)
            .shadow(color: .black.opacity(0.03), radius: 1, y: 1)
            
            // History list
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(filteredItems) { item in
                        NavigationLink(value: item) {
                            HistoryItemRow(item: item)
                        }
                        .listRowBackground(AppColors.background)
                        .listRowInsets(EdgeInsets(
                            top: 0,
                            leading: AppSpacing.screenMargin,
                            bottom: 0,
                            trailing: AppSpacing.screenMargin
                        ))
                        .listRowSeparatorTint(AppColors.separator)
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(AppColors.background)
            }
        }
        .navigationDestination(for: MenuProcessResult.self) { result in
            CategorizedMenuView(
                analysisResult: MenuAnalysisResult(items: result.items),
                dishImages: result.dishImages ?? [:]
                // 不传递 onDismiss，让它使用 .push 导航模式
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Text("扫描历史")
                        .font(AppFonts.navigationTitle)
                        .foregroundColor(AppColors.primary)
                    Text("(\(filteredItems.count))")
                        .font(AppFonts.navigationTitle)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
        }
        .background(AppColors.background)
        .onAppear {
            loadHistory()
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            
            Image(systemName: searchText.isEmpty ? "clock.circle" : "magnifyingglass.circle")
                .font(.system(size: 60))
                .foregroundColor(AppColors.tertiaryText)
            
            Text(searchText.isEmpty ? "暂无扫描历史" : "未找到相关记录")
                .font(AppFonts.title1)
                .fontWeight(.medium)
                .padding(.top)
            
            if searchText.isEmpty {
                Text("扫描菜单后会显示在这里")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.secondaryText)
                    .padding(.top, 4)
            }
            
            Spacer()
        }
        .background(AppColors.background)
    }
    
    private func loadHistory() {
        historyItems = storageService.loadMenuHistory()
    }
    
    private func deleteItems(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { filteredItems[$0] }
        for item in itemsToDelete {
            storageService.deleteMenuHistoryItem(withId: item.id)
        }
        // Reload data from storage to reflect the change
        loadHistory()
    }
}

// MARK: - History Item Row
struct HistoryItemRow: View {
    let item: MenuProcessResult
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: item.scanDate)
    }
    
    private var thumbnailImage: Image {
        if let thumbnailData = item.thumbnailData,
           let uiImage = UIImage(data: thumbnailData) {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: "photo")
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            thumbnailImage
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.smallCorner))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.smallCorner)
                        .stroke(AppColors.separator, lineWidth: 1)
                )
            
            // Content
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(formattedDate)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.primary)
                
                Text("\(item.items.count) 个菜品")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.secondaryText)
                
                if let firstItem = item.items.first {
                    Text(firstItem.translatedName ?? firstItem.originalName)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.secondaryText)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, AppSpacing.s)
    }
}
