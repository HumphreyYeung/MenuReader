import SwiftUI

/// Task007: 分类菜单显示界面
@MainActor
struct CategorizedMenuView: View {
    // MARK: - Properties
    let analysisResult: MenuAnalysisResult
    let dishImages: [String: [DishImage]]
    private let navigationMode: NavigationMode
    
    // 兼容性初始化器（保持向后兼容）
    init(analysisResult: MenuAnalysisResult, 
         dishImages: [String: [DishImage]], 
         onDismiss: (() -> Void)? = nil) {
        self.analysisResult = analysisResult
        self.dishImages = dishImages
        
        if let dismiss = onDismiss {
            self.navigationMode = .modal(onDismiss: dismiss)
        } else {
            self.navigationMode = .push
        }
    }
    
    // 明确的初始化器
    init(analysisResult: MenuAnalysisResult, 
         dishImages: [String: [DishImage]], 
         navigationMode: NavigationMode) {
        self.analysisResult = analysisResult
        self.dishImages = dishImages
        self.navigationMode = navigationMode
    }
    
    @EnvironmentObject var cartManager: CartManager
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var isRefreshing = false
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
            // 固定的搜索和过滤栏
            searchAndFilterSection
            
            // 可刷新的主要内容区域
            if categorizedItems.isEmpty {
                emptyStateView
                    .refreshable {
                        await refreshMenu()
                    }
            } else {
                menuContentView
                    .refreshable {
                        await refreshMenu()
                    }
            }
        }
        .background(AppColors.background)
        .onTapGesture {
            // 点击页面其他地方隐藏键盘
            isSearchFocused = false
        }
        .navigationTitle("Menu")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 只在模态展示时显示自定义关闭按钮
            if case .modal(let onDismiss) = navigationMode {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        onDismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                // 右侧购物车按钮 - 使用NavigationLink导航到购物车
                NavigationLink(value: "cart") {
                    ZStack {
                        Image(systemName: "cart")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                        
                        let totalQuantity = cartManager.cartItems.reduce(0) { $0 + $1.quantity }
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
                .padding(.trailing, 8)
            }
        }
    }
    
    // MARK: - Search and Filter Section
    
    private var searchAndFilterSection: some View {
        VStack(spacing: AppSpacing.m) {
            // 搜索栏 - 使用与卡片相同的宽度
            HStack(spacing: AppSpacing.s) {
                Image(systemName: AppIcons.search)
                    .foregroundColor(AppColors.secondaryText)
                    .font(AppFonts.body)
                
                TextField("search...", text: $searchText)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.primary)
                    .focused($isSearchFocused)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: AppIcons.close)
                            .foregroundColor(AppColors.secondaryText)
                            .font(AppFonts.body)
                    }
                }
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
            
            // 分类过滤标签 - 固定All标签，其他标签可滑动
            if !allCategories.isEmpty {
                HStack(spacing: 0) {
                    // 固定的"All"按钮
                    Button(action: {
                        selectedCategory = nil
                    }) {
                        Text("All")
                            .font(AppFonts.smallButton)
                            .foregroundColor(selectedCategory == nil ? AppColors.buttonText : AppColors.primary)
                            .padding(.horizontal, AppSpacing.s)
                            .padding(.vertical, AppSpacing.xs)
                            .background(selectedCategory == nil ? AppColors.primary : Color.clear)
                            .cornerRadius(AppSpacing.xxl)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppSpacing.xxl)
                                    .stroke(AppColors.separator, lineWidth: selectedCategory == nil ? 0 : 1)
                            )
                    }
                    .padding(.leading, AppSpacing.screenMargin)
                    .padding(.trailing, AppSpacing.xs)
                    
                    // 可滑动的分类标签 - 严格限制为水平滚动
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.xs) {
                            ForEach(allCategories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }) {
                                    Text(category)
                                        .font(AppFonts.smallButton)
                                        .foregroundColor(selectedCategory == category ? AppColors.buttonText : AppColors.primary)
                                        .padding(.horizontal, AppSpacing.s)
                                        .padding(.vertical, AppSpacing.xs)
                                        .background(selectedCategory == category ? AppColors.primary : Color.clear)
                                        .cornerRadius(AppSpacing.xxl)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppSpacing.xxl)
                                                .stroke(AppColors.separator, lineWidth: selectedCategory == category ? 0 : 1)
                                        )
                                }
                            }
                        }
                        .padding(.trailing, AppSpacing.screenMargin)
                    }
                    .frame(height: 40)
                    .clipped()
                    .scrollDisabled(false) // 明确允许水平滚动
                    .background(Color.clear) // 阻止背景交互
                }
                .frame(height: 40)
            }
        }
        .padding(.top, AppSpacing.s)
        .padding(.bottom, AppSpacing.m)
        .background(AppColors.background)
    }
    
    // MARK: - Menu Content
    
    private var menuContentView: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.m) {  // 增加卡片之间的间距
                ForEach(categorizedItems.keys.sorted(), id: \.self) { category in
                    if let items = categorizedItems[category], !items.isEmpty {
                        CategorySectionView(
                            category: category,
                            items: items,
                            dishImages: dishImages,
                            cartItems: $cartManager.cartItems,
                            animatingItems: $animatingItems,
                            onAddToCart: { menuItem in
                                addToCart(menuItem)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenMargin)  // 与搜索框和其他页面保持一致的水平padding
            .padding(.top, 0)  // 移除顶部间距，避免与searchAndFilterSection叠加
            .padding(.bottom, 100) // 为底部购物车按钮留空间
        }
        .background(AppColors.background)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.l) {
            Image(systemName: FoodIcons.search)
                .font(.system(size: 60))
                .foregroundColor(AppColors.tertiaryText)
            
            Text("没有找到菜品")
                .font(AppFonts.title1)
                .foregroundColor(AppColors.primary)
            
            if !searchText.isEmpty {
                Text("尝试调整搜索条件")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.secondaryText)
                
                Button("清除搜索") {
                    searchText = ""
                    selectedCategory = nil
                }
                .secondaryButtonStyle()
            } else {
                Text("菜单识别结果为空")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
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
        
        // 添加到购物车
        cartManager.addItem(menuItemForCart)
        
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
        if let existingIndex = cartManager.cartItems.firstIndex(where: { $0.menuItem.originalName == menuItem.originalName }) {
            if cartManager.cartItems[existingIndex].quantity > 1 {
                cartManager.cartItems[existingIndex].quantity -= 1
            } else {
                cartManager.cartItems.remove(at: existingIndex)
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
        LazyVStack(spacing: AppSpacing.m) {  // 统一卡片间距
            ForEach(items) { item in
                NavigationLink(destination: MenuItemDetailView(menuItem: item, dishImages: dishImages[item.originalName] ?? [])) {
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
                        onTapCard: nil  // 卡片点击由NavigationLink处理
                    )
                    .frame(maxWidth: .infinity)  // 确保卡片宽度一致
                }
                .buttonStyle(PlainButtonStyle())  // 防止NavigationLink干扰卡片内的按钮
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

// MARK: - Price Parsing Helper

private struct PriceInfo {
    let amount: Double
    let unit: String
    let isPrefix: Bool

    static func parse(from priceString: String) -> PriceInfo? {
        let trimmed = priceString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Regex to find prefix, amount, and suffix.
        // It captures (non-digits) (digits and dots) (non-digits)
        let pattern = #"^([^\d.]*)\s*([\d.]+)\s*([^\d.]*)$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)) else {
            return nil
        }
        
        // Extract amount string
        guard let amountRange = Range(match.range(at: 2), in: trimmed),
              let amount = Double(trimmed[amountRange]) else {
            return nil
        }
        
        // Extract prefix and suffix units
        let prefixUnit = Range(match.range(at: 1), in: trimmed).map { String(trimmed[$0]) } ?? ""
        let suffixUnit = Range(match.range(at: 3), in: trimmed).map { String(trimmed[$0]) } ?? ""
        
        if !prefixUnit.isEmpty {
            return PriceInfo(amount: amount, unit: prefixUnit, isPrefix: true)
        } else {
            return PriceInfo(amount: amount, unit: suffixUnit, isPrefix: false)
        }
    }
}

// MARK: - Cart View

struct CartView: View {
    @Binding var cartItems: [CartItem]
    @Environment(\.dismiss) private var dismiss
    
    private var priceDisplayFormat: (unit: String, isPrefix: Bool) {
        // Find the first item with a valid price to determine the format for the total.
        for item in cartItems {
            if let priceString = item.menuItem.price, let info = PriceInfo.parse(from: priceString) {
                // If a unit is found, use its format.
                if !info.unit.isEmpty {
                    return (unit: info.unit, isPrefix: info.isPrefix)
                }
            }
        }
        // Fallback if no prices have units or cart is empty.
        // Defaulting to a common format.
        return (unit: "元", isPrefix: false)
    }
    
    var totalPrice: String {
        let totalAmount = cartItems.reduce(0.0) { sum, item in
            guard let priceString = item.menuItem.price,
                  let info = PriceInfo.parse(from: priceString) else {
                return sum
            }
            return sum + (info.amount * Double(item.quantity))
        }
        
        let format = priceDisplayFormat
        
        // Format amount, showing decimals only if necessary.
        let formattedAmount: String
        if totalAmount.truncatingRemainder(dividingBy: 1) == 0 {
            formattedAmount = String(format: "%.0f", totalAmount)
        } else {
            formattedAmount = String(format: "%.2f", totalAmount)
        }
        
        return format.isPrefix ? "\(format.unit)\(formattedAmount)" : "\(formattedAmount)\(format.unit)"
    }
    
    var totalQuantity: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 页面内容
            VStack(spacing: 0) {
                if cartItems.isEmpty {
                    // 空购物车状态
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: FoodIcons.cart)
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.tertiaryText)
                        
                        Text("购物车为空")
                            .font(AppFonts.title1)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.primary)
                        
                        Text("添加一些美味的菜品吧！")
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.secondaryText)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.background)
                } else {
                    // 购物车内容
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.m) {
                            ForEach(cartItems.indices, id: \.self) { index in
                                CartItemRow(
                                    cartItem: cartItems[index],
                                    onQuantityChange: { newQuantity in
                                        if newQuantity <= 0 {
                                            cartItems.remove(at: index)
                                        } else {
                                            cartItems[index].quantity = newQuantity
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, AppSpacing.screenMargin)
                        .padding(.top, AppSpacing.m)
                        .padding(.bottom, 120) // 为底部总价区域预留空间
                    }
                    
                    Spacer()
                }
            }
            .background(AppColors.background)
            
            // 底部总价区域 - 固定在底部
            if !cartItems.isEmpty {
                VStack(spacing: AppSpacing.m) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text("总计")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text(totalPrice)
                                .font(AppFonts.title1)
                                .foregroundColor(AppColors.primary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // 结账逻辑
                        }) {
                            Text("Show to Servants")
                                .font(AppFonts.button)
                                .foregroundColor(AppColors.buttonText)
                                .frame(width: 140, height: 44)
                                .background(AppColors.accent)
                                .cornerRadius(AppSpacing.standardCorner)
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenMargin)
                }
                .padding(.vertical, AppSpacing.l)
                .background(AppColors.background)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
            }
        }
        .navigationTitle("Cart")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !cartItems.isEmpty {
                    Button(action: {
                        cartItems.removeAll()
                    }) {
                        HStack(spacing: 3) {
                            Text("Clear All")
                                .font(AppFonts.smallButton)
                            Text("(\(totalQuantity))")
                                .font(AppFonts.smallButton.weight(.bold))
                        }
                        .foregroundColor(AppColors.error)
                    }
                    .padding(.trailing, AppSpacing.xs)
                }
            }
        }
    }
}

