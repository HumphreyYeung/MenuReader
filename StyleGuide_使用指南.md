# MenuReader StyleGuide 使用指南

本文档说明如何在 MenuReader App 中使用新的样式系统，实现全局UI一致性和高效的样式管理。

## 🎨 样式系统概览

新的样式系统包含以下几个核心组件：

- **AppColors**: 色彩系统
- **AppFonts**: 字体系统  
- **AppSpacing**: 间距系统
- **AppIcons**: 图标系统
- **按钮样式**: PrimaryButtonStyle, SecondaryButtonStyle 等
- **卡片样式**: PrimaryCardModifier, SecondaryCardModifier 等

## 🔧 如何使用

### 1. 色彩使用

```swift
// ✅ 推荐使用
Text("菜单翻译")
    .foregroundColor(AppColors.primary)
    .background(AppColors.background)

// ✅ 使用便捷方法
VStack {
    // 内容
}
.appBackground() // 应用主背景色
.contentBackground() // 应用内容背景色
```

### 2. 字体使用

```swift
// ✅ 推荐使用
Text("菜单标题")
    .font(AppFonts.headline)

Text("菜品描述")
    .font(AppFonts.body)

Text("价格信息")
    .font(AppFonts.caption)
```

### 3. 间距使用

```swift
// ✅ 推荐使用基础间距
VStack(spacing: AppSpacing.m) {
    // 内容
}
.padding(AppSpacing.cardPadding)

// ✅ 使用便捷方法
VStack {
    // 内容
}
.standardScreenPadding() // 应用标准屏幕边距
.cardPadding() // 应用卡片内边距
```

### 4. 按钮样式

```swift
// ✅ 主要按钮
Button("拍照翻译") {
    // 动作
}
.primaryButtonStyle()

// ✅ 次要按钮（橙色边框）
Button("从相册选择") {
    // 动作
}
.secondaryButtonStyle()

// ✅ 强调按钮（橙色背景）
Button("立即翻译") {
    // 动作
}
.accentButtonStyle()

// ✅ 文本按钮
Button("跳过") {
    // 动作
}
.textButtonStyle()
```

### 5. 卡片样式

```swift
// ✅ 主要卡片（带阴影）
VStack {
    // 卡片内容
}
.primaryCardStyle()

// ✅ 次要卡片（边框样式）
VStack {
    // 卡片内容
}
.secondaryCardStyle()

// ✅ 菜品专用卡片
VStack {
    // 菜品信息
}
.dishCardStyle()
```

### 6. 图标使用

```swift
// ✅ 使用预定义图标
Image(systemName: AppIcons.camera)
    .primaryIconStyle() // 主要图标样式

Image(systemName: AppIcons.settings)
    .secondaryIconStyle() // 次要图标样式

Image(systemName: AppIcons.translate)
    .accentIconStyle(size: AppIcons.largeSize) // 强调图标样式
```

### 7. 组合样式

```swift
// ✅ 标准屏幕布局
VStack {
    // 屏幕内容
}
.standardScreenLayout() // 包含屏幕边距和背景色

// ✅ 标准内容布局
VStack {
    // 内容
}
.standardContentLayout() // 包含内边距、背景色和圆角
```

## 🚀 实际应用示例

### 示例1: 菜品卡片

```swift
struct DishCard: View {
    let dishName: String
    let description: String
    let price: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            // 菜品名称
            Text(dishName)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primary)
            
            // 菜品描述
            Text(description)
                .font(AppFonts.body)
                .foregroundColor(AppColors.secondaryText)
            
            // 价格
            HStack {
                Spacer()
                Text(price)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.accent)
            }
        }
        .dishCardStyle() // ✅ 应用菜品卡片样式
    }
}
```

### 示例2: 设置页面

```swift
struct SettingsView: View {
    var body: some View {
        VStack(spacing: AppSpacing.l) {
            // 标题
            Text("设置")
                .font(AppFonts.largeTitle)
                .foregroundColor(AppColors.primary)
            
            // 设置项
            VStack(spacing: AppSpacing.m) {
                SettingRow(
                    icon: AppIcons.language,
                    title: "语言设置",
                    action: {}
                )
                
                SettingRow(
                    icon: AppIcons.history,
                    title: "历史记录",
                    action: {}
                )
            }
            .secondaryCardStyle()
            
            Spacer()
        }
        .standardScreenLayout() // ✅ 应用标准屏幕布局
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .primaryIconStyle()
                
                Text(title)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.primary)
                
                Spacer()
                
                Image(systemName: AppIcons.chevronRight)
                    .secondaryIconStyle(size: AppIcons.smallSize)
            }
        }
        .textButtonStyle()
    }
}
```

## 📝 最佳实践

### 1. 全局修改
当需要调整整个App的颜色主题时，只需修改 `AppColors` 中的定义：

```swift
// 在 AppColors 中修改
static let accent = Color.blue // 将橙色改为蓝色
// 整个App的强调色都会更新
```

### 2. 组件级定制
对于特殊组件的样式，在该组件的文件中进行定制：

```swift
// 在具体的View文件中
struct SpecialButton: View {
    var body: some View {
        Button("特殊按钮") {
            // 动作
        }
        .font(AppFonts.button)
        .foregroundColor(.white)
        .padding(.horizontal, AppSpacing.xl) // 使用更大的内边距
        .background(AppColors.accent)
        .cornerRadius(AppSpacing.extraLargeCorner) // 使用更大的圆角
    }
}
```

### 3. 避免硬编码
```swift
// ❌ 避免硬编码
.padding(16)
.foregroundColor(.orange)
.font(.system(size: 17))

// ✅ 使用样式系统
.padding(AppSpacing.m)
.foregroundColor(AppColors.accent)
.font(AppFonts.button)
```

## 🎯 好处

1. **一致性**: 整个App使用统一的视觉语言
2. **效率**: 修改一个地方即可全局生效
3. **可维护性**: 样式集中管理，易于维护和更新
4. **响应性**: 基于苹果的动态字体系统，支持无障碍功能
5. **精致感**: 基于8点网格系统，确保视觉和谐

## 🔄 迁移现有代码

逐步将现有代码迁移到新的样式系统：

1. 优先处理通用组件（按钮、卡片等）
2. 然后处理颜色和字体
3. 最后处理间距和布局
4. 测试确保视觉效果正确

这样，您就可以在 MenuReader App 中享受系统化、高效的UI开发体验了！ 