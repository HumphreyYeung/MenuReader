//
//  CameraPreviewView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI
import AVFoundation
import UIKit

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.backgroundColor = .black
        
        // 获取预览层并设置初始属性
        let previewLayer = cameraManager.getPreviewLayer()
        previewLayer.videoGravity = .resizeAspectFill
        
        // 将预览层添加到视图
        view.layer.addSublayer(previewLayer)
        view.previewLayer = previewLayer
        
        return view
    }
    
    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        // 确保预览层的frame与视图匹配
        DispatchQueue.main.async {
            if uiView.bounds != .zero {
                uiView.previewLayer?.frame = uiView.bounds
            }
        }
    }
}

// MARK: - Custom UIView for Preview
class PreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 当视图布局改变时，更新预览层的frame
        previewLayer?.frame = bounds
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
} 
