import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rectangle_detector_plugin/rectangle_detector_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rectangle Detector Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RectangleDetectorDemo(),
    );
  }
}

class RectangleDetectorDemo extends StatefulWidget {
  const RectangleDetectorDemo({super.key});

  @override
  State<RectangleDetectorDemo> createState() => _RectangleDetectorDemoState();
}

class _RectangleDetectorDemoState extends State<RectangleDetectorDemo> {
  final _rectangleDetectorPlugin = RectangleDetectorPlugin();
  List<RectangleFeature>? _detectedRectangles;
  bool _isDetecting = false;
  ui.Image? _image;
  double _imageWidth = 0;
  double _imageHeight = 0;
  String _statusMessage = '点击检测按钮开始检测矩形';

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  /// 加载图片资源
  Future<void> _loadImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/tv.jpeg');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      
      setState(() {
        _image = frameInfo.image;
        _imageWidth = frameInfo.image.width.toDouble();
        _imageHeight = frameInfo.image.height.toDouble();
      });
    } catch (e) {
      setState(() {
        _statusMessage = '加载图片失败: $e';
      });
    }
  }

  /// 检测矩形
  Future<void> _detectRectangles() async {
    if (_image == null) {
      setState(() {
        _statusMessage = '图片未加载完成';
      });
      return;
    }

    setState(() {
      _isDetecting = true;
      _statusMessage = '正在检测矩形...';
    });

    try {
      // 将图片转换为字节数组
      final ByteData data = await rootBundle.load('assets/images/tv.jpeg');
      final Uint8List imageBytes = data.buffer.asUint8List();

      // 调用插件检测单个矩形
      final rectangle = await _rectangleDetectorPlugin.detectRectangle(imageBytes);
      
      if (rectangle != null) {
        setState(() {
          _detectedRectangles = [rectangle];
          _isDetecting = false;
          _statusMessage = '检测完成，发现 1 个矩形\n'
              'TL: (${rectangle.topLeft.x.toStringAsFixed(1)}, ${rectangle.topLeft.y.toStringAsFixed(1)})\n'
              'TR: (${rectangle.topRight.x.toStringAsFixed(1)}, ${rectangle.topRight.y.toStringAsFixed(1)})\n'
              'BL: (${rectangle.bottomLeft.x.toStringAsFixed(1)}, ${rectangle.bottomLeft.y.toStringAsFixed(1)})\n'
              'BR: (${rectangle.bottomRight.x.toStringAsFixed(1)}, ${rectangle.bottomRight.y.toStringAsFixed(1)})';
        });
      } else {
        setState(() {
          _detectedRectangles = [];
          _isDetecting = false;
          _statusMessage = '未检测到矩形';
        });
      }
    } catch (e) {
      setState(() {
        _isDetecting = false;
        _statusMessage = '检测失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('矩形检测演示'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // 状态信息
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Text(
              _statusMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          
          // 检测按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isDetecting ? null : _detectRectangles,
              child: _isDetecting 
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('检测中...'),
                      ],
                    )
                  : const Text('检测矩形'),
            ),
          ),
          
          // 图片显示区域
          Expanded(
            child: _image == null
                ? const Center(child: CircularProgressIndicator())
                : InteractiveViewer(
                    child: Center(
                      child: CustomPaint(
                        painter: RectanglePainter(
                          image: _image!,
                          rectangles: _detectedRectangles,
                          imageWidth: _imageWidth,
                          imageHeight: _imageHeight,
                        ),
                        child: Container(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// 自定义画笔，用于绘制图片和检测到的矩形
class RectanglePainter extends CustomPainter {
  final ui.Image image;
  final List<RectangleFeature>? rectangles;
  final double imageWidth;
  final double imageHeight;

  RectanglePainter({
    required this.image,
    this.rectangles,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 计算图片在画布中的显示尺寸和位置
    final double aspectRatio = imageWidth / imageHeight;
    final double canvasAspectRatio = size.width / size.height;
    
    double displayWidth, displayHeight;
    double offsetX = 0, offsetY = 0;
    
    if (aspectRatio > canvasAspectRatio) {
      // 图片更宽，以宽度为准
      displayWidth = size.width;
      displayHeight = size.width / aspectRatio;
      offsetY = (size.height - displayHeight) / 2;
    } else {
      // 图片更高，以高度为准
      displayHeight = size.height;
      displayWidth = size.height * aspectRatio;
      offsetX = (size.width - displayWidth) / 2;
    }
    
    // 绘制图片
    final Rect imageRect = Rect.fromLTWH(offsetX, offsetY, displayWidth, displayHeight);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, imageWidth, imageHeight),
      imageRect,
      Paint(),
    );
    
    // 绘制检测到的矩形
    if (rectangles != null && rectangles!.isNotEmpty) {
      final Paint rectanglePaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      final Paint pointPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;
      
      for (final rectangle in rectangles!) {
        // 获取矩形的四个顶点
        final List<Offset> uiPoints = [
          // 转换坐标系：从图片坐标系转换到UI坐标系
          Offset(
            offsetX + (rectangle.topLeft.x / imageWidth) * displayWidth,
            offsetY + (rectangle.topLeft.y / imageHeight) * displayHeight,
          ),
          Offset(
            offsetX + (rectangle.topRight.x / imageWidth) * displayWidth,
            offsetY + (rectangle.topRight.y / imageHeight) * displayHeight,
          ),
          Offset(
            offsetX + (rectangle.bottomRight.x / imageWidth) * displayWidth,
            offsetY + (rectangle.bottomRight.y / imageHeight) * displayHeight,
          ),
          Offset(
            offsetX + (rectangle.bottomLeft.x / imageWidth) * displayWidth,
            offsetY + (rectangle.bottomLeft.y / imageHeight) * displayHeight,
          ),
        ];
        
        // 绘制矩形边框
        final Path path = Path();
        path.moveTo(uiPoints[0].dx, uiPoints[0].dy);
        for (int i = 1; i < uiPoints.length; i++) {
          path.lineTo(uiPoints[i].dx, uiPoints[i].dy);
        }
        path.close();
        canvas.drawPath(path, rectanglePaint);
        
        // 绘制角点
        for (final point in uiPoints) {
          canvas.drawCircle(point, 6, pointPaint);
        }
        
        // 绘制点坐标标签
        final List<String> labels = ['TL', 'TR', 'BR', 'BL'];
        for (int i = 0; i < uiPoints.length; i++) {
          final point = uiPoints[i];
          final textPainter = TextPainter(
            text: TextSpan(
              text: labels[i],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(
              point.dx - textPainter.width / 2,
              point.dy - textPainter.height / 2,
            ),
          );
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
