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

// MARK: - 重新设计的菜品卡片组件
struct UnifiedDishCard: View {
    let menuItem: MenuItemAnalysis
    let dishImages: [DishImage]
    let showCartButton: Bool
    @Binding var cartItems: [CartItem]
    let isAnimating: Bool
    let onAddToCart: (() -> Void)?
    let onRemoveFromCart: (() -> Void)?
    let onTapCard: (() -> Void)?
    
    @State private var selectedImageIndex = 0
    
    // 计算当前菜品在购物车中的数量
    private var quantity: Int {
        cartItems.first(where: { $0.menuItem.originalName == menuItem.originalName })?.quantity ?? 0
    }
    
    init(menuItem: MenuItemAnalysis, 
         dishImages: [DishImage], 
         showCartButton: Bool = false,
         cartItems: Binding<[CartItem]> = .constant([]),
         isAnimating: Bool = false,
         onAddToCart: (() -> Void)? = nil,
         onRemoveFromCart: (() -> Void)? = nil,
         onTapCard: (() -> Void)? = nil) {
        self.menuItem = menuItem
        self.dishImages = dishImages
        self.showCartButton = showCartButton
        self._cartItems = cartItems
        self.isAnimating = isAnimating
        self.onAddToCart = onAddToCart
        self.onRemoveFromCart = onRemoveFromCart
        self.onTapCard = onTapCard
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 主图片区域
            imageSection
            
            // 菜品信息区域
            infoSection
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .frame(maxWidth: .infinity)  // 确保卡片宽度一致
        .overlay(
            // 购物车动画圆点
            animationDot
        )
    }
    
