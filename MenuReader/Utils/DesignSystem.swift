//
//  DesignSystem.swift
//  MenuReader
//
//  MenuReader App 样式指南系统
//  基于8点网格系统和苹果设计规范，确保UI的一致性和精致感
//

import SwiftUI

// MARK: - 色彩系统

struct AppColors {
    /// 主背景色 - 营造温暖、干净的感觉
    static let background = Color(red: 0.97, green: 0.96, blue: 0.95) // #F7F5F2 米白
    
    /// 内容背景色 - 卡片、弹窗等内容区域背景
    static let contentBackground = Color.white // 纯白
    
    /// 主文本/按钮色 - 主要文字、主要按钮背景、重要图标
    static let primary = Color(red: 0.11, green: 0.11, blue: 0.12) // #1C1C1E 近黑
    
    /// 次要文本色 - 辅助性文字，如菜品描述、时间戳等
    static let secondaryText = Color(red: 0.54, green: 0.54, blue: 0.56) // #8A8A8E 中灰
    
    /// 点缀/高亮色 - 可交互元素、加载指示器、高亮状态
    static let accent = Color(red: 1.0, green: 0.58, blue: 0.0) // #FF9500 亮橙
    
    /// 按钮文字色 - 用于深色按钮上的文字
    static let buttonText = Color.white // 纯白
    
    /// 分割线颜色 - 用于列表、卡片之间的分割线
    static let separator = Color(red: 0.90, green: 0.90, blue: 0.92) // #E5E5EA 浅灰
    
    /// 成功提示色
    static let success = Color(red: 0.20, green: 0.78, blue: 0.35) // #34C759 系统绿
    
    /// 失败/错误色
    static let error = Color(red: 1.0, green: 0.23, blue: 0.19) // #FF3B30 系统红
    
    /// 警告色
    static let warning = Color.orange
    
    /// 信息色
    static let info = Color.blue
    
    // MARK: 扩展色彩 - 为更丰富的UI层次
    
    /// 三级文本色 - 最不重要的文字信息
    static let tertiaryText = Color(red: 0.70, green: 0.70, blue: 0.72) // #B3B3B7
    
    /// 浅背景色 - 用于区域分割
    static let lightBackground = Color(red: 0.98, green: 0.98, blue: 0.98) // #FAFAFA
    
    /// 强调背景色 - 用于重要信息的背景
    static let accentBackground = Color(red: 1.0, green: 0.95, blue: 0.87) // #FFF2DE
}

// MARK: - 字体系统

struct AppFonts {
    /// 大标题 - 屏幕主标题，如"菜单翻译"
    static let largeTitle: Font = .system(.largeTitle, design: .default, weight: .bold)
    
    /// 标题 1 - 卡片式页面的主标题
    static let title1: Font = .system(.title, design: .default, weight: .bold)
    
    /// 标题 2 - 菜品名称、列表项标题
    static let headline: Font = .system(.headline, design: .default, weight: .semibold)
    
    /// 正文 - 菜品翻译后的内容、主要段落文字
    static let body: Font = .system(.body, design: .default, weight: .regular)
    
    /// 副标题 - 辅助说明文字
    static let subheadline: Font = .system(.subheadline, design: .default, weight: .regular)
    
    /// 标注 - 价格、备注、图片来源等小字信息
    static let caption: Font = .system(.caption, design: .default, weight: .regular)
    
    /// 脚注 - 最小的文字信息
    static let footnote: Font = .system(.footnote, design: .default, weight: .regular)
    
    /// 按钮文本 - 所有主要按钮上的文字
    static let button: Font = .system(.body, design: .default, weight: .semibold)
    
    /// 小按钮文本
    static let smallButton: Font = .system(.subheadline, design: .default, weight: .medium)
    
    /// 导航标题
    static let navigationTitle: Font = .system(.headline, design: .default, weight: .semibold)
}

