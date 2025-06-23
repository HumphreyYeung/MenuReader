//
//  CameraSettingsView.swift
//  MenuReader
//
//  Created by MenuReader on 2025-06-12.
//

import SwiftUI

struct CameraSettingsView: View {
    @ObservedObject var cameraManager: CameraManager
    @State private var showExposureSlider = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 背景遮罩
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // 设置面板
            VStack(spacing: 20) {
                // 标题栏
                HStack {
                    Text("相机设置")
                        .font(AppFonts.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
                .padding(.horizontal)
                .padding(.top, AppSpacing.m)
                
                // 设置选项
                VStack(spacing: AppSpacing.m) {
                    
                    // 曝光调节
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        HStack {
                            Image(systemName: "sun.max")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 30)
                            
                            Text("曝光")
                                .foregroundColor(.white)
                                .font(AppFonts.body)
                            
                            Spacer()
                            
                            Button {
                                withAnimation(.spring()) {
                                    showExposureSlider.toggle()
                                }
                            } label: {
                                HStack {
                                    Text(String(format: "%.1f", cameraManager.exposureValue))
                                        .foregroundColor(AppColors.accent)
                                    Image(systemName: showExposureSlider ? "chevron.up" : "chevron.down")
                                        .foregroundColor(AppColors.accent)
                                        .font(AppFonts.caption)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        if showExposureSlider {
                            VStack(spacing: AppSpacing.xs) {
                                HStack {
                                    Text("-2.0")
                                        .font(AppFonts.caption)
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    Button("重置") {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            cameraManager.resetExposure()
                                        }
                                    }
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.accent)
                                    
                                    Spacer()
                                    
                                    Text("2.0")
                                        .font(AppFonts.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Slider(
                                    value: Binding(
                                        get: { cameraManager.exposureValue },
                                        set: { cameraManager.adjustExposure($0) }
                                    ),
                                    in: -2.0...2.0,
                                    step: 0.1
                                )
                                .accentColor(AppColors.accent)
                            }
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                }
                .padding(.bottom, AppSpacing.xl)
            }
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.m)
                    .fill(Color.black.opacity(0.8))
                    .background(.ultraThinMaterial)
            )
            .padding(.horizontal, AppSpacing.m)
        }
    }
}



#Preview {
    CameraSettingsView(cameraManager: CameraManager())
} 