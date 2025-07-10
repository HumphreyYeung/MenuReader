//
//  MenuReaderApp.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI

@main
struct MenuReaderApp: App {
    @State private var showOnboarding = true
    @StateObject private var cartManager = CartManager.shared
    
    init() {
        // 全局配置返回按钮，只显示图标，不显示文字
        let backButtonAppearance = UIBarButtonItem.appearance()
        backButtonAppearance.setBackButtonTitlePositionAdjustment(UIOffset(horizontal: -1000, vertical: 0), for: .default)

        // 初始化网络监控和离线管理
        _ = NetworkMonitor.shared
        _ = OfflineManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ZStack {
                    CameraView()
                
                // Onboarding 覆盖层
                if showOnboarding {
                    OnboardingView(isPresented: $showOnboarding)
                        .zIndex(1)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.5), value: showOnboarding)
                }
                }
                .navigationDestination(for: String.self) { destination in
                    switch destination {
                    case "history":
                        HistoryView()
                    case "profile":
                        ProfileView()
                    case "cart":
                        CartView(cartItems: $cartManager.cartItems)
                    default:
                        EmptyView()
                    }
                }
                .tint(AppColors.primary)
            }
            .environmentObject(cartManager)
            .preferredColorScheme(.light)
        }
    }
}
