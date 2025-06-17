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
        VStack(spacing: 12) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索菜品...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
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
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Menu Content
    
    private var menuContentView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
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
            .padding(.horizontal, 16)
            .padding(.bottom, 100) // 为底部购物车按钮留空间
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("没有找到菜品")
                .font(.title2)
                .fontWeight(.semibold)
            
            if !searchText.isEmpty {
                Text("尝试调整搜索条件")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("清除搜索") {
                    searchText = ""
                    selectedCategory = nil
                }
                .buttonStyle(.bordered)
            } else {
                Text("菜单识别结果为空")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Cart Button
    
    private var cartButton: some View {
        Button(action: {
            showingCart = true
        }) {
            ZStack {
                Image(systemName: "cart")
                    .font(.title3)
                
                if !cartItems.isEmpty {
                    Text("\(cartItems.count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(Color.red)
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
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // 展开/收起图标
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    
                    // 分类名称
                    Text(category)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 菜品数量标签
                    Text("\(items.count)道菜")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
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
                .transition(.opacity.combined(with: .move(edge: .top)))
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
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(20)
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
    let sampleResult = MenuAnalysisResult(
        items: [
            MenuItemAnalysis(
                originalName: "宫保鸡丁",
                translatedName: "Kung Pao Chicken",
                description: "经典川菜，鸡肉配花生米",
                price: "¥28",
                confidence: 0.95,
                category: "主菜"
            ),
            MenuItemAnalysis(
                originalName: "麻婆豆腐",
                translatedName: "Mapo Tofu",
                description: "四川传统豆腐菜",
                price: "¥18",
                confidence: 0.88,
                category: "主菜"
            ),
            MenuItemAnalysis(
                originalName: "酸辣汤",
                translatedName: "Hot and Sour Soup",
                description: "开胃汤品",
                price: "¥12",
                confidence: 0.92,
                category: "汤品"
            )
        ]
    )
    
    let sampleImages: [String: [DishImage]] = [
        "宫保鸡丁": [
            DishImage(
                title: "Kung Pao Chicken",
                imageURL: "https://example.com/kungpao.jpg",
                thumbnailURL: "https://example.com/kungpao_thumb.jpg",
                menuItemName: "宫保鸡丁"
            )
        ]
    ]
    
    return CategorizedMenuView(
        analysisResult: sampleResult,
        dishImages: sampleImages
    )
} 