// MARK: - 间距系统 (8点网格)

struct AppSpacing {
    /// 最小间距 - 4pt
    static let xxs: CGFloat = 4
    
    /// 紧凑间距 - 8pt (图标和文字，标签内部间距)
    static let xs: CGFloat = 8
    
    /// 小间距 - 12pt (列表项间距的选择之一)
    static let s: CGFloat = 12
    
    /// 标准间距 - 16pt (标题和内容间距，不同功能块间距)
    static let m: CGFloat = 16
    
    /// 大间距 - 24pt (屏幕边距的选择)
    static let l: CGFloat = 24
    
    /// 特大间距 - 32pt
    static let xl: CGFloat = 32
    
    /// 超大间距 - 48pt
    static let xxl: CGFloat = 48
    
    // MARK: 语义化间距
    
    /// 屏幕边距
    static let screenMargin: CGFloat = m
    
    /// 组件间距
    static let componentSpacing: CGFloat = m
    
    /// 卡片内边距
    static let cardPadding: CGFloat = m
    
    /// 按钮内边距
    static let buttonPaddingH: CGFloat = l
    static let buttonPaddingV: CGFloat = s
    
    /// 小按钮内边距
    static let smallButtonPaddingH: CGFloat = m
    static let smallButtonPaddingV: CGFloat = xs
    
    // MARK: 圆角系统
    
    /// 小圆角 - 标签等小元素
    static let smallCorner: CGFloat = 8
    
    /// 标准圆角 - 主要按钮、卡片、输入框
    static let standardCorner: CGFloat = 12
    
    /// 大圆角 - 大卡片
    static let largeCorner: CGFloat = 16
    
    /// 超大圆角
    static let extraLargeCorner: CGFloat = 24
}

// MARK: - 图标系统

struct AppIcons {
    // 主要功能图标
    static let camera = "camera.viewfinder"
    static let photoLibrary = "photo.on.rectangle.angled"
    static let translate = "text.magnifyingglass"
    static let settings = "gearshape.fill"
    static let history = "clock.arrow.circlepath"
    static let back = "chevron.backward"
    static let share = "square.and.arrow.up"
    static let viewImage = "photo.fill"
    
    // 状态图标
    static let favoriteEmpty = "star"
    static let favoriteFilled = "star.fill"
    static let success = "checkmark.circle.fill"
    static let error = "xmark.circle.fill"
    static let warning = "exclamationmark.triangle.fill"
    static let info = "info.circle.fill"
    
    // 导航图标
    static let chevronLeft = "chevron.left"
    static let chevronRight = "chevron.right"
    static let chevronUp = "chevron.up"
    static let chevronDown = "chevron.down"
    static let close = "xmark"
    static let more = "ellipsis"
    
    // 菜单相关图标
    static let menu = "doc.text.image"
    static let dish = "fork.knife.circle"
    static let price = "tag.fill"
    static let search = "magnifyingglass"
    static let filter = "line.3.horizontal.decrease.circle"
    
    // 图标尺寸
    static let smallSize: CGFloat = 16
    static let mediumSize: CGFloat = 20
    static let largeSize: CGFloat = 24
    static let extraLargeSize: CGFloat = 32
}

// MARK: - 食物相关图标

struct FoodIcons {
    // 健康标签图标
    static let organic = "leaf.fill"
    static let healthy = "heart.fill"
    static let spicy = "flame.fill"
    
    // 功能图标
    static let cart = "cart.fill"
    static let search = AppIcons.search
    
    // 菜品类型图标
    static let meat = "fork.knife"
    static let vegetarian = "leaf"
    static let vegan = "carrot.fill"
    static let seafood = "fish.fill"
    static let dessert = "birthday.cake.fill"
    static let drink = "cup.and.saucer.fill"
    
    // 过敏原图标
    static let gluten = "wheat"
    static let dairy = "drop.fill"
    static let nuts = "circle.fill"
    static let shellfish = "shell.fill"
    
