//
//  PhotoPreviewView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI

struct PhotoPreviewView: View {
    let image: UIImage
    let onConfirm: () -> Void
    let onRetake: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color.black
                    .ignoresSafeArea()
                
                // 图片预览界面
                VStack {
                    Spacer()
                    
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: max(geometry.size.width - 40, 100))
                        .cornerRadius(12)
                    
                    Spacer()
                }
                
                // 底部按钮区域
                VStack {
                    Spacer()
                    
                    HStack(spacing: 40) {
                        // 重拍/重选按钮
                        Button(action: onRetake) {
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                                
                                Text("重拍")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // 确认处理按钮
                        Button(action: onConfirm) {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.green)
                                
                                Text("确认处理")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 40)
                }
                
                // 顶部关闭按钮
                VStack {
                    HStack {
                        Button(action: onRetake) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 20)
                        .padding(.top, geometry.safeAreaInsets.top + 10)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
            }
        }
        .statusBarHidden(true)
    }
}

#Preview {
    PhotoPreviewView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        onConfirm: { },
        onRetake: { }
    )
} 