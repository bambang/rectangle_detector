# Rectangle Detector

[![Pub Version](https://img.shields.io/pub/v/rectangle_detector.svg)](https://pub.dev/packages/rectangle_detector)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.19.0-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-%5E3.2.0-blue.svg)](https://dart.dev/)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS-blue.svg)](https://flutter.dev/)
[![Support](https://img.shields.io/badge/Support-Mobile%20%7C%20Desktop%20%7C%20Web-green.svg)](https://flutter.dev/)

A Flutter plugin based on native platforms that provides efficient rectangle feature point recognition functionality. Supports detecting rectangles from images and returning precise coordinates of four corner points.

---

## 🇨🇳 中文文档

一个基于原生平台的Flutter插件，提供高效的矩形特征点识别功能。支持从图像中检测矩形并返回精确的四个角点坐标。

## 功能特性

- 🔍 **高精度检测**：基于原生平台算法，提供准确的矩形识别
- 📱 **多平台支持**：支持 Android、iOS、macOS 和 Web 平台
- ⚡ **高性能**：原生实现，处理速度快
- 🎯 **灵活检测**：支持检测单个最大矩形或所有矩形
- 📐 **精确坐标**：返回矩形四个角点的精确坐标
- 🔄 **多种输入类型**：支持 Uint8List、ui.Image 和 ImageProvider 三种输入格式
- 🛠️ **易于集成**：简洁的 API 设计，快速集成到现有项目
- 🌍 **多语言支持**：支持中文和英文界面，自动保存语言偏好

## 支持平台

| 平台 | 支持状态 |
|------|----------|
| Android | ✅ |
| iOS | ✅ |
| macOS | ✅ |
| Web | ✅ |
| Windows | ❌ |
| Linux | ❌ |

## 演示效果

### Android 平台
![Android Demo](doc/images/demo-android.png)

### iOS 平台
![iOS Demo](doc/images/demo-ios.png)

### macOS 平台
![macOS Demo](doc/images/demo-macos.png)

### Web 平台
![Web Demo](doc/images/demo-web.png)

## 安装

在你的 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  rectangle_detector: ^1.0.4
  intl: ^0.19.0
  shared_preferences: ^2.2.2

flutter:
  generate: true
```

然后运行：

```bash
flutter pub get
flutter gen-l10n
```

## 使用方法

### 基本用法

```dart
import 'package:rectangle_detector/rectangle_detector.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

// 方法1: 使用字节数据检测矩形
Future<void> detectRectangleFromBytes(Uint8List imageData) async {
  final rectangle = await RectangleDetector.detectRectangle(imageData);
  
  if (rectangle != null) {
    print('检测到矩形:');
    print('左上角: ${rectangle.topLeft}');
    print('右上角: ${rectangle.topRight}');
    print('左下角: ${rectangle.bottomLeft}');
    print('右下角: ${rectangle.bottomRight}');
  } else {
    print('未检测到矩形');
  }
}

// 方法2: 使用 ui.Image 检测矩形
Future<void> detectRectangleFromUIImage(ui.Image image) async {
  final rectangle = await RectangleDetector.detectRectangleFromImage(image);
  
  if (rectangle != null) {
    print('从 ui.Image 检测到矩形: ${rectangle.toString()}');
  }
}

// 方法3: 使用 ImageProvider 检测矩形
Future<void> detectRectangleFromProvider(ImageProvider imageProvider) async {
  final rectangle = await RectangleDetector.detectRectangleFromProvider(imageProvider);
  
  if (rectangle != null) {
    print('从 ImageProvider 检测到矩形: ${rectangle.toString()}');
  }
}

// 检测所有矩形（支持三种输入类型）
Future<void> detectAllRectangles(Uint8List imageData) async {
  final rectangles = await RectangleDetector.detectAllRectangles(imageData);
  
  print('检测到 ${rectangles.length} 个矩形');
  for (int i = 0; i < rectangles.length; i++) {
    final rect = rectangles[i];
    print('矩形 ${i + 1}: ${rect.toString()}');
  }
}

// 从 ui.Image 检测所有矩形
Future<void> detectAllRectanglesFromImage(ui.Image image) async {
  final rectangles = await RectangleDetector.detectAllRectanglesFromImage(image);
  print('从 ui.Image 检测到 ${rectangles.length} 个矩形');
}

// 从 ImageProvider 检测所有矩形
Future<void> detectAllRectanglesFromProvider(ImageProvider provider) async {
  final rectangles = await RectangleDetector.detectAllRectanglesFromProvider(provider);
  print('从 ImageProvider 检测到 ${rectangles.length} 个矩形');
}

// 多语言支持示例
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/app_localizations.dart';

class MultilingualApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: RectangleDetectionPage(),
    );
  }
}
```

### 完整示例

```dart
import 'package:flutter/material.dart';
import 'package:rectangle_detector/rectangle_detector.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';

class RectangleDetectionPage extends StatefulWidget {
  @override
  _RectangleDetectionPageState createState() => _RectangleDetectionPageState();
}

class _RectangleDetectionPageState extends State<RectangleDetectionPage> {
  List<RectangleFeature> _detectedRectangles = [];
  bool _isDetecting = false;

  Future<void> _pickAndDetectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _isDetecting = true;
      });
      
      try {
        final imageBytes = await File(pickedFile.path).readAsBytes();
        final rectangles = await RectangleDetector.detectAllRectangles(imageBytes);
        
        setState(() {
          _detectedRectangles = rectangles;
          _isDetecting = false;
        });
      } catch (e) {
        setState(() {
          _isDetecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('检测失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('矩形检测示例'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _isDetecting ? null : _pickAndDetectImage,
            child: Text(_isDetecting ? '检测中...' : '选择图片并检测'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _detectedRectangles.length,
              itemBuilder: (context, index) {
                final rect = _detectedRectangles[index];
                return ListTile(
                  title: Text('矩形 ${index + 1}'),
                  subtitle: Text('左上: ${rect.topLeft}, 右下: ${rect.bottomRight}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## API 文档

### RectangleDetector

主要的检测器类，提供矩形检测功能。支持三种输入类型：`Uint8List`、`ui.Image` 和 `ImageProvider`。

#### 检测单个矩形的方法

##### `detectRectangle(Uint8List imageData)`

从字节数据检测图像中的最大矩形。

**参数：**
- `imageData`: 图像的字节数据 (Uint8List)

**返回值：**
- `Future<RectangleFeature?>`: 检测到的矩形特征点，如果没有检测到则返回 null

##### `detectRectangleFromImage(ui.Image image)`

从 ui.Image 对象检测图像中的最大矩形。

**参数：**
- `image`: Flutter 的 ui.Image 对象

**返回值：**
- `Future<RectangleFeature?>`: 检测到的矩形特征点，如果没有检测到则返回 null

##### `detectRectangleFromProvider(ImageProvider imageProvider)`

从 ImageProvider 检测图像中的最大矩形。

**参数：**
- `imageProvider`: Flutter 的 ImageProvider 对象（如 AssetImage、NetworkImage 等）

**返回值：**
- `Future<RectangleFeature?>`: 检测到的矩形特征点，如果没有检测到则返回 null

#### 检测所有矩形的方法

##### `detectAllRectangles(Uint8List imageData)`

从字节数据检测图像中的所有矩形。

**参数：**
- `imageData`: 图像的字节数据 (Uint8List)

**返回值：**
- `Future<List<RectangleFeature>>`: 所有检测到的矩形特征点列表

##### `detectAllRectanglesFromImage(ui.Image image)`

从 ui.Image 对象检测图像中的所有矩形。

**参数：**
- `image`: Flutter 的 ui.Image 对象

**返回值：**
- `Future<List<RectangleFeature>>`: 所有检测到的矩形特征点列表

##### `detectAllRectanglesFromProvider(ImageProvider imageProvider)`

从 ImageProvider 检测图像中的所有矩形。

**参数：**
- `imageProvider`: Flutter 的 ImageProvider 对象（如 AssetImage、NetworkImage 等）

**返回值：**
- `Future<List<RectangleFeature>>`: 所有检测到的矩形特征点列表

### RectangleFeature

表示矩形特征点的数据类。

#### 属性

- `topLeft`: 左上角坐标 (Point<double>)
- `topRight`: 右上角坐标 (Point<double>)
- `bottomLeft`: 左下角坐标 (Point<double>)
- `bottomRight`: 右下角坐标 (Point<double>)

#### 方法

##### `fromMap(Map<String, dynamic> map)`

从 Map 数据创建 RectangleFeature 对象。

## 多语言支持

示例应用支持中文和英文两种语言界面：

### 语言切换
- 点击 AppBar 右侧的 🌐 图标
- 选择 "中文" 或 "English"
- 语言偏好会自动保存，下次启动时使用上次选择的语言

### 支持的语言
- 🇨🇳 **中文**：默认语言，完整的中文界面
- 🇺🇸 **English**：完整的英文界面

### 本地化内容
- 应用标题和按钮文字
- 状态消息和错误提示
- 控制面板和设置选项
- 检测结果和坐标显示

## 示例应用

本插件包含一个完整的示例应用，展示了如何：

- 选择图片进行检测
- 显示检测结果
- 在图像上绘制检测到的矩形
- 处理检测错误
- 多语言界面切换

运行示例：

```bash
cd example
flutter run
```

## 注意事项

1. **图像格式**：支持常见的图像格式（JPEG、PNG等）
2. **性能**：大图像可能需要较长的处理时间
3. **精度**：检测精度取决于图像质量和矩形的清晰度
4. **内存**：处理大图像时注意内存使用

## 常见问题

### Q: 为什么检测不到矩形？
A: 可能的原因：
- 图像中没有明显的矩形
- 图像质量较低或模糊
- 矩形边缘不够清晰
- 图像尺寸过小

### Q: 如何提高检测精度？
A: 建议：
- 使用高质量、清晰的图像
- 确保矩形边缘对比度足够
- 避免图像过度压缩
- 适当的图像尺寸（不要太小）

### Q: 支持实时检测吗？
A: 当前版本主要针对静态图像检测，实时检测功能将在后续版本中考虑添加。

### Q: 如何切换语言？
A: 在示例应用中，点击 AppBar 右侧的 🌐 图标，选择 "中文" 或 "English"。语言偏好会自动保存。

### Q: 支持哪些语言？
A: 目前支持中文（默认）和英文两种语言界面。

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

---

## 🇺🇸 English Documentation

A Flutter plugin based on native platforms that provides efficient rectangle feature point recognition functionality. Supports detecting rectangles from images and returning precise coordinates of four corner points.

## Features

- 🔍 **High Precision Detection**: Based on native platform algorithms, provides accurate rectangle recognition
- 📱 **Multi-platform Support**: Supports Android, iOS, macOS and Web platforms
- ⚡ **High Performance**: Native implementation with fast processing speed
- 🎯 **Flexible Detection**: Supports detecting single largest rectangle or all rectangles
- 📐 **Precise Coordinates**: Returns precise coordinates of four corner points of rectangles
- 🔄 **Multiple Input Types**: Supports three input formats: Uint8List, ui.Image and ImageProvider
- 🛠️ **Easy Integration**: Simple API design for quick integration into existing projects
- 🌍 **Multilingual Support**: Supports Chinese and English interface with automatic language preference saving

## Supported Platforms

| Platform | Support Status |
|----------|----------------|
| Android  | ✅ |
| iOS      | ✅ |
| macOS    | ✅ |
| Web      | ✅ |
| Windows  | ❌ |
| Linux    | ❌ |

## Demo Results

### Android Platform
![Android Demo](doc/images/demo-android.png)

### iOS Platform
![iOS Demo](doc/images/demo-ios.png)

### macOS Platform
![macOS Demo](doc/images/demo-macos.png)

### Web Platform
![Web Demo](doc/images/demo-web.png)

## Installation

Add the dependencies to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  rectangle_detector: ^1.0.4
  intl: ^0.19.0
  shared_preferences: ^2.2.2

flutter:
  generate: true
```

Then run:

```bash
flutter pub get
flutter gen-l10n
```

## Usage

### Basic Usage

```dart
import 'package:rectangle_detector/rectangle_detector.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

// Method 1: Detect rectangle using byte data
Future<void> detectRectangleFromBytes(Uint8List imageData) async {
  final rectangle = await RectangleDetector.detectRectangle(imageData);
  
  if (rectangle != null) {
    print('Rectangle detected:');
    print('Top Left: ${rectangle.topLeft}');
    print('Top Right: ${rectangle.topRight}');
    print('Bottom Left: ${rectangle.bottomLeft}');
    print('Bottom Right: ${rectangle.bottomRight}');
  } else {
    print('No rectangle detected');
  }
}

// Method 2: Detect rectangle using ui.Image
Future<void> detectRectangleFromUIImage(ui.Image image) async {
  final rectangle = await RectangleDetector.detectRectangleFromImage(image);
  
  if (rectangle != null) {
    print('Rectangle detected from ui.Image: ${rectangle.toString()}');
  }
}

// Method 3: Detect rectangle using ImageProvider
Future<void> detectRectangleFromProvider(ImageProvider imageProvider) async {
  final rectangle = await RectangleDetector.detectRectangleFromProvider(imageProvider);
  
  if (rectangle != null) {
    print('Rectangle detected from ImageProvider: ${rectangle.toString()}');
  }
}

// Detect all rectangles (supports three input types)
Future<void> detectAllRectangles(Uint8List imageData) async {
  final rectangles = await RectangleDetector.detectAllRectangles(imageData);
  
  print('Detected ${rectangles.length} rectangles');
  for (int i = 0; i < rectangles.length; i++) {
    final rect = rectangles[i];
    print('Rectangle ${i + 1}: ${rect.toString()}');
  }
}

// Detect all rectangles from ui.Image
Future<void> detectAllRectanglesFromImage(ui.Image image) async {
  final rectangles = await RectangleDetector.detectAllRectanglesFromImage(image);
  print('Detected ${rectangles.length} rectangles from ui.Image');
}

// Detect all rectangles from ImageProvider
Future<void> detectAllRectanglesFromProvider(ImageProvider provider) async {
  final rectangles = await RectangleDetector.detectAllRectanglesFromProvider(provider);
  print('Detected ${rectangles.length} rectangles from ImageProvider');
}

// Multilingual support example
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/app_localizations.dart';

class MultilingualApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: RectangleDetectionPage(),
    );
  }
}
```

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:rectangle_detector/rectangle_detector.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';

class RectangleDetectionPage extends StatefulWidget {
  @override
  _RectangleDetectionPageState createState() => _RectangleDetectionPageState();
}

class _RectangleDetectionPageState extends State<RectangleDetectionPage> {
  List<RectangleFeature> _detectedRectangles = [];
  bool _isDetecting = false;

  Future<void> _pickAndDetectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _isDetecting = true;
      });
      
      try {
        final imageBytes = await File(pickedFile.path).readAsBytes();
        final rectangles = await RectangleDetector.detectAllRectangles(imageBytes);
        
        setState(() {
          _detectedRectangles = rectangles;
          _isDetecting = false;
        });
      } catch (e) {
        setState(() {
          _isDetecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Detection failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rectangle Detection Example'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _isDetecting ? null : _pickAndDetectImage,
            child: Text(_isDetecting ? 'Detecting...' : 'Select Image and Detect'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _detectedRectangles.length,
              itemBuilder: (context, index) {
                final rect = _detectedRectangles[index];
                return ListTile(
                  title: Text('Rectangle ${index + 1}'),
                  subtitle: Text('Top Left: ${rect.topLeft}, Bottom Right: ${rect.bottomRight}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## API Documentation

### RectangleDetector

The main detector class that provides rectangle detection functionality. Supports three input types: `Uint8List`, `ui.Image` and `ImageProvider`.

#### Methods for detecting single rectangle

##### `detectRectangle(Uint8List imageData)`

Detects the largest rectangle in the image from byte data.

**Parameters:**
- `imageData`: Image byte data (Uint8List)

**Returns:**
- `Future<RectangleFeature?>`: Detected rectangle feature points, returns null if no rectangle is detected

##### `detectRectangleFromImage(ui.Image image)`

Detects the largest rectangle in the image from ui.Image object.

**Parameters:**
- `image`: Flutter's ui.Image object

**Returns:**
- `Future<RectangleFeature?>`: Detected rectangle feature points, returns null if no rectangle is detected

##### `detectRectangleFromProvider(ImageProvider imageProvider)`

Detects the largest rectangle in the image from ImageProvider.

**Parameters:**
- `imageProvider`: Flutter's ImageProvider object (such as AssetImage, NetworkImage, etc.)

**Returns:**
- `Future<RectangleFeature?>`: Detected rectangle feature points, returns null if no rectangle is detected

#### Methods for detecting all rectangles

##### `detectAllRectangles(Uint8List imageData)`

Detects all rectangles in the image from byte data.

**Parameters:**
- `imageData`: Image byte data (Uint8List)

**Returns:**
- `Future<List<RectangleFeature>>`: List of all detected rectangle feature points

##### `detectAllRectanglesFromImage(ui.Image image)`

Detects all rectangles in the image from ui.Image object.

**Parameters:**
- `image`: Flutter's ui.Image object

**Returns:**
- `Future<List<RectangleFeature>>`: List of all detected rectangle feature points

##### `detectAllRectanglesFromProvider(ImageProvider imageProvider)`

Detects all rectangles in the image from ImageProvider.

**Parameters:**
- `imageProvider`: Flutter's ImageProvider object (such as AssetImage, NetworkImage, etc.)

**Returns:**
- `Future<List<RectangleFeature>>`: List of all detected rectangle feature points

### RectangleFeature

Data class representing rectangle feature points.

#### Properties

- `topLeft`: Top-left corner coordinates (Point<double>)
- `topRight`: Top-right corner coordinates (Point<double>)
- `bottomLeft`: Bottom-left corner coordinates (Point<double>)
- `bottomRight`: Bottom-right corner coordinates (Point<double>)

#### Methods

##### `fromMap(Map<String, dynamic> map)`

Creates a RectangleFeature object from Map data.

## Multilingual Support

The example application supports both Chinese and English language interfaces:

### Language Switching
- Tap the 🌐 icon in the AppBar
- Choose "中文" or "English"
- Language preference is automatically saved and used on next app launch

### Supported Languages
- 🇨🇳 **Chinese**: Default language with complete Chinese interface
- 🇺🇸 **English**: Complete English interface

### Localized Content
- App title and button text
- Status messages and error prompts
- Control panel and settings options
- Detection results and coordinate display

## Example Application

This plugin includes a complete example application that demonstrates how to:

- Select images for detection
- Display detection results
- Draw detected rectangles on images
- Handle detection errors
- Switch between multilingual interfaces

Run the example:

```bash
cd example
flutter run
```

## Notes

1. **Image Format**: Supports common image formats (JPEG, PNG, etc.)
2. **Performance**: Large images may require longer processing time
3. **Accuracy**: Detection accuracy depends on image quality and rectangle clarity
4. **Memory**: Pay attention to memory usage when processing large images

## FAQ

### Q: Why can't rectangles be detected?
A: Possible reasons:
- No obvious rectangles in the image
- Low image quality or blur
- Rectangle edges are not clear enough
- Image size is too small

### Q: How to improve detection accuracy?
A: Recommendations:
- Use high-quality, clear images
- Ensure sufficient contrast for rectangle edges
- Avoid excessive image compression
- Appropriate image size (not too small)

### Q: Does it support real-time detection?
A: The current version mainly focuses on static image detection. Real-time detection functionality will be considered for future versions.

### Q: How to switch languages?
A: In the example app, tap the 🌐 icon in the AppBar and choose "中文" or "English". Language preference is automatically saved.

### Q: What languages are supported?
A: Currently supports Chinese (default) and English language interfaces.

## Contributing

Issues and Pull Requests are welcome!

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

