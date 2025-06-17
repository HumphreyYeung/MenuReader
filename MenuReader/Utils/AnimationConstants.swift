//
//  AnimationConstants.swift
//  MenuReader
//
//  统一动画管理 - 解决多文件动画冲突
//

import SwiftUI

/// 统一动画常量和配置
struct MenuAnimations {
    
    // MARK: - 动画常量
    
    /// 分类折叠展开动画
    static let categoryToggle = Animation.easeInOut(duration: 0.3)
    
    /// 图标旋转动画
    static let iconRotation = Animation.easeInOut(duration: 0.2)
    
    /// 卡片出现/消失动画
    @MainActor
    static let cardTransition = AnyTransition.opacity
    
    // MARK: - 动画方法
    
    /// 执行分类toggle动画
    static func performCategoryToggle(_ action: @escaping () -> Void) {
        withAnimation(categoryToggle) {
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
    
    /// 应用卡片transition
    @MainActor
    func cardTransition() -> some View {
        self.transition(MenuAnimations.cardTransition)
    }
}
