//
//  DishImageView.swift
//  MenuReader
//
//  Created by MenuReader on 2025-06-13.
//

import SwiftUI

/// 菜品图片显示组件 - 支持懒加载和缓存
struct DishImageView: View {
    let dishImage: DishImage
    let size: CGSize
    let cornerRadius: CGFloat
    
    @State private var isLoaded = false
    @State private var loadingFailed = false
    
    init(dishImage: DishImage, 
         size: CGSize = CGSize(width: 120, height: 120),
         cornerRadius: CGFloat = 8) {
        self.dishImage = dishImage
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        ZStack {
            // 背景占位符
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.2))
                .frame(width: size.width, height: size.height)
            
            if loadingFailed {
                // 错误状态
                errorPlaceholder
            } else {
                // 图片内容
                imageContent
            }
        }
        .frame(width: size.width, height: size.height)
    }
    
    // MARK: - View Components
    
    private var imageContent: some View {
        AsyncImage(url: URL(string: dishImage.thumbnailURL)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipped()
                .cornerRadius(cornerRadius)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoaded = true
                    }
                }
        } placeholder: {
            loadingPlaceholder
        }
        .onAppear {
            loadingFailed = false
        }
    }
    
    private var loadingPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.1))
            
            VStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                
                Text("加载中...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size.width, height: size.height)
    }
    
    private var errorPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.1))
            
            VStack(spacing: 4) {
                Image(systemName: "photo.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text("加载失败")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

/// 菜品图片网格视图
struct DishImageGridView: View {
    let dishImages: [DishImage]
    let columns: Int
    let spacing: CGFloat
    let imageSize: CGSize
    
    @State private var selectedImage: DishImage?
    @State private var showImageDetail = false
    
    init(dishImages: [DishImage],
         columns: Int = 3,
         spacing: CGFloat = 8,
         imageSize: CGSize = CGSize(width: 100, height: 100)) {
        self.dishImages = dishImages
        self.columns = columns
        self.spacing = spacing
        self.imageSize = imageSize
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: spacing) {
            ForEach(dishImages) { dishImage in
                DishImageView(
                    dishImage: dishImage,
                    size: imageSize,
                    cornerRadius: 8
                )
                .onTapGesture {
                    selectedImage = dishImage
                    showImageDetail = true
                }
            }
        }
        .sheet(isPresented: $showImageDetail) {
            if let selectedImage = selectedImage {
                DishImageDetailView(dishImage: selectedImage)
            }
        }
    }
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
    }
}

/// 菜品图片详情视图
struct DishImageDetailView: View {
    let dishImage: DishImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 大图显示
                    AsyncImage(url: URL(string: dishImage.imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                            .cornerRadius(12)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 300)
                            .overlay {
                                ProgressView()
                            }
                    }
                    
                    // 图片信息
                    VStack(alignment: .leading, spacing: 12) {
                        Text(dishImage.title)
                            .font(.headline)
                            .lineLimit(3)
                        
                        if let sourceURL = dishImage.sourceURL {
                            Link("查看原图", destination: URL(string: sourceURL)!)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        // 图片尺寸信息
                        if let width = dishImage.width, let height = dishImage.height {
                            Text("尺寸: \(width) × \(height)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("菜品: \(dishImage.menuItemName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("菜品图片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// 菜品图片加载状态视图
struct DishImageLoadingView: View {
    let loadingState: ImageLoadingState
    let menuItemName: String
    
    var body: some View {
        Group {
            switch loadingState {
            case .idle:
                EmptyView()
                
            case .loading:
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("正在搜索 \(menuItemName) 的图片...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
            case .loaded(let dishImages):
                if dishImages.isEmpty {
                    VStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("未找到相关图片")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    DishImageGridView(dishImages: dishImages)
                }
                
            case .failed(let error):
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("加载失败")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(error.localizedDescription)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleDishImage = DishImage(
        title: "宫保鸡丁",
        imageURL: "https://example.com/kungpao.jpg",
        thumbnailURL: "https://example.com/kungpao_thumb.jpg",
        menuItemName: "宫保鸡丁"
    )
    
    return VStack {
        DishImageView(dishImage: sampleDishImage)
        
        DishImageGridView(dishImages: [sampleDishImage, sampleDishImage, sampleDishImage])
    }
    .padding()
} 