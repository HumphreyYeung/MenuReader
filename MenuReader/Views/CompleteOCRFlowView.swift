//
//  CompleteOCRFlowView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI

/// 完整OCR流程视图 - 整合Task001-007，包含图片搜索和展示，以及OCRProcessingView功能
@MainActor
struct CompleteOCRFlowView: View {
    @StateObject private var menuAnalysisService = MenuAnalysisService.shared
    @StateObject private var googleSearchService = GoogleSearchService.shared
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var processingManager = OCRProcessingManager.shared
    
    @State private var currentStep: OCRFlowStep = .camera
    @State private var selectedImage: UIImage?
    @State private var analysisResult: MenuAnalysisResult?
    @State private var dishImages: [String: [DishImage]] = [:]
    @State private var errorMessage: String?
    @State private var showingImagePicker = false
    @State private var isLoadingImages = false
    @State private var imageLoadingProgress: Double = 0.0
    @State private var isSimpleMode = false // 新增：简化模式开关
    
    enum OCRFlowStep: CaseIterable {
        case camera
        case processing
        case loadingImages
        case results
        case error
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 模式切换器
                modeToggleView
                
                if isSimpleMode {
                    // 简化OCR模式（整合自OCRProcessingView）
                    simpleOCRModeView
                } else {
                    // 完整流程模式
                    completeFlowModeView
                }
            }
            .navigationTitle(isSimpleMode ? "OCR 菜单识别" : "菜单识别")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: Binding(
                get: { selectedImage },
                set: { newImage in
                    selectedImage = newImage
                    if let image = newImage {
                        if isSimpleMode {
                            Task {
                                await processingManager.startMockProcessing(image: image)
                            }
                        } else {
                            processImage(image)
                        }
                    }
                }
            ))
        }
    }
    
    // MARK: - Mode Toggle
    
    private var modeToggleView: some View {
        HStack {
            Text("模式：")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker("模式", selection: $isSimpleMode) {
                Text("完整流程").tag(false)
                Text("简单OCR").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Simple OCR Mode (整合自OCRProcessingView)
    
    private var simpleOCRModeView: some View {
        VStack(spacing: 20) {
            // 标题区域
            VStack(spacing: 8) {
                Text("上传菜单图片，自动识别并翻译")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            // 图片显示区域
            if let image = processingManager.currentImage {
                simpleImageDisplaySection(image)
            } else {
                simpleImagePlaceholderSection
            }
            
            // 处理进度区域
            if processingManager.isProcessing {
                simpleProcessingProgressSection
            } else if let result = processingManager.ocrResult {
                simpleResultsSection(result)
            } else if let error = processingManager.errorMessage {
                simpleErrorSection(error)
            }
            
            Spacer()
            
            // 操作按钮
            simpleActionButtonsSection
        }
        .padding()
    }
    
    // MARK: - Complete Flow Mode
    
    private var completeFlowModeView: some View {
        VStack(spacing: 0) {
            // 进度指示器
            progressIndicator
            
            // 主要内容
            switch currentStep {
            case .camera:
                cameraStepView
            case .processing:
                processingStepView
            case .loadingImages:
                imageLoadingStepView
            case .results:
                resultsStepView
            case .error:
                errorStepView
            }
        }
    }
    
    // MARK: - Simple Mode Components (整合自OCRProcessingView)
    
    private func simpleImageDisplaySection(_ image: UIImage) -> some View {
        VStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)
                .cornerRadius(12)
                .shadow(radius: 4)
            
            Button("选择其他图片") {
                showingImagePicker = true
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
    }
    
    private var simpleImagePlaceholderSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("选择菜单图片开始识别")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button("选择图片") {
                showingImagePicker = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var simpleProcessingProgressSection: some View {
        VStack(spacing: 16) {
            Text(processingManager.currentStatus.displayName)
                .font(.headline)
            
            ProgressView(value: processingManager.progress)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("\\(Int(processingManager.progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func simpleResultsSection(_ result: OCRProcessingResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("识别结果")
                    .font(.headline)
                Spacer()
                Text("置信度: \\(Int(result.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if result.menuItems.isEmpty {
                Text("未识别到菜单项")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(result.menuItems, id: \.id) { item in
                        // 使用统一的卡片组件，确保所有菜品都显示图片区域
                        UnifiedDishCard(
                            menuItem: item,
                            dishImages: [] // 简单OCR模式默认没有搜索图片
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func simpleErrorSection(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            Text("处理失败")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var simpleActionButtonsSection: some View {
        HStack(spacing: 16) {
            if processingManager.isProcessing {
                Button("取消") {
                    Task {
                        await processingManager.cancelProcessing()
                    }
                }
                .buttonStyle(.bordered)
            } else {
                if processingManager.errorMessage != nil {
                    Button("重试") {
                        Task {
                            if let image = processingManager.currentImage {
                                await processingManager.startMockProcessing(image: image)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("选择新图片") {
                    showingImagePicker = true
                }
                .buttonStyle(.bordered)
            }
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
        case (.camera, .camera), (.processing, .processing), (.loadingImages, .loadingImages), (.results, .results):
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
        case .loadingImages: return 2
        case .results: return 3
        case .error: return 4
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
            // 处理中动画
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(2.0)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                
                Text("正在分析菜单...")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("请稍候，我们正在识别菜品信息")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            
            Spacer()
            
            // 处理步骤说明
            VStack(alignment: .leading, spacing: 16) {
                ProcessingStepRow(
                    icon: "doc.text.viewfinder",
                    title: "文字识别",
                    description: "提取菜单中的文字内容",
                    isCompleted: true
                )
                
                ProcessingStepRow(
                    icon: "brain.head.profile",
                    title: "智能分析",
                    description: "分析菜品名称、价格和描述",
                    isCompleted: false
                )
                
                ProcessingStepRow(
                    icon: "photo.on.rectangle.angled",
                    title: "图片搜索",
                    description: "为每道菜品搜索参考图片",
                    isCompleted: false
                )
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
    }
    
    // MARK: - Image Loading Step
    
    private var imageLoadingStepView: some View {
        VStack(spacing: 30) {
            // 加载动画
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: imageLoadingProgress)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: imageLoadingProgress)
                    
                    Image(systemName: "photo.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                
                Text("正在搜索菜品图片...")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("\\(Int(imageLoadingProgress * 100))% 完成")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 60)
            
            Spacer()
            
            // 搜索进度说明
            if let result = analysisResult {
                VStack(alignment: .leading, spacing: 12) {
                    Text("正在为 \\(result.items.count) 道菜品搜索图片")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    ForEach(Array(result.items.prefix(5).enumerated()), id: \.offset) { index, item in
                        HStack {
                            Image(systemName: index < Int(imageLoadingProgress * 5) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(index < Int(imageLoadingProgress * 5) ? .green : .gray)
                            
                            Text(item.originalName)
                                .font(.subheadline)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 30)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Results Step
    
    private var resultsStepView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 成功标题
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("分析完成！")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if analysisResult != nil {
                        Text("识别到 \\(analysisResult!.items.count) 道菜品")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 20)
                
                // 分类菜品列表
                if let result = analysisResult {
                    let categorizedItems = groupItemsByCategory(result.items)
                    
                    LazyVStack(spacing: 20) {
                        ForEach(categorizedItems.keys.sorted(), id: \.self) { category in
                            if let items = categorizedItems[category], !items.isEmpty {
                                SimpleCategorySection(
                                    category: category,
                                    items: items,
                                    dishImages: dishImages
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // 操作按钮
                VStack(spacing: 12) {
                    Button("重新分析") {
                        resetToCamera()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    Button("保存结果") {
                        saveResults()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }
    
    // MARK: - Error Step
    
    private var errorStepView: some View {
        VStack(spacing: 30) {
            // 错误图标和信息
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("处理失败")
                    .font(.title)
                    .fontWeight(.bold)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .padding(.top, 60)
            
            Spacer()
            
            // 操作按钮
            VStack(spacing: 16) {
                Button("重试") {
                    if let image = selectedImage {
                        processImage(image)
                    } else {
                        resetToCamera()
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                
                Button("重新选择图片") {
                    resetToCamera()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helper Methods
    
    private func groupItemsByCategory(_ items: [MenuItemAnalysis]) -> [String: [MenuItemAnalysis]] {
        return Dictionary(grouping: items) { item in
            item.category ?? "其他"
        }
    }
    
    private func processImage(_ image: UIImage) {
        Task {
            do {
                currentStep = .processing
                
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
    
    private func resetToCamera() {
        currentStep = .camera
        selectedImage = nil
        analysisResult = nil
        dishImages = [:]
        errorMessage = nil
        imageLoadingProgress = 0.0
    }
    
    private func saveResults() {
        // TODO: 实现保存功能
        print("保存结果功能待实现")
    }
}

// MARK: - Supporting Views

struct SimpleCategorySection: View {
    let category: String
    let items: [MenuItemAnalysis]
    let dishImages: [String: [DishImage]]
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 可点击的分类标题
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // 展开/收起图标
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    
                    // 分类名称
                    Text(category)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 菜品数量标签
                    Text("\(items.count)道菜")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 菜品卡片（可折叠）
            if isExpanded {
                LazyVStack(spacing: 12) {
                    ForEach(items, id: \.id) { item in
                        let itemImages = dishImages[item.originalName] ?? []
                        UnifiedDishCard(
                            menuItem: item, 
                            dishImages: itemImages
                        )
                    }
                }
                .padding(.top, 12)
                .transition(.opacity)
            }
        }
    }
}

struct ProcessingStepRow: View {
    let icon: String
    let title: String
    let description: String
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isCompleted ? .green : .blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isCompleted ? .green : .primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - ImagePicker (整合自OCRProcessingView)

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    CompleteOCRFlowView()
} 