// MARK: - Cart Item Row

struct CartItemRow: View {
    let cartItem: CartItem
    let onQuantityChange: (Int) -> Void
    
    private var formattedPrice: String {
        guard let priceString = cartItem.menuItem.price else { return "" }
        
        // Use the same parsing logic to format the individual item's price.
        if let info = PriceInfo.parse(from: priceString) {
            let formattedAmount: String
            if info.amount.truncatingRemainder(dividingBy: 1) == 0 {
                formattedAmount = String(format: "%.0f", info.amount)
            } else {
                formattedAmount = String(format: "%.2f", info.amount)
            }
            return info.isPrefix ? "\(info.unit)\(formattedAmount)" : "\(formattedAmount)\(info.unit)"
        }
        
        // Fallback to the original string if parsing fails.
        return priceString
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 正方形菜品图片
            AsyncImage(url: URL(string: cartItem.menuItem.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: AppSpacing.standardCorner)
                    .fill(AppColors.lightBackground)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.tertiaryText)
                    }
            }
            .frame(width: 80, height: 80)
            .clipped()
            .cornerRadius(AppSpacing.standardCorner)
            
            // 菜品信息区域 - 使用更明确的布局控制
            VStack(alignment: .leading, spacing: 6) {
                // 原始名称
                Text(cartItem.menuItem.originalName)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                // 翻译名称
                if let translatedName = cartItem.menuItem.translatedName {
                    Text(translatedName)
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                // 价格
                if cartItem.menuItem.price != nil {
                    Text(formattedPrice)
                        .font(AppFonts.headline.weight(.semibold))
                        .foregroundColor(AppColors.accent)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 增删控件 - 缩小尺寸以节省空间
            VStack(spacing: 8) {
                Spacer()
                
                HStack(spacing: 8) {
                    // 减少按钮
                    Button(action: {
                        onQuantityChange(cartItem.quantity - 1)
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.buttonText)
                            .frame(width: 24, height: 24)
                            .background(AppColors.secondaryText)
                            .clipShape(Circle())
                    }
                    
                    // 数量显示
                    Text("\(cartItem.quantity)")
                        .font(AppFonts.subheadline.weight(.semibold))
                        .foregroundColor(AppColors.primary)
                        .frame(minWidth: 16)
                    
                    // 增加按钮
                    Button(action: {
                        onQuantityChange(cartItem.quantity + 1)
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.buttonText)
                            .frame(width: 24, height: 24)
                            .background(AppColors.accent)
                            .clipShape(Circle())
                    }
                }
                
                Spacer()
            }
            .frame(width: 80)
        }
        .padding(AppSpacing.m)
        .background(AppColors.contentBackground)
        .cornerRadius(AppSpacing.largeCorner)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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

// MARK: - Navigation Mode
enum NavigationMode: Equatable {
    case modal(onDismiss: () -> Void)    // 模态展示，需要关闭按钮
    case push                            // 导航栈推送，使用系统返回按钮
    
    static func == (lhs: NavigationMode, rhs: NavigationMode) -> Bool {
        switch (lhs, rhs) {
        case (.modal, .modal), (.push, .push):
            return true
        default:
            return false
        }
    }
} 