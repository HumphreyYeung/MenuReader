# MenuReader API Debug Guide

## 现有的API服务调试指南

（原有内容保持不变）

---

## 🎨 新增功能：菜品图像生成API调试

### 功能概述
当Google搜索API成功但返回空结果时，系统会自动调用Gemini 2.0 Flash图像生成API作为后备方案，生成菜品图片。

### 触发条件
- ✅ Google搜索API调用成功
- ⭕ Google搜索返回空结果（不是失败）
- 🎯 自动调用图像生成API

### 技术细节

#### API模型
- **模型**: `gemini-2.0-flash-preview-image-generation`
- **端点**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-preview-image-generation:generateContent`
- **要求**: `responseModalities: ["TEXT", "IMAGE"]` **必须放在 generationConfig 内部**

#### App Bundle ID
- **Bundle ID**: `io.github.HumphreyYeung.MenuReader`
- **包含位置**: 所有API请求头中

### ✅ 正确的curl测试命令

#### 测试红烧肉（修复后的正确格式）
```bash
curl -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-preview-image-generation:generateContent?key=AIzaSyDgbnOFhQ8yF8uwE8NBqstMzFsIt2u1TRE" \
  -H "Content-Type: application/json" \
  -H "X-Ios-Bundle-Identifier: io.github.HumphreyYeung.MenuReader" \
  -d '{
    "contents": [
      {
        "parts": [
          {
            "text": "App Bundle ID: io.github.HumphreyYeung.MenuReader\n\nGenerate a high-quality, photorealistic image of the dish: 红烧肉\n\nRequirements:\n- Show a close-up view of the dish\n- Use clean, neutral background\n- Professional food photography style\n- High resolution and sharp details\n\nStyle: Professional food photography, clean presentation, appetizing appearance"
          }
        ],
        "role": "user"
      }
    ],
    "generationConfig": {
      "responseModalities": ["TEXT", "IMAGE"],
      "temperature": 0.7,
      "topK": 40,
      "topP": 0.95,
      "maxOutputTokens": 1024
    },
    "safetySettings": [
      {
        "category": "HARM_CATEGORY_HARASSMENT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE"
      },
      {
        "category": "HARM_CATEGORY_HATE_SPEECH", 
        "threshold": "BLOCK_MEDIUM_AND_ABOVE"
      },
      {
        "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE"
      },
      {
        "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE"
      }
    ]
  }'
```

#### 测试宫保鸡丁
```bash
curl -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-preview-image-generation:generateContent?key=AIzaSyDgbnOFhQ8yF8uwE8NBqstMzFsIt2u1TRE" \
  -H "Content-Type: application/json" \
  -H "X-Ios-Bundle-Identifier: io.github.HumphreyYeung.MenuReader" \
  -d '{
    "contents": [
      {
        "parts": [
          {
            "text": "App Bundle ID: io.github.HumphreyYeung.MenuReader\n\nGenerate a high-quality, photorealistic image of the dish: 宫保鸡丁\n\nRequirements:\n- Show a close-up view of the dish\n- Use clean, neutral background\n- Professional food photography style\n- High resolution and sharp details\n\nStyle: Professional food photography, clean presentation, appetizing appearance"
          }
        ],
        "role": "user"
      }
    ],
    "generationConfig": {
      "responseModalities": ["TEXT", "IMAGE"]
    }
  }'
```

#### 简化版测试（最小配置）
```bash
curl -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-preview-image-generation:generateContent?key=AIzaSyDgbnOFhQ8yF8uwE8NBqstMzFsIt2u1TRE" \
  -H "Content-Type: application/json" \
  -H "X-Ios-Bundle-Identifier: io.github.HumphreyYeung.MenuReader" \
  -d '{
    "contents": [
      {
        "parts": [
          {
            "text": "Generate a dish image: 麻婆豆腐"
          }
        ],
        "role": "user"
      }
    ],
    "generationConfig": {
      "responseModalities": ["TEXT", "IMAGE"]
    }
  }'
```

### 🔧 Swift代码修复

#### ✅ 修复后的模型结构
```swift
struct GeminiGenerationConfig: Codable {
    let responseModalities: [String]?  // ✅ 正确：在generationConfig内部
    // ... 其他字段
    
    static let imageGeneration = GeminiGenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
        stopSequences: nil,
        responseModalities: ["TEXT", "IMAGE"]  // ✅ 正确位置
    )
}

struct GeminiImageGenerationRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig?
    let safetySettings: [GeminiSafetySetting]?
    // ❌ 移除：let responseModalities: [String]  // 错误的根级别位置
}
```

### 测试步骤

#### 1. 准备环境
```bash
# API密钥已包含在curl命令中
export GEMINI_API_KEY="AIzaSyDgbnOFhQ8yF8uwE8NBqstMzFsIt2u1TRE"
```

#### 2. 测试图像生成
- 使用上面的curl命令进行测试
- 观察是否返回base64编码的图像数据

#### 3. 日志输出示例
```
🔍 [MenuAnalysisService] 搜索无结果，尝试生成图片: 红烧肉
🎨 [GeminiService] 开始生成菜品图片: 红烧肉
🔤 [GeminiService] 图像生成提示词已创建
📡 [GeminiService] 发送图像生成请求到 Gemini 2.0 Flash...
✅ [GeminiService] 收到图像生成响应
📸 [GeminiService] 图像数据获取成功，长度: XXXX 字符
✅ [GeminiService] 菜品图片生成完成: 红烧肉
✅ [MenuAnalysisService] 图片生成成功: 红烧肉
```

### 关键修复点

1. **✅ responseModalities位置修复**：
   - ❌ 错误：在请求根级别
   - ✅ 正确：在 `generationConfig` 内部

2. **✅ 使用预定义配置**：
   - 使用 `GeminiGenerationConfig.imageGeneration` 
   - 包含正确的 `responseModalities: ["TEXT", "IMAGE"]`

3. **✅ Bundle ID包含**：
   - 所有请求头都包含正确的Bundle ID
   - 格式：`X-Ios-Bundle-Identifier: io.github.HumphreyYeung.MenuReader`

### 图像生成提示词特点

#### 关键要求
- 菜品特写镜头
- 干净的中性背景（白色或浅色）
- 专业食物摄影风格
- 良好的照明效果
- 食物看起来新鲜诱人
- 无文字、标签或水印
- 高分辨率和清晰细节
- 菜品为主要焦点

#### 多语言支持
- 支持原始菜品名称和翻译名称
- 包含菜品描述和类别（如果可用）
- 保持菜系的真实外观

### 故障排除

#### 常见问题
1. **API密钥问题**
   - 错误：`缺少Gemini API密钥`
   - 解决：在 Info.plist 中设置 `GEMINI_API_KEY`

2. **网络请求失败**
   - 错误：`图片生成失败: 网络错误`
   - 解决：检查网络连接和API密钥有效性

3. **响应无图像数据**
   - 错误：`API响应中未包含图像数据`
   - 解决：检查请求格式和API模型可用性

#### 调试技巧
- 查看控制台日志中的详细输出
- 验证Bundle ID是否正确包含在请求中
- 检查API响应的完整性

### 性能注意事项
- 图像生成比搜索慢，作为后备方案使用
- 生成的图像以Base64 data URL格式存储
- 系统会优雅处理生成失败，不影响主流程

### 集成位置
- **GeminiService.swift**: 图像生成核心逻辑
- **MenuAnalysisService.swift**: 后备机制集成
- **NetworkService.swift**: API端点配置 