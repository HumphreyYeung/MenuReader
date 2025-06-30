import SwiftUI

/// Task007: 分类菜单显示界面
@MainActor
struct CategorizedMenuView: View {
    let analysisResult: MenuAnalysisResult
    let dishImages: [String: [DishImage]]
    let onDismiss: (() -> Void)?
    
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var isRefreshing = false
    @State private var cartItems: [CartItem] = []
    @State private var showingCart = false
    @FocusState private var isSearchFocused: Bool
    @State private var animatingItems: [String: Bool] = [:]
    
    // 分类后的菜品
    private var categorizedItems: [String: [MenuItemAnalysis]] {
        let items = filteredItems
        return Dictionary(grouping: items) { item in
            item.category ?? "其他"
        }
    }
    
    // 过滤后的菜品
    private var filteredItems: [MenuItemAnalysis] {
        let items = analysisResult.items
        
        // 搜索过滤
        let searchFiltered = searchText.isEmpty ? items : items.filter { item in
            item.originalName.localizedCaseInsensitiveContains(searchText) ||
            (item.translatedName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (item.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        
        // 分类过滤
        if let selectedCategory = selectedCategory {
            return searchFiltered.filter { ($0.category ?? "其他") == selectedCategory }
        }
        
        return searchFiltered
    }
    
    // 所有分类
    private var allCategories: [String] {
        let categories = Set(analysisResult.items.compactMap { $0.category })
        var result = Array(categories).sorted()
        if analysisResult.items.contains(where: { $0.category == nil }) {
            result.append("其他")
        }
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 统一的导航栏
            HStack(alignment: .center) {
                // 左侧返回按钮
                Button(action: {
                    onDismiss?()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                }
                .frame(width: 44, height: 44)
                
                Spacer()
                
                // 中间标题
                Text("Menu")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                // 右侧购物车按钮
                Button(action: {
                    showingCart = true
                }) {
                    ZStack {
                        Image(systemName: "cart")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                        
                        let totalQuantity = cartItems.reduce(0) { $0 + $1.quantity }
                        if totalQuantity > 0 {
                            Text("\(totalQuantity)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 18, height: 18)
                                .background(Color.orange)  // 改为橘色
                                .clipShape(Circle())
                                .offset(x: 12, y: -12)
                        }
                    }
                }
                .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 20)
            .frame(height: 44)
            .background(Color(red: 0.97, green: 0.96, blue: 0.95))
            
            // 页面内容
            VStack(spacing: 0) {
                // 搜索和过滤栏
                searchAndFilterSection
                
                // 主要内容
                if categorizedItems.isEmpty {
                    emptyStateView
                } else {
                    menuContentView
                }
            }
            .background(Color(red: 0.97, green: 0.96, blue: 0.95))
            .refreshable {
                await refreshMenu()
            }
            .onTapGesture {
                // 点击页面其他地方隐藏键盘
                isSearchFocused = false
            }
        }
        .sheet(isPresented: $showingCart) {
            CartView(cartItems: $cartItems)
        }
        .preferredColorScheme(.light)
    }
    
    // MARK: - Search and Filter Section
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 16) {  // 减少搜索栏和标签栏的间距为16pt
            // 搜索栏 - 使用与卡片相同的宽度
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                
                TextField("search...", text: $searchText)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .focused($isSearchFocused)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 20)  // 与卡片保持相同的水平padding
            
            // 分类过滤标签 - 固定All标签，其他标签可滑动
            if !allCategories.isEmpty {
                HStack(spacing: 0) {
                    // 固定的"All"按钮
                    Button(action: {
                        selectedCategory = nil
                    }) {
                        Text("All")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedCategory == nil ? .white : .black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == nil ? .black : Color.clear)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: selectedCategory == nil ? 0 : 1)
                            )
                    }
                    .padding(.leading, 20)  // 左侧padding
                    .padding(.trailing, 8)  // 与滑动标签的间距
                    
                    // 可滑动的分类标签
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(allCategories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }) {
                                    Text(category)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedCategory == category ? .white : .black)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == category ? .black : Color.clear)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: selectedCategory == category ? 0 : 1)
                                        )
                                }
                            }
                        }
                        .padding(.trailing, 20)  // 右侧padding
                    }
                }
                .frame(height: 44)  // 统一标签栏高度
                .padding(.vertical, 2)  // 减少标签栏上下padding为2pt
            }
        }
        .padding(.top, 16)  // 保留顶部16pt间距
        .padding(.bottom, 16)  // 减少底部间距为16pt
        .background(Color(red: 0.97, green: 0.96, blue: 0.95))
    }
    
    // MARK: - Menu Content
    
    private var menuContentView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {  // 增加卡片之间的间距
                ForEach(categorizedItems.keys.sorted(), id: \.self) { category in
                    if let items = categorizedItems[category], !items.isEmpty {
                        CategorySectionView(
                            category: category,
                            items: items,
                            dishImages: dishImages,
                            cartItems: $cartItems,
                            animatingItems: $animatingItems,
                            onAddToCart: { menuItem in
                                addToCart(menuItem)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)  // 统一使用20的水平padding
            .padding(.top, 0)  // 移除顶部间距，避免与searchAndFilterSection叠加
            .padding(.bottom, 100) // 为底部购物车按钮留空间
        }
        .background(Color(red: 0.97, green: 0.96, blue: 0.95))
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Image(systemName: FoodIcons.search)
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.textTertiary)
            
            Text("没有找到菜品")
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if !searchText.isEmpty {
                Text("尝试调整搜索条件")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Button("清除搜索") {
                    searchText = ""
                    selectedCategory = nil
                }
                .secondaryButtonStyle()
            } else {
                Text("菜单识别结果为空")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.97, green: 0.96, blue: 0.95))
    }
    
    // MARK: - Methods
    
    private func addToCart(_ menuItem: MenuItemAnalysis) {
        // 设置动画状态
        animatingItems[menuItem.originalName] = true
        
        // 转换为MenuItem
        let menuItemForCart = MenuItem(
            originalName: menuItem.originalName,
            translatedName: menuItem.translatedName,
            imageURL: dishImages[menuItem.originalName]?.first?.imageURL,
            category: menuItem.category,
            description: menuItem.description,
            price: menuItem.price,
            confidence: menuItem.confidence,
            hasAllergens: false,
            allergenTypes: [],
            imageResults: dishImages[menuItem.originalName]?.map { $0.imageURL } ?? []
        )
        
        // 查找是否已存在相同菜品
        if let existingIndex = cartItems.firstIndex(where: { $0.menuItem.originalName == menuItem.originalName }) {
            cartItems[existingIndex].quantity += 1
        } else {
            let cartItem = CartItem(menuItem: menuItemForCart, quantity: 1)
            cartItems.append(cartItem)
        }
        
        // 添加触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 延迟重置动画状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                animatingItems[menuItem.originalName] = false
            }
        }
    }
    
    private func removeFromCart(_ menuItem: MenuItemAnalysis) {
        if let existingIndex = cartItems.firstIndex(where: { $0.menuItem.originalName == menuItem.originalName }) {
            if cartItems[existingIndex].quantity > 1 {
                cartItems[existingIndex].quantity -= 1
            } else {
                cartItems.remove(at: existingIndex)
            }
        }
    }
    
    private func refreshMenu() async {
        isRefreshing = true
        
        // 模拟刷新延迟
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        isRefreshing = false
    }
}

