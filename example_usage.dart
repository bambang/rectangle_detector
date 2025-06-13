import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:rectangle_detector/rectangle_detector.dart';

/// 矩形检测插件使用示例
void main() async {
  // 示例：从文件读取图片
  // final file = File('path/to/your/image.jpg');
  // final imageData = await file.readAsBytes();

  // 示例图片数据（实际使用时替换为真实的图片字节数据）
  final Uint8List imageData = Uint8List(0); // 这里应该是真实的图片数据

  try {
    // 检测单个矩形（最大的矩形）
    final rectangle = await RectangleDetector.detectRectangle(imageData);
    if (rectangle != null) {
      developer.log('检测到矩形:');
      developer.log('左上角: ${rectangle.topLeft}');
      developer.log('右上角: ${rectangle.topRight}');
      developer.log('左下角: ${rectangle.bottomLeft}');
      developer.log('右下角: ${rectangle.bottomRight}');
    } else {
      developer.log('未检测到矩形');
    }

    // 检测所有矩形
    final allRectangles = await RectangleDetector.detectAllRectangles(
      imageData,
    );
    developer.log('\n检测到 ${allRectangles.length} 个矩形:');
    for (int i = 0; i < allRectangles.length; i++) {
      final rect = allRectangles[i];
      developer.log('矩形 ${i + 1}: $rect');
    }
  } catch (e) {
    developer.log('检测过程中发生错误: $e', level: 1000); // 错误级别
  }
}

/// 在Flutter应用中的使用示例
///
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'package:image_picker/image_picker.dart';
/// import 'package:rectangle_detector/rectangle_detector.dart';
///
/// class RectangleDetectionPage extends StatefulWidget {
///   @override
///   _RectangleDetectionPageState createState() => _RectangleDetectionPageState();
/// }
///
/// class _RectangleDetectionPageState extends State<RectangleDetectionPage> {
///   RectangleFeature? _detectedRectangle;
///
///   Future<void> _pickAndDetectImage() async {
///     final picker = ImagePicker();
///     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
///
///     if (pickedFile != null) {
///       final imageData = await pickedFile.readAsBytes();
///       final rectangle = await RectangleDetector.detectRectangle(imageData);
///
///       setState(() {
///         _detectedRectangle = rectangle;
///       });
///     }
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: Text('矩形检测')),
///       body: Column(
///         children: [
///           ElevatedButton(
///             onPressed: _pickAndDetectImage,
///             child: Text('选择图片并检测矩形'),
///           ),
///           if (_detectedRectangle != null)
///             Padding(
///               padding: EdgeInsets.all(16),
///               child: Text('检测结果: $_detectedRectangle'),
///             ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