    // 烹饪方式图标
    static let grilled = "flame"
    static let steamed = "cloud.fill"
    static let fried = "circle.hexagonpath.fill"
    static let raw = "minus.circle"
}

// MARK: - 向后兼容的DesignSystem命名空间

/// 向后兼容的设计系统命名空间
/// 用于支持现有代码中的DesignSystem.Spacing等用法
struct DesignSystem {
    
    // 间距系统 - 映射到AppSpacing
    struct Spacing {
        static let xxs = AppSpacing.xxs
        static let xs = AppSpacing.xs
        static let s = AppSpacing.s
        static let m = AppSpacing.m
        static let l = AppSpacing.l
        static let xl = AppSpacing.xl
        static let xxl = AppSpacing.xxl
    }
    
    // 颜色系统 - 映射到AppColors并添加兼容性颜色
    struct Colors {
        // 基础颜色
        static let textPrimary = AppColors.primary
        static let textSecondary = AppColors.secondaryText
        static let textTertiary = AppColors.tertiaryText
        static let accent = AppColors.accent
        static let primary = AppColors.primary
        static let error = AppColors.error
        static let success = AppColors.success
        static let warning = AppColors.warning
        
        // 边框颜色
        static let border = AppColors.separator
        
        // 扩展颜色
        static let primaryVeryLight = AppColors.lightBackground
        static let accentSoft = AppColors.accentBackground
        static let backgroundPrimary = AppColors.background
        static let backgroundSecondary = AppColors.contentBackground
    }
    
    // 字体系统 - 映射到AppFonts并添加兼容性字体
    struct Typography {
        static let largeTitle = AppFonts.largeTitle
        static let title1 = AppFonts.title1
        static let title2 = AppFonts.headline
        static let title3 = AppFonts.headline
        static let headline = AppFonts.headline
        static let body = AppFonts.body
        static let subheadline = AppFonts.subheadline
        static let caption = AppFonts.caption
        static let caption2 = AppFonts.footnote
        static let footnote = AppFonts.footnote
        
        // 按钮字体
        static let button = AppFonts.button
        static let captionMedium = Font.system(.caption, weight: .medium)
    }
    
    // 圆角系统
    struct CornerRadius {
        static let small = AppSpacing.smallCorner
        static let medium = AppSpacing.standardCorner
        static let large = AppSpacing.largeCorner
        static let extraLarge = AppSpacing.extraLargeCorner
        static let round = AppSpacing.standardCorner  // 别名，用于向后兼容
    }
}

// MARK: - 按钮样式

/// 主按钮样式 - 黑色背景
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.button)
            .foregroundColor(AppColors.buttonText)
            .padding(.horizontal, AppSpacing.buttonPaddingH)
            .padding(.vertical, AppSpacing.buttonPaddingV)
            .background(AppColors.primary)
            .cornerRadius(AppSpacing.standardCorner)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// 次要按钮样式 - 橙色边框
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.button)
            .foregroundColor(AppColors.accent)
            .padding(.horizontal, AppSpacing.buttonPaddingH)
            .padding(.vertical, AppSpacing.buttonPaddingV)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.standardCorner)
                    .stroke(AppColors.accent, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// 强调按钮样式 - 橙色背景
struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.button)
            .foregroundColor(AppColors.buttonText)
            .padding(.horizontal, AppSpacing.buttonPaddingH)
            .padding(.vertical, AppSpacing.buttonPaddingV)
            .background(AppColors.accent)
            .cornerRadius(AppSpacing.standardCorner)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// 文本按钮样式 - 橙色文字
struct TextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.button)
            .foregroundColor(AppColors.accent)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 卡片样式

/// 主要卡片样式 - 带阴影
struct PrimaryCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.contentBackground)
            .cornerRadius(AppSpacing.largeCorner)
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 12,
                x: 0,
                y: 4
            )
    }
}

