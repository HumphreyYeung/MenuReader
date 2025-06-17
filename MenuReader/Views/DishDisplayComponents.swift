//
//  DishDisplayComponents.swift
//  MenuReader
//
//  Created by MenuReader on 2025-06-13.
//

import SwiftUI

// MARK: - 图片加载错误类型
enum ImageLoadError: Equatable {
    case networkError
    case serviceCallFailed
    case serviceNotCalled
    case urlInvalid
    case unknownError(String)
    
    var displayText: String {
        switch self {
        case .networkError:
            return "网络错误"
        case .serviceCallFailed:
            return "加载失败"
        case .serviceNotCalled:
            return "暂无图片"
        case .urlInvalid:
            return "图片无效"
        case .unknownError:
            return "加载失败"
        }
    }
    
    var iconName: String {
        switch self {
        case .networkError:
            return "wifi.exclamationmark"
        case .serviceCallFailed:
            return "exclamationmark.triangle"
        case .serviceNotCalled:
            return "photo"
        case .urlInvalid:
            return "link.badge.plus"
        case .unknownError:
            return "questionmark.circle"
        }
    }
}

// MARK: - 统一菜品卡片组件
struct UnifiedDishCard: View {
    let menuItem: MenuItemAnalysis
    let dishImages: [DishImage]
    let showCartButton: Bool
    let onAddToCart: (() -> Void)?
    let onTapCard: (() -> Void)?
    
    @State private var isExpanded = false
    @State private var selectedImageIndex = 0
    
    init(menuItem: MenuItemAnalysis, 
         dishImages: [DishImage], 
         showCartButton: Bool = false,
         onAddToCart: (() -> Void)? = nil,
         onTapCard: (() -> Void)? = nil) {
        self.menuItem = menuItem
        self.dishImages = dishImages
        self.showCartButton = showCartButton
        self.onAddToCart = onAddToCart
        self.onTapCard = onTapCard
    }
    
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
            handleCardTap()
        }
    }
    
    // MARK: - Main Content
    
    private var mainContentView: some View {
        HStack(spacing: 16) {
            // 正方形图片区域
            DishSquareImageView(
                dishImages: dishImages,
                menuItem: menuItem
            )
            
            // 菜品信息区域
            VStack(alignment: .leading, spacing: 8) {
                dishInfoView
                
                // 操作按钮区域（只在需要购物车按钮时显示）
                if showCartButton {
                    actionButtonsView
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
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
            
            // 价格区域
            HStack {
                if let price = menuItem.price {
                    Text(price)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
            
            // 描述
            if let description = menuItem.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(isExpanded ? nil : 2)
                    .multilineTextAlignment(.leading)
            }
            
            // 置信度显示
            HStack {
                Text("识别准确度: \(Int(menuItem.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Action Buttons
    
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
            Button(action: {
                onAddToCart?()
            }) {
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
            
            // 图片展示区域
            if !dishImages.isEmpty {
                imageExpandedSection
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
    
    private var imageExpandedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("参考图片 (\(dishImages.count)张)")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if dishImages.count == 1 {
                // 单张图片大图显示
                AsyncImage(url: URL(string: dishImages[0].imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                } placeholder: {
                    ProgressView()
                        .frame(height: 200)
                }
            } else {
                // 多张图片横向滚动
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(dishImages.enumerated()), id: \.offset) { index, dishImage in
                            AsyncImage(url: URL(string: dishImage.thumbnailURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 80, height: 80)
                            }
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(8)
                            .onTapGesture {
                                selectedImageIndex = index
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedImageIndex == index ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleCardTap() {
        onTapCard?()
    }
}

// MARK: - 正方形菜品图片视图组件
struct DishSquareImageView: View {
    let dishImages: [DishImage]
    let menuItem: MenuItemAnalysis
    let size: CGFloat = 80 // 正方形边长
    
    @StateObject private var googleSearchService = GoogleSearchService.shared
    @State private var currentImageIndex = 0
    @State private var imageError: ImageLoadError?
    
    var body: some View {
        ZStack {
            // 背景正方形
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .frame(width: size, height: size)
            
            // 内容区域
            contentView
        }
        .frame(width: size, height: size)
        .onAppear {
            checkImageStatus()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        let loadingState = googleSearchService.getLoadingState(for: menuItem)
        
        switch loadingState {
        case .idle:
            idleStateView
            
        case .loading:
            loadingStateView
            
        case .loaded(let images):
            if images.isEmpty {
                errorStateView(error: .serviceCallFailed)
            } else {
                successStateView(images: images)
            }
            
        case .failed(let error):
            errorStateView(error: parseError(error))
        }
    }
    
    // MARK: - State Views
    
    private var idleStateView: some View {
        VStack(spacing: 6) {
            Image(systemName: "photo")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("暂无图片")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(8)
    }
    
    private var loadingStateView: some View {
        VStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("加载中")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func successStateView(images: [DishImage]) -> some View {
        ZStack {
            if !images.isEmpty {
                // 显示图片轮播
                TabView(selection: $currentImageIndex) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                        AsyncImage(url: URL(string: image.thumbnailURL)) { imagePhase in
                            switch imagePhase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: size, height: size)
                                    .clipped()
                                    .cornerRadius(12)
                                    .tag(index)
                                
                            case .failure(_):
                                errorStateView(error: .urlInvalid)
                                    .tag(index)
                                
                            case .empty:
                                loadingStateView
                                    .tag(index)
                                    
                            @unknown default:
                                EmptyView()
                                    .tag(index)
                            }
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: images.count > 1 ? .automatic : .never))
                .frame(width: size, height: size)
                
                // 图片数量指示器（右上角）
                if images.count > 1 {
                    VStack {
                        HStack {
                            Spacer()
                            Text("\(currentImageIndex + 1)/\(images.count)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.ultraThinMaterial, in: Capsule())
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    .padding(6)
                }
            }
        }
    }
    
    private func errorStateView(error: ImageLoadError) -> some View {
        VStack(spacing: 6) {
            Image(systemName: error.iconName)
                .font(.title2)
                .foregroundColor(.red)
            
            Text(error.displayText)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding(8)
    }
    
    // MARK: - Helper Methods
    
    private func checkImageStatus() {
        let loadingState = googleSearchService.getLoadingState(for: menuItem)
        if case .idle = loadingState {
            // 如果状态是idle，说明还没有调用过服务
            imageError = .serviceNotCalled
        }
    }
    
    private func parseError(_ error: Error) -> ImageLoadError {
        let errorMessage = error.localizedDescription.lowercased()
        
        if errorMessage.contains("network") || errorMessage.contains("连接") {
            return .networkError
        } else if errorMessage.contains("service") || errorMessage.contains("服务") {
            return .serviceCallFailed
        } else if errorMessage.contains("url") || errorMessage.contains("链接") {
            return .urlInvalid
        } else {
            return .unknownError(error.localizedDescription)
        }
    }
}

// MARK: - 兼容性别名
typealias DishCardView = UnifiedDishCard

// MARK: - 图片网格视图（保留原有功能）
struct DishImageGridView: View {
    let dishImages: [DishImage]
    let columns: Int
    let imageSize: CGSize
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 8) {
            ForEach(Array(dishImages.enumerated()), id: \.offset) { index, dishImage in
                AsyncImage(url: URL(string: dishImage.thumbnailURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                        .frame(width: imageSize.width, height: imageSize.height)
                }
                .frame(width: imageSize.width, height: imageSize.height)
                .clipped()
                .cornerRadius(8)
            }
        }
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