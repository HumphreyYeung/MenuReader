# MenuReader项目依赖管理配置

## Swift Package Manager依赖项

本项目使用Swift Package Manager (SPM) 管理第三方依赖。以下是推荐的核心依赖项：

### 1. 网络请求处理
- **Alamofire**
  - 仓库URL: `https://github.com/Alamofire/Alamofire.git`
  - 版本要求: `~> 5.6.0`
  - 用途: API通信、HTTP请求处理、响应拦截

### 2. 图片处理和缓存
- **SDWebImage**
  - 仓库URL: `https://github.com/SDWebImage/SDWebImage.git`
  - 版本要求: `~> 5.12.0`
  - 用途: 异步图片加载、缓存管理、图片处理

### 3. 自动布局(可选但推荐)
- **SnapKit**
  - 仓库URL: `https://github.com/SnapKit/SnapKit.git`
  - 版本要求: `~> 5.0.0`
  - 用途: 声明式约束编程、UI布局简化

## 添加依赖的步骤

### 通过Xcode界面添加:
1. 打开MenuReader.xcodeproj
2. 选择项目根节点"MenuReader"
3. 在"Package Dependencies"选项卡中点击"+"
4. 输入上述仓库URL
5. 选择合适的版本规则
6. 点击"Add Package"
7. 在目标选择界面选择"MenuReader"主target

### 验证安装:
```swift
// 在相关文件中添加import语句验证
import Alamofire
import SDWebImage
import SnapKit
```

## 项目设置
- **最低iOS版本**: iOS 16.6
- **Swift版本**: 5.0
- **Xcode版本**: 16.3+

## 注意事项
1. 所有依赖项均支持iOS 16.6+
2. 建议定期更新到稳定版本
3. 新增依赖前请先评估必要性
4. 测试target和UI测试target可根据需要添加相关依赖

## 状态
- [x] 项目支持SPM
- [x] 基础配置完成
- [ ] 核心依赖添加 (需要通过Xcode界面完成)
- [ ] 验证依赖正常工作 