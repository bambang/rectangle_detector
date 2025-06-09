# Android 端矩形检测实现说明

## 概述

Android 端的矩形检测功能基于 OpenCV 4.8.0 实现，提供了与 iOS 端一致的接口和数据格式。

## 功能特性

- **单矩形检测**: `detectRectangle()` - 检测图像中最大的矩形
- **多矩形检测**: `detectAllRectangles()` - 检测图像中所有矩形
- **自动 OpenCV 初始化**: 插件会自动处理 OpenCV 的初始化
- **内存管理**: 自动释放 OpenCV Mat 对象，避免内存泄漏

## 技术实现

### 核心算法流程

1. **图像预处理**
   - 转换为灰度图像
   - 高斯模糊去噪
   - Canny 边缘检测
   - 形态学操作（闭运算）

2. **轮廓检测**
   - 使用 `findContours` 查找外部轮廓
   - 多边形近似 (`approxPolyDP`)
   - 筛选四边形轮廓

3. **矩形验证**
   - 验证对边长度是否相等
   - 过滤面积过小的轮廓
   - 按面积排序

4. **顶点排序**
   - 按照 iOS 端一致的顺序：左上、右上、右下、左下

### 关键类说明

#### RectangleDetector.kt
- `detectRectangle()`: 检测单个最大矩形
- `detectAllRectangles()`: 检测所有矩形
- `findLargestRectangle()`: 查找最大矩形轮廓
- `approximateToRectangle()`: 轮廓近似为矩形
- `isValidRectangle()`: 验证矩形有效性
- `sortRectanglePoints()`: 顶点排序

#### RectangleDetectorPlugin.kt
- Flutter 方法通道处理
- OpenCV 初始化管理
- 图像数据转换
- 错误处理

## 依赖配置

### 推荐的第三方OpenCV依赖
```gradle
dependencies {
    implementation 'com.quickbirdstudios:opencv:4.5.1'
}
```

这个第三方依赖包装了OpenCV 4.5.1，可以直接通过Maven使用，避免了手动集成的复杂性。

### 备选方案：手动集成OpenCV SDK
如果第三方依赖不满足需求，可以参考 `OPENCV_SETUP.md` 文件中的详细步骤来手动集成OpenCV SDK。

## 数据格式

### 输入
- `imageData`: `ByteArray` - 图像的字节数据

### 输出格式

#### 单矩形检测返回格式
```kotlin
{
  "topLeft": {"x": 100.0, "y": 50.0},
  "topRight": {"x": 300.0, "y": 55.0},
  "bottomRight": {"x": 295.0, "y": 200.0},
  "bottomLeft": {"x": 105.0, "y": 195.0}
}
```

#### 多矩形检测返回格式
```kotlin
[
  {
    "topLeft": {"x": 100.0, "y": 50.0},
    "topRight": {"x": 300.0, "y": 55.0},
    "bottomRight": {"x": 295.0, "y": 200.0},
    "bottomLeft": {"x": 105.0, "y": 195.0}
  },
  // ... 更多矩形
]
```

## 错误处理

- `OPENCV_NOT_INITIALIZED`: OpenCV 未初始化
- `INVALID_ARGUMENT`: 参数无效
- `INVALID_IMAGE`: 图像解码失败
- `DETECTION_ERROR`: 检测过程中发生错误

## 性能优化

1. **内存管理**: 及时释放 Mat 对象
2. **参数调优**: 可调整 Canny 阈值、形态学核大小等参数
3. **面积过滤**: 过滤面积小于 1000 像素的轮廓
4. **近似精度**: 使用 2% 的周长作为近似精度

## 故障排除

### 矩形检测准确性问题

**问题描述：** 检测到的矩形坐标不正确，例如点位置混乱或形状不合理。

**解决方案：** 已在v1.1.0中修复了以下问题：

1. **点排序算法优化：** 改进了矩形顶点的排序逻辑，使用基于坐标的几何方法替代角度排序
2. **图像预处理增强：** 添加了自适应阈值处理，提高边缘检测效果
3. **验证逻辑加强：** 增加了面积、角度和边长比例的验证，过滤无效检测结果
4. **参数优化：** 调整了Canny边缘检测和形态学操作的参数

**检测结果格式：**
```json
{
  "topLeft": {"x": 100.0, "y": 50.0},
  "topRight": {"x": 300.0, "y": 55.0},
  "bottomRight": {"x": 295.0, "y": 200.0},
  "bottomLeft": {"x": 105.0, "y": 195.0}
}
```

### OpenCV 集成问题

**问题：** 构建时出现 "Unresolved reference 'Imgproc'" 或 "Unresolved reference 'Mat'" 错误

**原因：** OpenCV 依赖未正确配置

**解决方案：** 
1. **推荐方案：** 使用第三方 OpenCV 依赖
   ```gradle
   dependencies {
       implementation 'com.quickbirdstudios:opencv:4.5.1'
   }
   ```

2. **备选方案：** 手动集成 OpenCV SDK
   - 参考 `OPENCV_SETUP.md` 文件
   - 下载 OpenCV Android SDK
   - 将 OpenCV 作为模块导入项目

### 常见构建错误

1. **Gradle 同步失败**: 检查 OpenCV 模块配置
2. **找不到 OpenCV 类**: 确认模块依赖已正确添加
3. **运行时初始化失败**: 检查 OpenCV 库加载逻辑

## 使用注意事项

1. **OpenCV 集成**: 必须手动集成 OpenCV SDK，不能使用 Maven 依赖
2. **OpenCV 初始化**: 插件会自动处理，无需手动初始化
3. **图像格式**: 支持常见的图像格式（JPEG、PNG 等）
4. **坐标系**: 返回的坐标基于原始图像尺寸
5. **检测精度**: 适用于文档、卡片等规则矩形物体

## 与 iOS 端的兼容性

- 接口名称完全一致
- 数据格式完全一致
- 顶点排序规则一致
- 错误处理机制一致

这确保了跨平台的一致性体验。