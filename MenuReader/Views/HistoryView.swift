//
//  HistoryView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var storageService = StorageService.shared
    @State private var historyItems: [MenuProcessResult] = []
    @State private var searchText = ""
    @State private var showingFavoritesOnly = false
    @State private var currentPage = 0
    @State private var isLoading = false
    
    private let pageSize = 20
    
    var filteredItems: [MenuProcessResult] {
        let items = showingFavoritesOnly ? historyItems.filter { $0.isFavorite } : historyItems
        
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { result in
                result.items.contains { item in
                    item.originalName.localizedCaseInsensitiveContains(searchText) ||
                    (item.translatedName?.localizedCaseInsensitiveContains(searchText) ?? false)
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar and filter
                VStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("搜索菜品...", text: $searchText)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    HStack {
                        Toggle("只显示收藏", isOn: $showingFavoritesOnly)
                            .toggleStyle(SwitchToggleStyle())
                        Spacer()
                        Text("共 \(filteredItems.count) 条记录")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))
                .shadow(radius: 1)
                
                // History list
                if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            HistoryItemRow(
                                item: item,
                                onToggleFavorite: { toggleFavorite(item.id) },
                                onDelete: { deleteItem(item.id) }
                            )
                            .listRowInsets(EdgeInsets())
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("扫描历史")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadHistory()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            
            Image(systemName: searchText.isEmpty && !showingFavoritesOnly ? "clock.circle" : "magnifyingglass.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(searchText.isEmpty && !showingFavoritesOnly ? "暂无扫描历史" : "未找到相关记录")
                .font(.title3)
                .foregroundColor(.secondary)
                .padding(.top)
            
            if searchText.isEmpty && !showingFavoritesOnly {
                Text("扫描菜单后会显示在这里")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            Spacer()
        }
    }
    
    private func loadHistory() {
        historyItems = storageService.loadMenuHistory()
    }
    
    private func toggleFavorite(_ id: UUID) {
        storageService.toggleFavoriteHistoryItem(withId: id)
        loadHistory()
    }
    
    private func deleteItem(_ id: UUID) {
        storageService.deleteMenuHistoryItem(withId: id)
        loadHistory()
    }
}

// MARK: - History Item Row
struct HistoryItemRow: View {
    let item: MenuProcessResult
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void
    
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
        NavigationLink(destination: HistoryDetailView(item: item)) {
            HStack(spacing: 12) {
                // Thumbnail
                thumbnailImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedDate)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(item.items.count) 个菜品")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let firstItem = item.items.first {
                        Text(firstItem.translatedName ?? firstItem.originalName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Actions
                VStack {
                    Button(action: onToggleFavorite) {
                        Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(item.isFavorite ? .red : .gray)
                            .font(.title3)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.title3)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - History Detail View
struct HistoryDetailView: View {
    let item: MenuProcessResult
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: item.scanDate)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header info
                VStack(alignment: .leading, spacing: 8) {
                    Text("扫描时间")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedDate)
                        .font(.body)
                    
                    if item.isFavorite {
                        Label("已收藏", systemImage: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Menu items
                VStack(alignment: .leading, spacing: 12) {
                    Text("菜品列表 (\(item.items.count))")
                        .font(.headline)
                    
                    ForEach(item.items) { menuItem in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(menuItem.translatedName ?? menuItem.originalName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    if menuItem.translatedName != nil {
                                        Text(menuItem.originalName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if let price = menuItem.price {
                                        Text(price)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                Spacer()
                                
                                if menuItem.hasUserAllergens {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            
                            if let description = menuItem.description {
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 1)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("历史详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HistoryView()
} 