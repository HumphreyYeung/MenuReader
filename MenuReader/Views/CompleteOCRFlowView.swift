import SwiftUI

/// 完整OCR流程视图 - 整合Task001-007
@MainActor
struct CompleteOCRFlowView: View {
    @StateObject private var menuAnalysisService = MenuAnalysisService.shared
    @StateObject private var imageService = ImageService.shared
    @StateObject private var cameraManager = CameraManager()
    
    @State private var currentStep: OCRFlowStep = .camera
    @State private var selectedImage: UIImage?
    @State private var analysisResult: MenuAnalysisResult?
    @State private var dishImages: [String: [DishImage]] = [:]
    @State private var errorMessage: String?
    @State private var showingImagePicker = false
    
    enum OCRFlowStep {
        case camera
        case processing
        case results
        case error
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 进度指示器
                progressIndicator
                
                // 主要内容
                switch currentStep {
                case .camera:
                    cameraStepView
                case .processing:
                    processingStepView
                case .results:
                    resultsStepView
                case .error:
                    errorStepView
                }
            }
            .navigationTitle("菜单识别")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingImagePicker) {
            PhotoPickerView(selectedImage: Binding(
                get: { selectedImage },
                set: { newImage in
                    selectedImage = newImage
                    if let image = newImage {
                        processImage(image)
                    }
                }
            ))
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(Array(OCRFlowStep.allCases.enumerated()), id: \.offset) { index, step in
                if step != .error {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(stepColor(for: step))
                            .frame(width: 12, height: 12)
                        
                        if index < OCRFlowStep.allCases.count - 2 { // 不包括error步骤
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    private func stepColor(for step: OCRFlowStep) -> Color {
        switch (currentStep, step) {
        case (.camera, .camera), (.processing, .processing), (.results, .results):
            return .blue
        case (.error, _):
            return .red
        default:
            if stepIndex(step) < stepIndex(currentStep) {
                return .green
            } else {
                return .gray.opacity(0.3)
            }
        }
    }
    
    private func stepIndex(_ step: OCRFlowStep) -> Int {
        switch step {
        case .camera: return 0
        case .processing: return 1
        case .results: return 2
        case .error: return 3
        }
    }
    
    // MARK: - Camera Step
    
    private var cameraStepView: some View {
        VStack(spacing: 20) {
            // 说明文字
            VStack(spacing: 12) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("拍摄或选择菜单图片")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("请确保菜单文字清晰可见，光线充足")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // 已选择的图片预览
            if let image = selectedImage {
                VStack(spacing: 16) {
                    Text("已选择图片")
                        .font(.headline)
                    
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    
                    Button("重新处理") {
                        processImage(image)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            
            Spacer()
            
            // 操作按钮
            VStack(spacing: 16) {
                Button(action: {
                    // 使用相机拍照
                    if cameraManager.isCameraAvailable {
                        // 这里可以集成CameraView的功能
                        showingImagePicker = true
                    }
                }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("拍照")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!cameraManager.isCameraAvailable)
                
                Button(action: {
                    showingImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("从相册选择")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Processing Step
    
    private var processingStepView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 处理动画
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                
                Text("正在处理菜单...")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(menuAnalysisService.currentStage.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 进度条
            VStack(spacing: 8) {
                HStack {
                    Text("处理进度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(menuAnalysisService.analysisProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: menuAnalysisService.analysisProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // 取消按钮
            Button("取消") {
                resetFlow()
            }
            .buttonStyle(.bordered)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Results Step
    
    private var resultsStepView: some View {
        Group {
            if let result = analysisResult {
                CategorizedMenuView(
                    analysisResult: result,
                    dishImages: dishImages
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("没有识别到菜品")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("请尝试重新拍摄或选择更清晰的菜单图片")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("重新扫描") {
                        resetFlow()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Error Step
    
    private var errorStepView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("处理失败")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let error = errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button("重试") {
                    if let image = selectedImage {
                        processImage(image)
                    } else {
                        resetFlow()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("重新选择图片") {
                    resetFlow()
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Methods
    
    private func processImage(_ image: UIImage) {
        currentStep = .processing
        errorMessage = nil
        
        Task {
            do {
                let (result, images) = try await menuAnalysisService.analyzeMenuWithDishImages(image)
                
                await MainActor.run {
                    analysisResult = result
                    dishImages = images
                    currentStep = .results
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    currentStep = .error
                }
            }
        }
    }
    
    private func resetFlow() {
        currentStep = .camera
        selectedImage = nil
        analysisResult = nil
        dishImages = [:]
        errorMessage = nil
    }
}

// MARK: - OCRFlowStep Extension

extension CompleteOCRFlowView.OCRFlowStep: CaseIterable {
    static var allCases: [CompleteOCRFlowView.OCRFlowStep] {
        [.camera, .processing, .results, .error]
    }
}

// MARK: - Preview

#Preview {
    CompleteOCRFlowView()
} 