/// 次要卡片样式 - 边框样式
struct SecondaryCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.contentBackground)
            .cornerRadius(AppSpacing.standardCorner)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.standardCorner)
                    .stroke(AppColors.separator, lineWidth: 1)
            )
    }
}

/// 菜品专用卡片样式
struct DishCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.contentBackground)
            .cornerRadius(AppSpacing.largeCorner)
            .shadow(
                color: Color.black.opacity(0.08),
                radius: 12,
                x: 0,
                y: 4
            )
    }
}

// MARK: - 页面标题组件

/// 标准页面标题组件 - 顶部与状态栏对齐
struct AppPageHeader: View {
    let title: String
    let showBackButton: Bool
    let onBackAction: (() -> Void)?
    let rightButton: AnyView?
    
    init(_ title: String, showBackButton: Bool = true, onBackAction: (() -> Void)? = nil, rightButton: AnyView? = nil) {
        self.title = title
        self.showBackButton = showBackButton
        self.onBackAction = onBackAction
        self.rightButton = rightButton
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 确保标题栏紧贴状态栏
            HStack(alignment: .center) {
                // 左侧按钮
                if showBackButton {
                    Button(action: {
                        onBackAction?()
                    }) {
                        Image(systemName: AppIcons.chevronLeft)
                            .font(.system(size: AppIcons.mediumSize, weight: .medium))
                            .foregroundColor(AppColors.primary)
                    }
                    .frame(width: 44, height: 44)
                } else {
                    Spacer()
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                // 中间标题
                Text(title)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.primary)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // 右侧按钮或占位
                if let rightButton = rightButton {
                    rightButton
                        .frame(width: 44, height: 44)
                } else {
                    Spacer()
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, AppSpacing.screenMargin)
            .padding(.top, AppSpacing.xs) // 顶部少量间距
            .padding(.bottom, AppSpacing.xs) // 底部少量间距
            .background(AppColors.background)
            
            // 分隔线
            Divider()
                .background(AppColors.separator)
        }
    }
}

// MARK: - 页面展示系统

/// iOS标准页面展示类型
enum PagePresentationType {
    /// 标准页面导航 - 从右到左滑入，支持边缘返回手势
    case navigation
    /// 模态弹窗 - 从底部弹出，用于相册选择、设置等
    case modal
    /// 全屏模态 - 用于图片预览、分析结果等需要完全占屏的内容
    case fullScreenModal
}

/// 页面展示包装器 - 统一管理页面展示方式
struct PagePresentationWrapper<Content: View>: View {
    let content: Content
    let presentationType: PagePresentationType
    let onDismiss: (() -> Void)?
    
    init(
        @ViewBuilder content: () -> Content,
        presentationType: PagePresentationType = .navigation,
        onDismiss: (() -> Void)? = nil
    ) {
        self.content = content()
        self.presentationType = presentationType
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        switch presentationType {
        case .navigation:
            NavigationView {
                content
                    .navigationBarHidden(true) // 使用自定义AppPageHeader
                    .navigationBarTitleDisplayMode(.inline)
            }
        case .modal:
            content
        case .fullScreenModal:
            content
        }
    }
}

// MARK: - View 扩展

extension View {
    // MARK: 页面展示样式
    
    /// 应用标准iOS页面展示样式 - 自动处理导航和返回手势
    func standardPagePresentation(
        type: PagePresentationType = .navigation,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        PagePresentationWrapper(
            content: { self },
            presentationType: type,
            onDismiss: onDismiss
        )
    }
    
    // MARK: 背景样式
    
    /// 应用主背景色
    func appBackground() -> some View {
        self.background(AppColors.background)
    }
    
    /// 应用内容背景色
    func contentBackground() -> some View {
        self.background(AppColors.contentBackground)
    }
    
    /// 应用浅背景色
    func lightBackground() -> some View {
        self.background(AppColors.lightBackground)
    }
    