    // MARK: - 图片区域
    private var imageSection: some View {
        ZStack {
            if !dishImages.isEmpty {
                // 使用TabView实现滑动切换图片
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(dishImages.enumerated()), id: \.offset) { index, dishImage in
                        
                        CachedAsyncImage(url: dishImage.imageURL) {
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 40))
                                )
                        } content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        }
                        .tag(index)
                        .id("\(menuItem.originalName)-\(index)-\(dishImage.imageURL)")  // 添加稳定的ID避免重复加载
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 200)
                
                // 多图片圆点指示器
                if dishImages.count > 1 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 6) {
                                ForEach(0..<dishImages.count, id: \.self) { index in
                                    Circle()
                                        .fill(index == selectedImageIndex ? .white : .white.opacity(0.5))
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.3))
                            .cornerRadius(12)
                            .padding(.trailing, 12)
                            .padding(.bottom, 12)
                        }
                    }
                }
                
                // 价格标签（左下角）- 使用橘色底白色字
                if let price = menuItem.price {
                    VStack {
                        Spacer()
                        HStack {
                            Text(price)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.orange)  // 改为橘色
                                .cornerRadius(8)
                                .padding(.leading, 12)
                                .padding(.bottom, 12)
                            Spacer()
                        }
                    }
                }
            } else {
                // 无图片占位符
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .font(.system(size: 40))
                            Text("暂无图片")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            }
        }
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: 12,
                    bottomLeading: 0,
                    bottomTrailing: 0,
                    topTrailing: 12
                )
            )
        )
        .contentShape(Rectangle())  // 限制点击区域仅限于图片区域
        .onTapGesture {
            // 图片区域点击不触发卡片点击事件，保留给图片切换
        }
    }
    
    // MARK: - 菜品信息区域
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 菜品名称 - 同时显示原始和翻译名称
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // 原始名称
                    Text(menuItem.originalName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                    
                    // 翻译名称 - 始终显示（如果存在且不同）
                    if let translatedName = menuItem.translatedName, 
                       !translatedName.isEmpty,
                       translatedName != menuItem.originalName {
                        Text(translatedName)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // +/- 购物车按钮
                if showCartButton {
                    addToCartButtons
                }
            }
            
            // 描述
            if let description = menuItem.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            // 标签（素食、辣度等）
            tagsSection
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)  // 增加底部间距避免重叠
        .contentShape(Rectangle())
        .onTapGesture {
            onTapCard?()
        }
    }
    
    // MARK: - 添加到购物车按钮
    private var addToCartButtons: some View {
        HStack(spacing: 8) {
            if quantity > 0 {
                // 减号按钮
                Button(action: {
                    onRemoveFromCart?()
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.orange)
                        .frame(width: 32, height: 32)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // 数量显示
                Text("\(quantity)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 24)
            }
            
            // 加号按钮
            Button(action: {
                onAddToCart?()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(.orange)
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - 购物车动画圆点
    private var animationDot: some View {
        Group {
            if isAnimating {
                Circle()
                    .fill(.orange)
                    .frame(width: 12, height: 12)
                    .opacity(isAnimating ? 0.0 : 1.0)
                    .scaleEffect(isAnimating ? 1.5 : 1.0)
                    .position(x: isAnimating ? UIScreen.main.bounds.width - 44 : 200, y: isAnimating ? 44 : 100)
                    .animation(.easeInOut(duration: 1.0), value: isAnimating)
            }
        }
    }
    
    // MARK: - 标签区域  
    private var tagsSection: some View {
        HStack(spacing: 8) {
            // 素食标签
            if menuItem.isVegan == true {
                tagView(text: "纯素", color: .green)
            } else if menuItem.isVegetarian == true {
                tagView(text: "素食", color: .green)
            }
            
            // 辣度标签
            if let spicyLevel = menuItem.spicyLevel, spicyLevel != "0" {
                tagView(text: "辣度\(spicyLevel)", color: .red)
            }
            
            Spacer()
        }
    }
    
    private func tagView(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .cornerRadius(8)
    }
}

// MARK: - 其他组件

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
        let _ = print("🎨 [DishSquareImageView] 渲染菜品: \(menuItem.originalName), 传入图片: \(dishImages.count)张, 服务状态: 查询中")
        
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

// MARK: - 图片缓存管理器
@MainActor
class ImageCacheManager: ObservableObject {
    static let shared = ImageCacheManager()
    private var cache: [String: UIImage] = [:]
    private var loadingTasks: [String: Task<UIImage?, Never>] = [:]
    
    private init() {}
    
    func getImage(for url: String) -> UIImage? {
        return cache[url]
    }
    
    func loadImage(for url: String) async -> UIImage? {
        // 如果已经缓存了，直接返回
        if let cachedImage = cache[url] {
            return cachedImage
        }
        
        // 如果正在加载，等待现有任务完成
        if let existingTask = loadingTasks[url] {
            return await existingTask.value
        }
        
        // 创建新的加载任务
        let task = Task<UIImage?, Never> {
            guard let imageUrl = URL(string: url) else { return nil as UIImage? }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: imageUrl)
                let image = UIImage(data: data)
                
                // 缓存图片
                if let image = image {
                    cache[url] = image
                }
                
                return image
            } catch {
                return nil as UIImage?
            }
        }
        
        loadingTasks[url] = task
        let result = await task.value
        loadingTasks.removeValue(forKey: url)
        
        return result
    }
}

// MARK: - 缓存图片组件
struct CachedAsyncImage: View {
    let url: String
    let placeholder: AnyView
    let content: (Image) -> AnyView
    
    @StateObject private var cacheManager = ImageCacheManager.shared
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(url: String, @ViewBuilder placeholder: () -> some View, @ViewBuilder content: @escaping (Image) -> some View) {
        self.url = url
        self.placeholder = AnyView(placeholder())
        self.content = { image in AnyView(content(image)) }
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder
                    .onAppear {
                        Task {
                            await loadImage()
                        }
                    }
            }
        }
    }
    
    private func loadImage() async {
        guard !isLoading else { return }
        isLoading = true
        
        // 先检查缓存
        if let cachedImage = cacheManager.getImage(for: url) {
            image = cachedImage
            isLoading = false
            return
        }
        
        // 加载新图片
        if let loadedImage = await cacheManager.loadImage(for: url) {
            image = loadedImage
        }
        
        isLoading = false
    }
} 
