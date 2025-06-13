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
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // 设置选项
                VStack(spacing: 16) {
                    
                    // 曝光调节
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sun.max")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 30)
                            
                            Text("曝光")
                                .foregroundColor(.white)
                                .font(.body)
                            
                            Spacer()
                            
                            Button {
                                withAnimation(.spring()) {
                                    showExposureSlider.toggle()
                                }
                            } label: {
                                HStack {
                                    Text(String(format: "%.1f", cameraManager.exposureValue))
                                        .foregroundColor(.blue)
                                    Image(systemName: showExposureSlider ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        if showExposureSlider {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("-2.0")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    Button("重置") {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            cameraManager.resetExposure()
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    
                                    Spacer()
                                    
                                    Text("2.0")
                                        .font(.caption)
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
                                .accentColor(.blue)
                            }
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .background(.ultraThinMaterial)
            )
            .padding(.horizontal, 20)
        }
    }
}



#Preview {
    CameraSettingsView(cameraManager: CameraManager())
} 