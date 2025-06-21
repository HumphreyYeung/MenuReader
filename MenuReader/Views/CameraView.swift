//
//  CameraView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var menuAnalysisService = MenuAnalysisService.shared
    
    @State private var showPhotoLibrary = false
    @State private var showHistoryView = false
    @State private var showProfileView = false
    @State private var showImagePreview = false
    @State private var showCameraSettings = false
    @State private var selectedImage: UIImage?
    @State private var showPermissionAlert = false
    @State private var permissionMessage = ""
    @State private var deviceOrientation: UIDeviceOrientation = .portrait
    
    // 新增：分析结果状态
    @State private var analysisResult: MenuAnalysisResult?
    @State private var dishImages: [String: [DishImage]] = [:]
    @State private var showAnalysisResult = false
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    
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
                            showProfileView = true
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
                        // 左侧：历史记录按钮
                        VStack(spacing: 10) {
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
        }
        .onChange(of: selectedImage) { image in
            // 当selectedImage更新时，检查是否需要显示预览
            if image != nil && !showImagePreview && !showPhotoLibrary {
                print("📸 [CameraView] 检测到新选择的图片，显示预览")
                showImagePreview = true
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
        .sheet(isPresented: $showProfileView) {
            NavigationView {
                ProfileView()
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("完成") {
                                showProfileView = false
                            }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showImagePreview) {
            if let image = selectedImage {
                PhotoPreviewView(image: image) {
                    // 确认处理图像 - 使用MenuAnalysisService with 图片搜索
                    showImagePreview = false
                    
                    // 启动完整的菜单分析（包含图片搜索）
                    Task {
                        await analyzeMenuWithImages(image)
                    }
                } onRetake: {
                    // 重新拍照
                    showImagePreview = false
                    selectedImage = nil
                    cameraManager.capturedImage = nil
                }
            } else {
                // 安全检查：如果没有图片，自动关闭预览
                VStack {
                    Text("图片加载失败")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    Button("关闭") {
                        showImagePreview = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .onAppear {
                    // 自动关闭，避免用户困惑
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showImagePreview = false
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showAnalysisResult) {
            if let result = analysisResult {
                NavigationView {
                    CategorizedMenuView(
                        analysisResult: result,
                        dishImages: dishImages
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("完成") {
                                showAnalysisResult = false
                                selectedImage = nil
                                resetAnalysisState()
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("重新拍照") {
                                showAnalysisResult = false
                                selectedImage = nil
                                resetAnalysisState()
                            }
                        }
                    }
                }
            }
        }
        .overlay {
            // 分析进度指示器
            if isAnalyzing {
                ZStack {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        VStack(spacing: 8) {
                            Text("正在分析菜单...")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(menuAnalysisService.currentStage.description)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            ProgressView(value: menuAnalysisService.analysisProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .frame(width: 200)
                        }
                    }
                    .padding(30)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(16)
                }
                .transition(.opacity)
            }
        }
        .alert("分析错误", isPresented: .constant(analysisError != nil)) {
            Button("确定") {
                analysisError = nil
            }
            Button("重试") {
                if let image = selectedImage {
                    Task {
                        await analyzeMenuWithImages(image)
                    }
                }
            }
        } message: {
            Text(analysisError ?? "")
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
            print("🎬 [CameraView] 开始设置相机和权限")
            
            // 同时请求相机和相册权限
            async let cameraPermissionTask = permissionManager.requestCameraPermission()
            async let photoPermissionTask = permissionManager.requestPhotoLibraryPermission()
            
            let (cameraPermissionGranted, photoPermissionGranted) = await (cameraPermissionTask, photoPermissionTask)
            
            print("📱 [CameraView] 相机权限: \(cameraPermissionGranted ? "已获取" : "被拒绝")")
            print("📸 [CameraView] 相册权限: \(photoPermissionGranted ? "已获取" : "被拒绝")")
            
            if cameraPermissionGranted {
                print("📱 [CameraView] 相机权限已获取，开始配置会话")
                await cameraManager.configureCameraSession()
                
                await MainActor.run {
                    if cameraManager.isConfigured {
                        print("✅ [CameraView] 相机会话配置完成，启动会话")
                        cameraManager.startSession()
                    } else {
                        print("❌ [CameraView] 相机会话配置失败")
                    }
                }
            } else {
                print("❌ [CameraView] 相机权限被拒绝")
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
        
        print("🎬 开始拍照")
        cameraManager.capturePhoto()
    }
    
    private func openPhotoLibrary() {
        print("📸 [CameraView] 尝试打开相册...")
        
        // 由于权限已在App启动时获取，直接检查当前状态
        if permissionManager.photoLibraryPermissionGranted {
            print("✅ [CameraView] 相册权限已获得，打开相册")
            showPhotoLibrary = true
        } else {
            print("❌ [CameraView] 相册权限未获得，尝试重新请求")
            Task {
                let photoPermissionGranted = await permissionManager.requestPhotoLibraryPermission()
                
                await MainActor.run {
                    if photoPermissionGranted {
                        print("✅ [CameraView] 权限请求成功，打开相册")
                        showPhotoLibrary = true
                    } else {
                        print("❌ [CameraView] 权限请求失败")
                        permissionMessage = "需要照片库访问权限才能选择图片"
                        showPermissionAlert = true
                    }
                }
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
    
    // MARK: - 新增：菜单分析方法
    private func analyzeMenuWithImages(_ image: UIImage) async {
        print("🔄 开始完整的菜单分析（包含图片搜索）...")
        
        isAnalyzing = true
        analysisError = nil
        
        do {
            print("📞 调用 menuAnalysisService.analyzeMenuWithDishImages...")
            let (result, images) = try await menuAnalysisService.analyzeMenuWithDishImages(image)
            
            await MainActor.run {
                print("✅ 分析完成！识别到 \(result.items.count) 个菜品")
                print("🖼️ 获取到 \(images.count) 组菜品图片")
                
                analysisResult = result
                dishImages = images
                isAnalyzing = false
                showAnalysisResult = true
                
                // 🔥 保存到历史记录
                saveMenuToHistory(result: result, originalImage: image)
                
                // 打印详细结果
                for item in result.items {
                    print("🍽️ \(item.originalName) -> \(item.translatedName ?? "无翻译")")
                    if let itemImages = images[item.originalName] {
                        print("   📸 找到 \(itemImages.count) 张图片")
                    }
                }
            }
            
        } catch {
            await MainActor.run {
                print("❌ 菜单分析失败: \(error)")
                isAnalyzing = false
                analysisError = "分析失败：\(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - 历史记录保存
    private func saveMenuToHistory(result: MenuAnalysisResult, originalImage: UIImage) {
        print("💾 开始保存菜单到历史记录...")
        
        // 创建MenuProcessResult
        let processResult = MenuProcessResult(items: result.items)
        
        // 保存到历史记录，包含原始图片用于生成缩略图
        StorageService.shared.saveMenuHistory(processResult, originalImage: originalImage)
        
        print("✅ 菜单已保存到历史记录，包含 \(result.items.count) 个菜品")
    }
    
    private func resetAnalysisState() {
        analysisResult = nil
        dishImages = [:]
        analysisError = nil
        isAnalyzing = false
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
