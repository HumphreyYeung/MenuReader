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
    
    init() {
        // 初始化网络监控和离线管理
        _ = NetworkMonitor.shared
        _ = OfflineManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ZStack {
                    CameraView()
                        .preferredColorScheme(.dark) // 仅相机界面使用深色主题
                
                // Onboarding 覆盖层
                if showOnboarding {
                    OnboardingView(isPresented: $showOnboarding)
                        .zIndex(1)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.5), value: showOnboarding)
                }
            }
            .preferredColorScheme(.light) // 全局使用浅色主题
            }
            .navigationBarHidden(true) // 隐藏导航栏保持相机界面沉浸式
        }
    }
}
