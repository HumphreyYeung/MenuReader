//
//  CameraView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @State private var showAPITest = false
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var permissionManager = PermissionManager.shared
    
    @State private var showPhotoLibrary = false
    @State private var showHistoryView = false
    @State private var showProfileView = false
    @State private var showImagePreview = false
    @State private var showCameraSettings = false
    @State private var selectedImage: UIImage?
    @State private var showPermissionAlert = false
    @State private var permissionMessage = ""
    @State private var deviceOrientation: UIDeviceOrientation = .portrait
    
    // 设备方向监听
    @State private var orientationNotifier = NotificationCenter.default.publisher(
        for: UIDevice.orientationDidChangeNotification
    )
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景色
                Color.black
                    .ignoresSafeArea()
                
                if permissionManager.cameraPermissionGranted && cameraManager.isConfigured {
                    // 相机预览
                    ZStack {
                        CameraPreviewView(cameraManager: cameraManager)
                            .ignoresSafeArea()
                        

                    }
                } else {
                    // 权限请求或相机不可用界面
                    VStack(spacing: 20) {
                        Image(systemName: "camera.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("需要相机权限")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("请在设置中允许 MenuReader 访问您的相机")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button("打开设置") {
                            permissionManager.openAppSettings()
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
                
                // 顶部控制栏
                VStack {
                    HStack {
                        Spacer()
                        
                        // 右上角：相机设置
                        Button(action: {
                            showCameraSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.top, geometry.safeAreaInsets.top + 10)
                    
                    Spacer()
                }
                
                // 底部控制区域
                VStack {
                    Spacer()
                    

                    
                    // 主要控制区域
                    HStack {
                        // 左侧：API测试和历史记录按钮
                        VStack(spacing: 10) {
                            Button(action: {
                                showAPITest = true
                            }) {
                                Text("API")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 28)
                                    .background(Color.blue.opacity(0.7))
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                showHistoryView = true
                            }) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 40)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                            }
                        }
                        
                        Spacer()
                        
                        // 中央：拍照按钮
                        Button(action: {
                            capturePhoto()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 80, height: 80)
                                    .scaleEffect(cameraManager.isCapturing ? 0.9 : 1.0)
                                
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 96, height: 96)
                                
                                if cameraManager.isCapturing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                }
                            }
                        }
                        .disabled(cameraManager.isCapturing)
                        .opacity(cameraManager.isCapturing ? 0.8 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: cameraManager.isCapturing)
                        
                        Spacer()
                        
                        // 右侧：相册选择按钮
                        Button(action: {
                            openPhotoLibrary()
                        }) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                }
                
                // 加载指示器（全屏）
                if cameraManager.isCapturing {
                    ZStack {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("正在拍照...")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                        .padding(20)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                    }
                    .transition(.opacity)
                }
            }
        }
        .statusBarHidden(true) // 隐藏状态栏以获得沉浸式体验
        .onAppear {
            setupCamera()
            startOrientationMonitoring()
        }
        .onDisappear {
            cameraManager.stopSession()
            stopOrientationMonitoring()
        }
        .onChange(of: cameraManager.capturedImage) { image in
            if let image = image {
                selectedImage = image
                showImagePreview = true
            }
        }
        .onReceive(orientationNotifier) { _ in
            updateDeviceOrientation()
        }
        .sheet(isPresented: $showPhotoLibrary) {
            PhotoPickerView(selectedImage: $selectedImage)
                .onDisappear {
                    if selectedImage != nil {
                        showImagePreview = true
                    }
                }
        }
        .sheet(isPresented: $showHistoryView) {
            NavigationView {
                HistoryView()
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("完成") {
                                showHistoryView = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showCameraSettings) {
            CameraSettingsView(cameraManager: cameraManager)
        }
        .sheet(isPresented: $showAPITest) {
            APITestView()
        }
        .fullScreenCover(isPresented: $showImagePreview) {
            if let image = selectedImage {
                ImagePreviewView(image: image) {
                    // 确认处理图像
                    showImagePreview = false
                    selectedImage = nil
                    // TODO: 调用图像处理服务
                } onRetake: {
                    // 重新拍照
                    showImagePreview = false
                    selectedImage = nil
                    cameraManager.capturedImage = nil
                }
            }
        }
        .alert("权限提示", isPresented: $showPermissionAlert) {
            Button("确定", role: .cancel) { }
            Button("打开设置") {
                permissionManager.openAppSettings()
            }
        } message: {
            Text(permissionMessage)
        }
    }
    
    // MARK: - Private Methods
    private func setupCamera() {
        Task {
            print("🎬 开始设置相机")
            let cameraPermissionGranted = await permissionManager.requestCameraPermission()
            
            if cameraPermissionGranted {
                print("📱 相机权限已获取，开始配置会话")
                await cameraManager.configureCameraSession()
                
                await MainActor.run {
                    if cameraManager.isConfigured {
                        print("✅ 相机会话配置完成，启动会话")
                        cameraManager.startSession()
                    } else {
                        print("❌ 相机会话配置失败")
                    }
                }
            } else {
                print("❌ 相机权限被拒绝")
                await MainActor.run {
                    permissionMessage = "需要相机权限才能拍照"
                    showPermissionAlert = true
                }
            }
        }
    }
    
    private func capturePhoto() {
        // 添加触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        cameraManager.capturePhoto()
    }
    
    private func openPhotoLibrary() {
        Task {
            let photoPermissionGranted = await permissionManager.requestPhotoLibraryPermission()
            
            if photoPermissionGranted {
                showPhotoLibrary = true
            } else {
                permissionMessage = "需要照片库访问权限才能选择图片"
                showPermissionAlert = true
            }
        }
    }
    
    // MARK: - Orientation Handling
    private func startOrientationMonitoring() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        updateDeviceOrientation()
    }
    
    private func stopOrientationMonitoring() {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    
    private func updateDeviceOrientation() {
        let newOrientation = UIDevice.current.orientation
        
        // 只处理有效的方向
        if newOrientation.isValidInterfaceOrientation {
            withAnimation(.easeInOut(duration: 0.3)) {
                deviceOrientation = newOrientation
            }
        }
    }
}

// MARK: - Device Orientation Extension
extension UIDeviceOrientation {
    var isValidInterfaceOrientation: Bool {
        switch self {
        case .portrait, .portraitUpsideDown, .landscapeLeft, .landscapeRight:
            return true
        default:
            return false
        }
    }
}

#Preview {
    CameraView()
} 