    // MARK: 间距样式
    
    /// 应用标准屏幕边距
    func standardScreenPadding() -> some View {
        self.padding(.horizontal, AppSpacing.screenMargin)
    }
    
    /// 应用组件间距
    func standardComponentSpacing() -> some View {
        self.padding(.vertical, AppSpacing.componentSpacing)
    }
    
    /// 应用卡片内边距
    func cardPadding() -> some View {
        self.padding(AppSpacing.cardPadding)
    }
    
    /// 应用小内边距
    func smallPadding() -> some View {
        self.padding(AppSpacing.xs)
    }
    
    /// 应用大内边距
    func largePadding() -> some View {
        self.padding(AppSpacing.l)
    }
    
    // MARK: 圆角样式
    
    /// 应用标准圆角
    func standardCornerRadius() -> some View {
        self.cornerRadius(AppSpacing.standardCorner)
    }
    
    /// 应用小圆角
    func smallCornerRadius() -> some View {
        self.cornerRadius(AppSpacing.smallCorner)
    }
    
    /// 应用大圆角
    func largeCornerRadius() -> some View {
        self.cornerRadius(AppSpacing.largeCorner)
    }
    
    // MARK: 按钮样式
    
    /// 应用主按钮样式
    func primaryButtonStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
    
    /// 应用次要按钮样式
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
    
    /// 应用强调按钮样式
    func accentButtonStyle() -> some View {
        self.buttonStyle(AccentButtonStyle())
    }
    
    /// 应用文本按钮样式
    func textButtonStyle() -> some View {
        self.buttonStyle(TextButtonStyle())
    }
    
    // MARK: 卡片样式
    
    /// 应用主要卡片样式
    func primaryCardStyle() -> some View {
        self.modifier(PrimaryCardModifier())
    }
    
    /// 应用次要卡片样式
    func secondaryCardStyle() -> some View {
        self.modifier(SecondaryCardModifier())
    }
    
    /// 应用菜品卡片样式
    func dishCardStyle() -> some View {
        self.modifier(DishCardModifier())
    }
    
    // MARK: 图标样式
    
    /// 通用图标样式
    func iconStyle(size: CGFloat = AppIcons.mediumSize, color: Color = AppColors.primary) -> some View {
        self
            .font(.system(size: size))
            .foregroundColor(color)
    }
    
    /// 主要图标样式
    func primaryIconStyle(size: CGFloat = AppIcons.mediumSize) -> some View {
        self.iconStyle(size: size, color: AppColors.primary)
    }
    
    /// 次要图标样式
    func secondaryIconStyle(size: CGFloat = AppIcons.mediumSize) -> some View {
        self.iconStyle(size: size, color: AppColors.secondaryText)
    }
    
    /// 强调图标样式
    func accentIconStyle(size: CGFloat = AppIcons.mediumSize) -> some View {
        self.iconStyle(size: size, color: AppColors.accent)
    }
    
    // MARK: 组合样式
    
    /// 标准屏幕布局 - 包含屏幕边距和背景色
    func standardScreenLayout() -> some View {
        self
            .standardScreenPadding()
            .appBackground()
    }
    
    /// 标准内容布局 - 包含内边距、背景色和圆角
    func standardContentLayout() -> some View {
        self
            .cardPadding()
            .contentBackground()
            .standardCornerRadius()
    }
    
    /// 卡片容器布局
    func cardContainerLayout() -> some View {
        self
            .cardPadding()
            .primaryCardStyle()
    }
    
    // MARK: 页面布局
    
    /// 应用标准页面布局 - 包含顶部标题
    func standardPageLayout(title: String, showBackButton: Bool = true, onBackAction: (() -> Void)? = nil) -> some View {
        VStack(spacing: 0) {
            AppPageHeader(title, showBackButton: showBackButton, onBackAction: onBackAction)
            
            self
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .appBackground()
        }
    }
} 