// MARK: - Category Section

struct CategorySectionView: View {
    let category: String
    let items: [MenuItemAnalysis]
    let dishImages: [String: [DishImage]]
    @Binding var cartItems: [CartItem]
    @Binding var animatingItems: [String: Bool]
    let onAddToCart: (MenuItemAnalysis) -> Void
    
    var body: some View {
        // 直接显示菜品卡片列表，不显示分类标题
        LazyVStack(spacing: 16) {  // 统一卡片间距
            ForEach(items) { item in
                UnifiedDishCard(
                    menuItem: item,
                    dishImages: dishImages[item.originalName] ?? [],
                    showCartButton: true,
                    cartItems: $cartItems,
                    isAnimating: animatingItems[item.originalName] ?? false,
                    onAddToCart: {
                        onAddToCart(item)
                    },
                    onRemoveFromCart: {
                        removeFromCart(item)
                    },
                    onTapCard: {
                        // 可以添加卡片点击处理逻辑
                    }
                )
                .frame(maxWidth: .infinity)  // 确保卡片宽度一致
            }
        }
    }
    
    private func removeFromCart(_ menuItem: MenuItemAnalysis) {
        if let existingIndex = cartItems.firstIndex(where: { $0.menuItem.originalName == menuItem.originalName }) {
            if cartItems[existingIndex].quantity > 1 {
                cartItems[existingIndex].quantity -= 1
            } else {
                cartItems.remove(at: existingIndex)
            }
        }
    }
}

// MARK: - Category Filter Button

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                .padding(.horizontal, DesignSystem.Spacing.m)
                .padding(.vertical, DesignSystem.Spacing.s)
                .background(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.round)
                        .stroke(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border, lineWidth: 1)
                )
                .cornerRadius(DesignSystem.CornerRadius.round)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Cart View

struct CartView: View {
    @Binding var cartItems: [CartItem]
    @Environment(\.dismiss) private var dismiss
    
    var totalPrice: String {
        let total = cartItems.compactMap { item in
            // 简单的价格解析（假设格式为 ¥XX 或 $XX）
            let priceString = item.menuItem.price ?? "¥0"
            let numberString = priceString.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            let price = Double(numberString) ?? 0.0
            return price * Double(item.quantity)  // 乘以数量
        }.reduce(0.0) { $0 + $1 }
        
        return "¥\(String(format: "%.0f", total))"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if cartItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cart")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("购物车为空")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("添加一些美味的菜品吧！")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(cartItems) { item in
                            CartItemRow(cartItem: item)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    
                    // 底部总价和结账按钮
                    VStack(spacing: 16) {
                        HStack {
                            Text("总计:")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text(totalPrice)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            // 结账逻辑
                        }) {
                            Text("结账")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("购物车")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                if !cartItems.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("清空") {
                            cartItems.removeAll()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        cartItems.remove(atOffsets: offsets)
    }
}

// MARK: - Cart Item Row

struct CartItemRow: View {
    let cartItem: CartItem
    
    var body: some View {
        HStack(spacing: 12) {
            // 菜品图片
            AsyncImage(url: URL(string: cartItem.menuItem.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
            }
            .frame(width: 60, height: 60)
            .clipped()
            .cornerRadius(8)
            
            // 菜品信息
            VStack(alignment: .leading, spacing: 4) {
                Text(cartItem.menuItem.originalName)
                    .font(.headline)
                    .lineLimit(1)
                
                if let translatedName = cartItem.menuItem.translatedName {
                    Text(translatedName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if let price = cartItem.menuItem.price {
                    Text(price)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // 数量
            Text("x\(cartItem.quantity)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    let sampleResult = MenuAnalysisResult(items: [])
    let sampleImages: [String: [DishImage]] = [:]
    
    return CategorizedMenuView(
        analysisResult: sampleResult,
        dishImages: sampleImages,
        onDismiss: nil
    )
} 