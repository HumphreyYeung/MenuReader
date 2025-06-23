//
//  OnboardingView.swift
//  MenuReader
//
//  Created by MenuReader on 2025-01-16.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    private let totalPages = 2
    
    var body: some View {
        ZStack {
            // 深色背景，保持与相机界面一致
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部状态栏占位
                Spacer()
                    .frame(height: 60)
                
                // 内容区域
                TabView(selection: $currentPage) {
                    // 第一页：欢迎和核心功能介绍
                    OnboardingPageView(
                        systemImage: "camera.viewfinder",
                        title: "欢迎使用 MenuReader",
                        subtitle: "扫描菜单，了解美食",
                        description: "拍照扫描任何菜单，即可获得中文翻译、菜品图片和详细信息。让您在任何餐厅都能轻松点餐。",
                        isFirstPage: true
                    )
                    .tag(0)
                    
                    // 第二页：功能说明和开始使用
                    OnboardingPageView(
                        systemImage: "photo.stack.fill",
                        title: "智能识别",
                        subtitle: "多语言翻译 · 菜品图片",
                        description: "• 支持多种语言菜单识别\n• 自动翻译成中文\n• 搜索菜品图片参考\n• 保存扫描历史记录",
                        isFirstPage: false
                    )
                    .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // 底部控制区域
                VStack(spacing: 24) {
                    // 页面指示器
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 按钮区域
                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button("上一步") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage -= 1
                                }
                            }
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        } else {
                            Spacer()
                        }
                        
                        Button(currentPage == totalPages - 1 ? "开始使用" : "下一步") {
                            if currentPage == totalPages - 1 {
                                // 完成onboarding
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    isPresented = false
                                }
                            } else {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage += 1
                                }
                            }
                        }
                        .foregroundColor(.black)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    
                    // 跳过按钮
                    if currentPage < totalPages - 1 {
                        Button("跳过") {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isPresented = false
                            }
                        }
                        .foregroundColor(.white.opacity(0.5))
                        .font(.caption)
                        .padding(.top, 8)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .statusBarHidden(false)
    }
}

// MARK: - Onboarding Page Component

struct OnboardingPageView: View {
    let systemImage: String
    let title: String
    let subtitle: String
    let description: String
    let isFirstPage: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 图标区域
            VStack(spacing: 20) {
                Image(systemName: systemImage)
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.white)
                    .frame(height: 100)
                
                // 标题
                VStack(spacing: 8) {
                    Text(title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
                .frame(height: 20)
            
            // 描述文本
            Text(description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(isPresented: .constant(true))
} 