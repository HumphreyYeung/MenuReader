//
//  AnimationConstants.swift
//  MenuReader
//
//  统一动画管理 - 健康食物主题的自然流畅动画
//

import SwiftUI

/// 统一动画常量和配置 - 健康食物主题
struct MenuAnimations {
    
    // MARK: - 自然流畅动画常量
    
    /// 分类折叠展开动画 - 像叶子展开一样自然
    static let categoryToggle = Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.1)
    
    /// 图标旋转动画 - 轻柔转动
    static let iconRotation = Animation.easeInOut(duration: 0.25)
    
    /// 卡片出现动画 - 从下方轻柔浮现
    @MainActor
    static let cardAppear = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .opacity
    )
    
    /// 卡片消失动画 - 淡出
    @MainActor
    static let cardDisappear = AnyTransition.opacity
    
    /// 按钮点击动画 - 轻微缩放
    static let buttonPress = Animation.easeInOut(duration: 0.15)
    
    /// 页面切换动画 - 平滑滑动
    static let pageTransition = Animation.easeInOut(duration: 0.4)
    
    /// 加载动画 - 呼吸效果
    static let loading = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    
    /// 成功反馈动画 - 弹性效果
    static let success = Animation.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.1)
    
    // MARK: - 动画方法
    
    /// 执行分类toggle动画
    static func performCategoryToggle(_ action: @escaping () -> Void) {
        withAnimation(categoryToggle) {
            action()
        }
    }
    
    /// 执行按钮点击动画
    static func performButtonPress(_ action: @escaping () -> Void) {
        withAnimation(buttonPress) {
            action()
        }
    }
    
    /// 执行成功反馈动画
    static func performSuccessAnimation(_ action: @escaping () -> Void) {
        withAnimation(success) {
            action()
        }
    }
}

/// SwiftUI View扩展 - 提供统一的动画接口
extension View {
    /// 应用图标动画
    func iconAnimation<T: Equatable>(value: T) -> some View {
        self.animation(MenuAnimations.iconRotation, value: value)
    }
    
    /// 应用卡片出现动画
    @MainActor
    func cardAppearTransition() -> some View {
        self.transition(MenuAnimations.cardAppear)
    }
    
    /// 应用卡片消失动画
    @MainActor
    func cardDisappearTransition() -> some View {
        self.transition(MenuAnimations.cardDisappear)
    }
    
    /// 应用按钮点击缩放效果
    func buttonPressEffect<T: Equatable>(value: T) -> some View {
        self.scaleEffect(1.0)
            .animation(MenuAnimations.buttonPress, value: value)
    }
}
