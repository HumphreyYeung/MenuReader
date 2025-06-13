# Gemini API 调试和修复指南

## 修复内容总结

我们已经对您的Gemini API调用进行了以下修复：

### 1. 🔧 修复模型版本不一致问题
- **问题**: 代码中硬编码了 `gemini-1.5-flash`，但配置默认为 `gemini-2.0-flash`
- **解决**: 移除了硬编码的baseURL，现在使用APIConfig中的动态配置
- **影响**: 确保使用最新的模型版本

### 2. 📊 增强调试信息
- **新增**: API配置检查（密钥长度、模型版本、Base URL）
- **新增**: 响应为空时的详细错误分析
- **新增**: 安全过滤器检测和处理
- **改进**: 更详细的日志输出

### 3. 🛡️ 增强错误处理
- **新增**: 安全过滤器阻止检测
- **新增**: API密钥验证
- **新增**: 多层次的文本解析备用方案

### 4. 🔄 新增测试方法
- **新增**: `validateConfiguration()` - 验证API配置
- **新增**: `testWithSimplePrompt()` - 简单图片描述测试
- **新增**: `fullConnectionTest()` - 完整连接测试
- **新增**: `analyzeMenuWithSimplePrompt()` - 简化提示词的菜单分析

## 使用调试工具

### 1. 快速诊断
在您的ViewControllers中添加这个调用来运行完整诊断：

```swift
Task {
    await APITestHelper.runDiagnostics()
}
```

### 2. 测试图片分析
```swift
Task {
    await APITestHelper.testImageAnalysis(with: yourImage)
}
```

### 3. 单独测试API连接
```swift
Task {
    let result = await GeminiService.shared.fullConnectionTest()
    print(result.message)
}
```

## 可能的问题和解决方案

### 问题1: "未识别出菜品"
**可能原因**:
1. API密钥无效或过期
2. 图片被安全过滤器阻止
3. 网络连接问题
4. Gemini API服务暂时不可用

**调试步骤**:
1. 运行 `APITestHelper.runDiagnostics()`
2. 检查控制台输出的详细调试信息
3. 尝试不同的图片（更清晰、内容更简单）
4. 使用简化提示词测试: `analyzeMenuWithSimplePrompt()`

### 问题2: API连接失败
**检查清单**:
- [ ] API密钥是否正确设置在环境变量或Info.plist中
- [ ] API密钥长度是否大于30个字符
- [ ] 网络连接是否正常
- [ ] Gemini API服务状态（访问 https://status.google.com）

### 问题3: 安全过滤器阻止
**解决方案**:
1. 尝试使用更清晰、内容更明确的菜单图片
2. 避免包含可能被误判为敏感内容的图片
3. 检查图片是否过于模糊或包含非菜单内容

## 最佳实践

### 1. 图片质量要求
- 分辨率: 建议800x600以上
- 格式: JPEG（压缩质量0.8）
- 内容: 清晰的菜单文字，避免倾斜或模糊

### 2. 错误处理
```swift
do {
    let result = try await GeminiService.shared.analyzeMenuImage(image)
    // 处理成功结果
} catch let error as GeminiError {
    switch error {
    case .invalidImage:
        // 处理无效图片
    case .invalidResponse:
        // 处理API响应问题
    case .networkError(let message):
        // 处理网络错误
        print("网络错误: \(message)")
    }
} catch {
    // 处理其他错误
    print("未知错误: \(error)")
}
```

### 3. 渐进式测试
1. 先测试简单的文本API调用
2. 再测试简单的图片描述
3. 最后测试复杂的菜单分析

## 控制台日志解读

### 正常情况
```
🔍 Gemini API 完整调试信息:
=== API配置检查 ===
API Key长度: 45
使用模型: gemini-2.0-flash
Base URL: https://generativelanguage.googleapis.com/v1beta/models
=== 响应分析 ===
Response candidates count: 1
Extracted text: '宫保鸡丁：¥28...'
Text length: 156
📝 使用简单文本解析，识别到 3 个菜品
```

### 问题情况
```
❌ API响应为空，检查原因:
  - Finish reason: SAFETY
  ⚠️ 内容被安全过滤器阻止
```

## 联系支持

如果问题仍然存在，请提供以下信息：
1. 完整的控制台调试日志
2. API诊断结果
3. 使用的图片示例
4. 错误重现步骤

## 版本信息
- 修复日期: 2025-01-28
- Gemini API版本: v1beta
- 推荐模型: gemini-2.0-flash 