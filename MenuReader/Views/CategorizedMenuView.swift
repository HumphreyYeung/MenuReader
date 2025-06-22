import SwiftUI

/// Task007: 分类菜单显示界面
@MainActor
struct CategorizedMenuView: View {
    let analysisResult: MenuAnalysisResult
    let dishImages: [String: [DishImage]]
    
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var isRefreshing = false
    @State private var cartItems: [CartItem] = []
    @State private var showingCart = false
    
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
        NavigationView {
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
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("菜单")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    cartButton
                }
            }
            .refreshable {
                await refreshMenu()
            }
            .sheet(isPresented: $showingCart) {
                CartView(cartItems: $cartItems)
            }
        }
    }
    
    // MARK: - Search and Filter Section
    
    private var searchAndFilterSection: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            // 搜索栏
            HStack {
                Image(systemName: FoodIcons.search)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .font(DesignSystem.Typography.body)
                
                TextField("搜索菜品...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.m)
            .padding(.vertical, DesignSystem.Spacing.m)
            .secondaryCardStyle()
            
            // 分类过滤
            if !allCategories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // "全部"按钮
                        CategoryFilterButton(
                            title: "全部",
                            isSelected: selectedCategory == nil,
                            action: {
                                selectedCategory = nil
                            }
                        )
                        
                        // 分类按钮
                        ForEach(allCategories, id: \.self) { category in
                            CategoryFilterButton(
                                title: category,
                                isSelected: selectedCategory == category,
                                action: {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.m)
        .background(DesignSystem.Colors.backgroundPrimary)
    }
    
    // MARK: - Menu Content
    
    private var menuContentView: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.l) {
                ForEach(categorizedItems.keys.sorted(), id: \.self) { category in
                    if let items = categorizedItems[category], !items.isEmpty {
                        CategorySection(
                            category: category,
                            items: items,
                            dishImages: dishImages,
                            onAddToCart: { menuItem in
                                addToCart(menuItem)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.m)
            .padding(.bottom, 100) // 为底部购物车按钮留空间
        }
        .background(DesignSystem.Colors.backgroundPrimary)
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
        .background(DesignSystem.Colors.backgroundPrimary)
    }
    
    // MARK: - Cart Button
    
    private var cartButton: some View {
        Button(action: {
            showingCart = true
        }) {
            ZStack {
                Image(systemName: FoodIcons.cart)
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.primary)
                
                if !cartItems.isEmpty {
                    Text("\(cartItems.count)")
                        .font(DesignSystem.Typography.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(Circle())
                        .offset(x: 8, y: -8)
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func addToCart(_ menuItem: MenuItemAnalysis) {
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
        
        let cartItem = CartItem(menuItem: menuItemForCart)
        cartItems.append(cartItem)
        
        // 添加触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func refreshMenu() async {
        isRefreshing = true
        
        // 模拟刷新延迟
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        isRefreshing = false
    }
}

// MARK: - Category Section

struct CategorySection: View {
    let category: String
    let items: [MenuItemAnalysis]
    let dishImages: [String: [DishImage]]
    let onAddToCart: (MenuItemAnalysis) -> Void
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 可点击的分类标题
            Button(action: {
                MenuAnimations.performCategoryToggle {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: DesignSystem.Spacing.m) {
                    // 展开/收起图标
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(DesignSystem.Typography.title3)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primary)
                        .iconAnimation(value: isExpanded)
                    
                    // 分类名称
                    Text(category)
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    // 菜品数量标签
                    Text("\(items.count)道菜")
                        .font(DesignSystem.Typography.captionMedium)
                        .foregroundColor(DesignSystem.Colors.primary)
                        .padding(.horizontal, DesignSystem.Spacing.m)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(DesignSystem.Colors.primaryVeryLight)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                }
                .padding(.vertical, DesignSystem.Spacing.m)
                .padding(.horizontal, DesignSystem.Spacing.m)
                .secondaryCardStyle()
            }
            .buttonStyle(PlainButtonStyle())
            
            // 菜品卡片（可折叠）
            if isExpanded {
                LazyVStack(spacing: 12) {
                    ForEach(items) { item in
                        UnifiedDishCard(
                            menuItem: item,
                            dishImages: dishImages[item.originalName] ?? [],
                            showCartButton: true,
                            onAddToCart: {
                                onAddToCart(item)
                            },
                            onTapCard: {
                                // 可以添加卡片点击处理逻辑
                            }
                        )
                    }
                }
                .padding(.top, 12)
                .transition(.opacity)
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
            return Double(numberString) ?? 0.0
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
        dishImages: sampleImages
    )
} 