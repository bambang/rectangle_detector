## 1.0.0

### 🎉 重大更新

* **新增多种输入类型支持**：现在支持 `Uint8List`、`ui.Image` 和 `ImageProvider` 三种输入格式
* **新增便捷方法**：
  - `detectRectangleFromImage(ui.Image image)` - 从 ui.Image 检测矩形
  - `detectRectangleFromProvider(ImageProvider provider)` - 从 ImageProvider 检测矩形
  - `detectAllRectanglesFromImage(ui.Image image)` - 从 ui.Image 检测所有矩形
  - `detectAllRectanglesFromProvider(ImageProvider provider)` - 从 ImageProvider 检测所有矩形
* **向后兼容**：保持原有 API 不变，确保现有代码无需修改
* **完善文档**：更新 README 和 API 文档，添加详细的使用示例
* **优化性能**：内部图像转换优化，提升处理效率

### 🔧 技术改进

* 添加 `dart:ui`、`dart:async`、`flutter/services.dart` 和 `flutter/widgets.dart` 依赖
* 实现图像格式自动转换功能
* 增强错误处理和参数验证
* 完善中文注释和文档

## 0.0.1

### 🚀 初始发布

* 实现矩形特征点位识别功能
* 支持多平台：Android、iOS、macOS、Web
* 提供原生平台接口调用
* 包含完整的示例应用
* 基于Flutter插件架构设计
* 支持检测单个最大矩形和所有矩形
* 返回精确的四个角点坐标
