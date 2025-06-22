//
//  DesignSystem.swift
//  MenuReader
//
//  健康食物主题设计系统
//

import SwiftUI

/// MenuReader 设计系统 - 健康食物主题
struct DesignSystem {
    
    // MARK: - 色彩系统
    
    /// 主色彩方案 - 健康绿色系
    struct Colors {
        
        // 背景色系 - 米白色为主
        static let backgroundPrimary = Color(red: 0.98, green: 0.98, blue: 0.96) // #FAFAF5 米白色
        static let backgroundSecondary = Color.white // #FFFFFF 纯白
        static let backgroundTertiary = Color(red: 0.96, green: 0.96, blue: 0.94) // #F5F5F0 浅米色
        
        // 主色调 - 绿色系
        static let primary = Color(red: 0.18, green: 0.49, blue: 0.20) // #2E7D32 深绿
        static let primaryLight = Color(red: 0.30, green: 0.69, blue: 0.31) // #4CAF50 标准绿
        static let primarySoft = Color(red: 0.51, green: 0.78, blue: 0.52) // #81C784 柔和绿
        static let primaryVeryLight = Color(red: 0.88, green: 0.95, blue: 0.88) // #E1F5E1 极浅绿
        
        // 点缀色 - 温暖橙色系
        static let accent = Color(red: 1.0, green: 0.42, blue: 0.21) // #FF6B35 活力橙
        static let accentLight = Color(red: 1.0, green: 0.72, blue: 0.30) // #FFB74D 温暖橙
        static let accentSoft = Color(red: 1.0, green: 0.85, blue: 0.73) // #FFD9BA 柔和橙
        
        // 文字色系
        static let textPrimary = Color(red: 0.13, green: 0.13, blue: 0.13) // #212121 深灰
        static let textSecondary = Color(red: 0.38, green: 0.38, blue: 0.38) // #616161 中灰
        static let textTertiary = Color(red: 0.62, green: 0.62, blue: 0.62) // #9E9E9E 浅灰
        
        // 功能色系
        static let success = Color(red: 0.30, green: 0.69, blue: 0.31) // #4CAF50 成功绿
        static let warning = Color(red: 1.0, green: 0.65, blue: 0.15) // #FFA726 警告橙
        static let error = Color(red: 0.94, green: 0.33, blue: 0.31) // #EF5350 错误红
        static let info = Color(red: 0.26, green: 0.65, blue: 0.96) // #42A5F5 信息蓝
        
        // 卡片和表面色系
        static let cardBackground = Color.white
        static let cardBorder = Color(red: 0.93, green: 0.93, blue: 0.91) // #EDEDE8 浅边框
        static let cardShadow = Color.black.opacity(0.08)
        
        // 分隔线和边框
        static let divider = Color(red: 0.90, green: 0.90, blue: 0.88) // #E6E6E0
        static let border = Color(red: 0.85, green: 0.85, blue: 0.83) // #D9D9D4
    }
    
    // MARK: - 字体系统
    
    struct Typography {
        // 标题字体
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 18, weight: .medium, design: .rounded)
        
        // 正文字体
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 16, weight: .medium, design: .default)
        static let bodySemibold = Font.system(size: 16, weight: .semibold, design: .default)
        
        // 小字体
        static let caption = Font.system(size: 14, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 12, weight: .regular, design: .default)
        static let captionMedium = Font.system(size: 14, weight: .medium, design: .default)
        
        // 按钮字体
        static let button = Font.system(size: 16, weight: .semibold, design: .rounded)
        static let buttonSmall = Font.system(size: 14, weight: .medium, design: .rounded)
    }
    
    // MARK: - 间距系统
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    // MARK: - 圆角系统
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
        static let round: CGFloat = 999 // 完全圆角
    }
    
    // MARK: - 阴影系统
    
    struct Shadow {
        static let small = (color: Colors.cardShadow, radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let medium = (color: Colors.cardShadow, radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let large = (color: Colors.cardShadow, radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
    }
    
    // MARK: - 图标尺寸
    
    struct IconSize {
        static let small: CGFloat = 16
        static let medium: CGFloat = 20
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
}

// MARK: - SwiftUI View 扩展

extension View {
    /// 应用主要卡片样式
    func primaryCardStyle() -> some View {
        self
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .shadow(
                color: DesignSystem.Shadow.medium.color,
                radius: DesignSystem.Shadow.medium.radius,
                x: DesignSystem.Shadow.medium.x,
                y: DesignSystem.Shadow.medium.y
            )
    }
    
    /// 应用次要卡片样式
    func secondaryCardStyle() -> some View {
        self
            .background(DesignSystem.Colors.backgroundSecondary)
            .cornerRadius(DesignSystem.CornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .stroke(DesignSystem.Colors.cardBorder, lineWidth: 1)
            )
    }
    
    /// 应用主要按钮样式
    func primaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.button)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.l)
            .padding(.vertical, DesignSystem.Spacing.m)
            .background(DesignSystem.Colors.primary)
            .cornerRadius(DesignSystem.CornerRadius.medium)
    }
    
    /// 应用次要按钮样式
    func secondaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.button)
            .foregroundColor(DesignSystem.Colors.primary)
            .padding(.horizontal, DesignSystem.Spacing.l)
            .padding(.vertical, DesignSystem.Spacing.m)
            .background(DesignSystem.Colors.primaryVeryLight)
            .cornerRadius(DesignSystem.CornerRadius.medium)
    }
    
    /// 应用强调按钮样式（橙色）
    func accentButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.button)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.l)
            .padding(.vertical, DesignSystem.Spacing.m)
            .background(DesignSystem.Colors.accent)
            .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

// MARK: - 食物主题图标

struct FoodIcons {
    static let camera = "camera.viewfinder"
    static let menu = "doc.text.image"
    static let dish = "fork.knife.circle"
    static let healthy = "leaf.circle"
    static let organic = "heart.circle"
    static let vegetarian = "carrot"
    static let spicy = "flame"
    static let cold = "snowflake"
    static let hot = "thermometer.sun"
    static let favorite = "heart.fill"
    static let cart = "cart.badge.plus"
    static let history = "clock.arrow.circlepath"
    static let search = "magnifyingglass.circle"
} 