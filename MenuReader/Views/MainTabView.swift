//
//  MainTabView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Camera Tab - 主要功能
            CameraView()
                .tabItem {
                    Image(systemName: "camera")
                    Text("扫描")
                }
                .tag(0)
            
            // History Tab - 历史记录
            HistoryView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("历史")
                }
                .tag(1)
            
            // Profile Tab - 用户设置
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("设置")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
} 