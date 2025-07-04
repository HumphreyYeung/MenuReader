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
                default:
                    EmptyView()
                }
            }
            .preferredColorScheme(.dark) // 统一使用深色主题避免切换闪烁
            }
        }
    }
}
