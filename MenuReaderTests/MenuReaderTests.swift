//
//  MenuReaderTests.swift
//  MenuReaderTests
//
//  Created by Humphrey Yeung on 6/10/25.
//

import XCTest
@testable import MenuReader

final class MenuReaderTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGeminiServiceInitialization() throws {
        // 测试GeminiService单例初始化
        let service = GeminiService.shared
        // 验证服务实例存在且可用
        XCTAssertTrue(type(of: service) == GeminiService.self)
    }
    
    @MainActor func testGoogleSearchServiceInitialization() throws {
        // 测试GoogleSearchService单例初始化
        let service = GoogleSearchService.shared
        // 验证服务实例存在且可用
        XCTAssertTrue(type(of: service) == GoogleSearchService.self)
    }
    
    @MainActor func testGoogleSearchServiceStateManagement() throws {
        let service = GoogleSearchService.shared
        
        // 清理状态
        service.clearStates()
        
        // 测试初始状态
        let testMenuItem = MenuItemAnalysis(
            originalName: "测试菜品",
            translatedName: "Test Dish", 
            description: "测试描述",
            price: "¥25"
        )
        
        let initialState = service.getLoadingState(for: testMenuItem)
        XCTAssertTrue(initialState == .idle)
        
        // 测试状态更新
        let testImages = [DishImage(
            id: UUID(),
            title: "Test Image",
            imageURL: "https://example.com/image.jpg",
            thumbnailURL: "https://example.com/thumb.jpg",
            sourceURL: "https://example.com/source",
            width: 300,
            height: 200,
            menuItemName: "测试菜品",
            isLoaded: false
        )]
        
        service.updateState(for: testMenuItem.originalName, to: .loaded(testImages))
        
        let updatedState = service.getLoadingState(for: testMenuItem)
        if case .loaded(let images) = updatedState {
            XCTAssertEqual(images.count, 1)
            XCTAssertEqual(images.first?.title, "Test Image")
        } else {
            XCTFail("Expected loaded state")
        }
        
        // 清理
        service.clearStates()
    }
    
    func testGeminiRequestCreation() throws {
        // 测试Gemini请求模型的创建
        let textPart = GeminiPart(text: "测试文本")
        let content = GeminiContent(parts: [textPart])
        let request = GeminiRequest(contents: [content])
        
        XCTAssertEqual(request.contents.count, 1)
        XCTAssertEqual(request.contents.first?.parts.count, 1)
        XCTAssertEqual(request.contents.first?.parts.first?.text, "测试文本")
    }
    
    func testGeminiInlineDataCreation() throws {
        // 测试Gemini内联数据创建
        let testData = "base64encodeddata"
        let inlineData = GeminiInlineData(mimeType: "image/jpeg", data: testData)
        let imagePart = GeminiPart(inlineData: inlineData)
        
        XCTAssertEqual(imagePart.inlineData?.mimeType, "image/jpeg")
        XCTAssertEqual(imagePart.inlineData?.data, testData)
        XCTAssertNil(imagePart.text)
    }
    
    func testGeminiGenerationConfigDefaults() throws {
        // 测试Gemini生成配置默认值
        let defaultConfig = GeminiGenerationConfig.default
        
        XCTAssertEqual(defaultConfig.temperature, 0.7)
        XCTAssertEqual(defaultConfig.topK, 40)
        XCTAssertEqual(defaultConfig.topP, 0.95)
        XCTAssertEqual(defaultConfig.maxOutputTokens, 2048)
        
        let imageConfig = GeminiGenerationConfig.imageGeneration
        XCTAssertTrue(imageConfig.responseModalities?.contains("TEXT") == true)
        XCTAssertTrue(imageConfig.responseModalities?.contains("IMAGE") == true)
    }
    
    func testDishImageCreation() throws {
        // 测试DishImage模型创建
        let dishImage = DishImage(
            id: UUID(),
            title: "美味菜品",
            imageURL: "https://example.com/dish.jpg",
            thumbnailURL: "https://example.com/thumb.jpg",
            sourceURL: "https://example.com/source",
            width: 400,
            height: 300,
            menuItemName: "红烧肉",
            isLoaded: true
        )
        
        XCTAssertEqual(dishImage.title, "美味菜品")
        XCTAssertEqual(dishImage.imageURL, "https://example.com/dish.jpg")
        XCTAssertEqual(dishImage.menuItemName, "红烧肉")
        XCTAssertTrue(dishImage.isLoaded)
    }
    
    func testImageLoadingStateEquality() throws {
        // 测试ImageLoadingState枚举的相等性
        let idle1 = ImageLoadingState.idle
        let idle2 = ImageLoadingState.idle
        let loading = ImageLoadingState.loading
        
        XCTAssertTrue(idle1 == idle2)
        XCTAssertFalse(idle1 == loading)
        
        let testImages = [DishImage(
            id: UUID(),
            title: "Test",
            imageURL: "test.jpg",
            thumbnailURL: "thumb.jpg",
            sourceURL: "source",
            width: 100,
            height: 100,
            menuItemName: "test",
            isLoaded: false
        )]
        
        let loaded1 = ImageLoadingState.loaded(testImages)
        
        // Note: 这里可能需要根据ImageLoadingState的实际实现来调整
        XCTAssertFalse(loaded1 == loading)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
