//
//  DishDisplayComponents.swift
//  MenuReader
//
//  Created by MenuReader on 2025-06-13.
//

import SwiftUI

// MARK: - 统一的菜品显示组件

/// 菜品卡片视图 - 整合了原DishCardView功能
struct DishCardView: View {
    let menuItem: MenuItemAnalysis
    let dishImages: [DishImage]
    let onAddToCart: () -> Void
    let onTapCard: () -> Void
    
    @State private var isExpanded = false
    @State private var selectedImageIndex = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 主要内容区域
            mainContentView
            
            // 展开的详细信息
            if isExpanded {
                expandedContentView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
            onTapCard()
        }
    }
    
    // MARK: - Main Content
    
    private var mainContentView: some View {
        VStack(spacing: 12) {
            // 菜品图片
            DishImageCarouselView(
                dishImages: dishImages,
                selectedIndex: $selectedImageIndex,
                height: 160
            )
            .overlay(alignment: .topTrailing) {
                confidenceBadge
                    .padding(8)
            }
            
            // 菜品信息
            dishInfoView
            
            // 操作按钮
            actionButtonsView
        }
        .padding(16)
    }
    
    private var confidenceBadge: some View {
        Text("\(Int(menuItem.confidence * 100))%")
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundColor(.primary)
    }
    
    private var dishInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 菜品名称
            VStack(alignment: .leading, spacing: 4) {
                Text(menuItem.originalName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let translatedName = menuItem.translatedName {
                    Text(translatedName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            
            // 价格和分类
            HStack {
                if let price = menuItem.price {
                    Text(price)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                if let category = menuItem.category {
                    Text(category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
            
            // 描述
            if let description = menuItem.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(isExpanded ? nil : 2)
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            // 展开/收起按钮
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                    Text(isExpanded ? "收起" : "详情")
                        .font(.caption)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
            
            // 添加到购物车按钮
            Button(action: onAddToCart) {
                HStack(spacing: 6) {
                    Image(systemName: "cart.badge.plus")
                        .font(.caption)
                    Text("加入购物车")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green)
                .cornerRadius(8)
            }
        }
    }
    
    private var expandedContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            
            // 图片网格（如果有多张图片）
            if dishImages.count > 1 {
                DishImageGridView(
                    dishImages: dishImages,
                    columns: 3,
                    imageSize: CGSize(width: 80, height: 80)
                )
            }
            
            // 详细信息
            if let description = menuItem.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("详细描述")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

/// 菜品图片轮播视图
struct DishImageCarouselView: View {
    let dishImages: [DishImage]
    @Binding var selectedIndex: Int
    let height: CGFloat
    
    var body: some View {
        ZStack {
            // 背景占位符
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(height: height)
                .overlay {
                    if dishImages.isEmpty {
                        VStack {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("暂无图片")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            
            // 图片轮播
            if !dishImages.isEmpty {
                TabView(selection: $selectedIndex) {
                    ForEach(Array(dishImages.enumerated()), id: \.offset) { index, dishImage in
                        DishImageView(
                            dishImage: dishImage,
                            size: CGSize(width: .infinity, height: height),
                            cornerRadius: 12
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(height: height)
            }
        }
    }
}

/// 菜品图片显示组件 - 整合了原DishImageView功能
struct DishImageView: View {
    let dishImage: DishImage
    let size: CGSize
    let cornerRadius: CGFloat
    
    @State private var isLoaded = false
    @State private var loadingFailed = false
    
    init(dishImage: DishImage, 
         size: CGSize = CGSize(width: 120, height: 120),
         cornerRadius: CGFloat = 8) {
        self.dishImage = dishImage
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        ZStack {
            // 背景占位符
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.2))
                .frame(width: size.width == .infinity ? nil : size.width, 
                       height: size.height)
            
            if loadingFailed {
                // 错误状态
                errorPlaceholder
            } else {
                // 图片内容
                imageContent
            }
        }
        .frame(width: size.width == .infinity ? nil : size.width, 
               height: size.height)
    }
    
    // MARK: - View Components
    
    private var imageContent: some View {
        AsyncImage(url: URL(string: dishImage.thumbnailURL)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width == .infinity ? nil : size.width, 
                       height: size.height)
                .clipped()
                .cornerRadius(cornerRadius)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoaded = true
                    }
                }
        } placeholder: {
            loadingPlaceholder
        }
        .onAppear {
            loadingFailed = false
        }
    }
    
    private var loadingPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.1))
            
            VStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                
                Text("加载中...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size.width == .infinity ? nil : size.width, 
               height: size.height)
    }
    
    private var errorPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.1))
            
            VStack(spacing: 4) {
                Image(systemName: "photo.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text("加载失败")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size.width == .infinity ? nil : size.width, 
               height: size.height)
    }
}

/// 菜品图片网格视图
struct DishImageGridView: View {
    let dishImages: [DishImage]
    let columns: Int
    let spacing: CGFloat
    let imageSize: CGSize
    
    @State private var selectedImage: DishImage?
    @State private var showImageDetail = false
    
    init(dishImages: [DishImage],
         columns: Int = 3,
         spacing: CGFloat = 8,
         imageSize: CGSize = CGSize(width: 100, height: 100)) {
        self.dishImages = dishImages
        self.columns = columns
        self.spacing = spacing
        self.imageSize = imageSize
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: spacing) {
            ForEach(dishImages) { dishImage in
                DishImageView(
                    dishImage: dishImage,
                    size: imageSize,
                    cornerRadius: 8
                )
                .onTapGesture {
                    selectedImage = dishImage
                    showImageDetail = true
                }
            }
        }
        .sheet(isPresented: $showImageDetail) {
            if let selectedImage = selectedImage {
                DishImageDetailView(dishImage: selectedImage)
            }
        }
    }
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
    }
}

/// 菜品图片详情视图
struct DishImageDetailView: View {
    let dishImage: DishImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 大图显示
                    AsyncImage(url: URL(string: dishImage.imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                            .cornerRadius(12)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 300)
                            .overlay {
                                ProgressView()
                            }
                    }
                    
                    // 图片信息
                    VStack(alignment: .leading, spacing: 12) {
                        Text(dishImage.title)
                            .font(.headline)
                            .lineLimit(3)
                        
                        if let sourceURL = dishImage.sourceURL {
                            Link("查看原图", destination: URL(string: sourceURL)!)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        // 图片尺寸信息
                        if let width = dishImage.width, let height = dishImage.height {
                            Text("尺寸: \(width) × \(height)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("菜品: \(dishImage.menuItemName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("图片详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - CGSize Extension

extension CGSize {
    static let infinity = CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
}

extension CGFloat {
    static let infinity = CGFloat.infinity
} 