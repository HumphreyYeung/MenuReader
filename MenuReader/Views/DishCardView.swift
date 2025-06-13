import SwiftUI
import SDWebImage

/// Task006: 菜品卡片UI组件
@MainActor
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
            
            // 展开的详细信息（如果需要）
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
            dishImageView
            
            // 菜品信息
            dishInfoView
            
            // 操作按钮
            actionButtonsView
        }
        .padding(16)
    }
    
    private var dishImageView: some View {
        ZStack {
            // 背景占位符
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 160)
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
            
            // 实际图片
            if !dishImages.isEmpty {
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(dishImages.enumerated()), id: \.offset) { index, dishImage in
                        AsyncImage(url: URL(string: dishImage.imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .frame(height: 160)
                        .clipped()
                        .cornerRadius(12)
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(height: 160)
            }
            
            // 置信度标签
            VStack {
                HStack {
                    Spacer()
                    confidenceBadge
                }
                Spacer()
            }
            .padding(8)
        }
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
            
            // 描述（如果有）
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
                .background(Color.blue)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Expanded Content
    
    private var expandedContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            
            // 详细信息
            VStack(alignment: .leading, spacing: 8) {
                Text("详细信息")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if let description = menuItem.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("暂无详细描述")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            // 图片信息
            if !dishImages.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("参考图片 (\(dishImages.count)张)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(dishImages.enumerated()), id: \.offset) { index, dishImage in
                                AsyncImage(url: URL(string: dishImage.thumbnailURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: 60, height: 60)
                                }
                                .frame(width: 60, height: 60)
                                .clipped()
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedImageIndex == index ? Color.blue : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedImageIndex = index
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            
            // 过敏原警告（预留）
            allergenWarningView
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private var allergenWarningView: some View {
        Group {
            // 这里可以根据需要添加过敏原警告
            // 目前MenuItemAnalysis没有过敏原信息，所以暂时留空
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleMenuItem = MenuItemAnalysis(
        originalName: "宫保鸡丁",
        translatedName: "Kung Pao Chicken",
        description: "经典川菜，鸡肉配花生米，口感香辣",
        price: "¥28",
        confidence: 0.95,
        category: "主菜",
        imageSearchQuery: "kung pao chicken"
    )
    
    let sampleImages = [
        DishImage(
            title: "Kung Pao Chicken",
            imageURL: "https://example.com/kungpao1.jpg",
            thumbnailURL: "https://example.com/kungpao1_thumb.jpg",
            menuItemName: "宫保鸡丁"
        ),
        DishImage(
            title: "Kung Pao Chicken 2",
            imageURL: "https://example.com/kungpao2.jpg",
            thumbnailURL: "https://example.com/kungpao2_thumb.jpg",
            menuItemName: "宫保鸡丁"
        )
    ]
    
    return ScrollView {
        VStack(spacing: 16) {
            DishCardView(
                menuItem: sampleMenuItem,
                dishImages: sampleImages,
                onAddToCart: {
                    print("Added to cart: \(sampleMenuItem.originalName)")
                },
                onTapCard: {
                    print("Tapped card: \(sampleMenuItem.originalName)")
                }
            )
            
            DishCardView(
                menuItem: MenuItemAnalysis(
                    originalName: "麻婆豆腐",
                    translatedName: "Mapo Tofu",
                    description: "四川传统豆腐菜",
                    price: "¥18",
                    confidence: 0.88,
                    category: "主菜"
                ),
                dishImages: [],
                onAddToCart: {},
                onTapCard: {}
            )
        }
        .padding()
    }
} 