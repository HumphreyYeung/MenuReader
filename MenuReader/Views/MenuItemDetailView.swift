//
//  MenuItemDetailView.swift
//  MenuReader
//
//  Created by MenuReader on 2025-06-13.
//

import SwiftUI

struct MenuItemDetailView: View {
    let menuItem: MenuItemAnalysis
    let dishImages: [DishImage]
    
    @EnvironmentObject var cartManager: CartManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImageIndex = 0
    @State private var isAnimating = false
    
    // 计算当前菜品在购物车中的数量
    private var quantity: Int {
        cartManager.cartItems.first(where: { $0.menuItem.originalName == menuItem.originalName })?.quantity ?? 0
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 主图片区域
                imageSection
                
                // 菜品信息区域
                infoSection
                
                // 底部填充空间
                Color.clear.frame(height: 100)
            }
        }
        .background(AppColors.background)
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // 购物车按钮
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
                            .background(Color.orange)
                            .clipShape(Circle())
                            .offset(x: 12, y: -12)
                    }
                }
            }
        }
        .overlay(
            // 底部按钮区域
            VStack {
                Spacer()
                bottomButtonSection
            }
        )
    }
    
    // MARK: - 图片区域
    private var imageSection: some View {
        GeometryReader { geometry in
            let imageSize = geometry.size.width  // 正方形，宽度等于屏幕宽度
            
            ZStack {
                if !dishImages.isEmpty {
                    // 使用TabView实现滑动切换图片
                    TabView(selection: $selectedImageIndex) {
                        ForEach(Array(dishImages.enumerated()), id: \.offset) { index, dishImage in
                            CachedAsyncImage(url: dishImage.imageURL) {
                                RoundedRectangle(cornerRadius: 0)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: imageSize, height: imageSize)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 40))
                                            Text("加载中...")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    )
                            } content: { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: imageSize, height: imageSize)
                                    .clipped()
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(width: imageSize, height: imageSize)
                    
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
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.black.opacity(0.3))
                                .cornerRadius(12)
                                .padding(.trailing, 20)
                                .padding(.bottom, 20)
                            }
                        }
                    }
                } else {
                    // 无图片占位符
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: imageSize, height: imageSize)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 60))
                                Text("暂无图片")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                        )
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)  // 确保正方形比例
    }
    
    // MARK: - 菜品信息区域
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            // 菜品名称区域
            nameSection
            
            // 描述区域
            if let description = menuItem.description, !description.isEmpty {
                descriptionSection(description)
            }
            
            // 过敏原提示
            allergenSection
        }
        .padding(.horizontal, AppSpacing.screenMargin)
        .padding(.top, AppSpacing.l)
        .background(AppColors.background)
    }
    
    // MARK: - 菜品名称区域
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            // 原始名称
            Text(menuItem.originalName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.primary)
                .lineLimit(nil)
            
            // 翻译名称（副标题）
            if let translatedName = menuItem.translatedName, 
               !translatedName.isEmpty,
               translatedName != menuItem.originalName {
                Text(translatedName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(nil)
            }
        }
    }
    
    // MARK: - 描述区域
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(description)
                .font(.system(size: 16))
                .foregroundColor(AppColors.secondaryText)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
        }
    }
    
    // MARK: - 过敏原提示区域
    private var allergenSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            // 检查是否有过敏原信息
            if menuItem.hasUserAllergens && !(menuItem.allergens?.isEmpty ?? true) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                    
                    Text("Allergen: \(menuItem.allergens?.joined(separator: ", ") ?? "")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, AppSpacing.s)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.error)
                .cornerRadius(AppSpacing.smallCorner)
            }
        }
    }
    
    // MARK: - 底部按钮区域
    private var bottomButtonSection: some View {
        VStack(spacing: 0) {
            // 分割线
            Divider()
                .background(AppColors.separator)
            
            HStack {
                // 价格显示
                if let price = menuItem.price {
                    Text(price)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.primary)
                } else {
                    Text("价格面议")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                // 添加到购物车按钮
                Button(action: {
                    addToCart()
                }) {
                    Text("Add to cart")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.primary)
                        .cornerRadius(AppSpacing.standardCorner)
                }
                .frame(maxWidth: 200)
            }
            .padding(.horizontal, AppSpacing.screenMargin)
            .padding(.vertical, AppSpacing.m)
            .background(AppColors.background)
        }
    }
    
    // MARK: - 功能方法
    private func addToCart() {
        // 设置动画状态
        isAnimating = true
        
        // 转换为MenuItem
        let menuItemForCart = MenuItem(
            originalName: menuItem.originalName,
            translatedName: menuItem.translatedName,
            imageURL: dishImages.first?.imageURL,
            category: menuItem.category,
            description: menuItem.description,
            price: menuItem.price,
            confidence: menuItem.confidence,
            hasAllergens: menuItem.hasUserAllergens,
            allergenTypes: menuItem.allergens ?? [],
            imageResults: dishImages.map { $0.imageURL }
        )
        
        // 添加到购物车
        cartManager.addItem(menuItemForCart)
        
        // 添加触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 延迟重置动画状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimating = false
        }
    }
}



// MARK: - 预览
#Preview {
    let sampleMenuItem = MenuItemAnalysis(
        originalName: "Côté France Plate",
        translatedName: "The French Plate",
        description: "A board with two cheeses, prosciutto, and our homemade pâté, serve with a very delicious gradients. A generous platter of classic French cured meats and cheeses, with all the traditional accompaniments.",
        price: "€22",
        confidence: 0.95,
        category: "主菜",
        allergens: ["Dairy"],
        hasUserAllergens: true,
        isVegetarian: false,
        isVegan: false,
        spicyLevel: "0"
    )
    
    let sampleImages = [
        DishImage(title: "Sample Image 1", imageURL: "https://example.com/image1.jpg", thumbnailURL: "https://example.com/image1.jpg", menuItemName: "Côté France Plate"),
        DishImage(title: "Sample Image 2", imageURL: "https://example.com/image2.jpg", thumbnailURL: "https://example.com/image2.jpg", menuItemName: "Côté France Plate")
    ]
    
    NavigationView {
        MenuItemDetailView(menuItem: sampleMenuItem, dishImages: sampleImages)
            .environmentObject(CartManager.shared)
    }
} 