import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' show Point;

import 'package:flutter/services.dart';
import 'package:rectangle_detector/rectangle_detector.dart';
import 'package:image_picker/image_picker.dart';

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
  List<RectangleFeature> _detectedRectangles = [];
  bool _isDetecting = false;
  ui.Image? _image;
  double _imageWidth = 0;
  double _imageHeight = 0;
  String _statusMessage = '请选择一张图片开始检测矩形';
  final ImagePicker _picker = ImagePicker();
  bool _isPanelExpanded = false;
  bool _showOnlyLargestRectangle = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultImage();
  }
  
  /// 加载默认测试图片
  Future<void> _loadDefaultImage() async {
    try {
      // 从assets加载默认图片
      final ByteData data = await rootBundle.load('assets/images/tv.jpeg');
      final Uint8List bytes = data.buffer.asUint8List();
      
      // 解码图片
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      
      setState(() {
        _image = frameInfo.image;
        _imageWidth = frameInfo.image.width.toDouble();
        _imageHeight = frameInfo.image.height.toDouble();
        _statusMessage = '已加载默认测试图片，点击检测按钮开始检测矩形';
        _detectedRectangles = []; // 清除之前的检测结果
      });
    } catch (e) {
      setState(() {
        _statusMessage = '默认图片加载失败: $e';
      });
    }
  }

  /// 选择图片
  /// 移除尺寸和质量限制，保持原始图片质量以确保检测结果一致性
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 3840,  // 4K分辨率
        maxHeight: 3840,
        imageQuality: 100,
      );
      
      if (pickedFile != null) {
        // 使用 XFile 的 readAsBytes 方法，兼容 Web 平台
        final Uint8List bytes = await pickedFile.readAsBytes();
        
        // 解码图片
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        
        setState(() {
          _image = frameInfo.image;
          _imageWidth = frameInfo.image.width.toDouble();
          _imageHeight = frameInfo.image.height.toDouble();
          _statusMessage = '图片加载完成，点击检测按钮开始检测矩形';
          _detectedRectangles = []; // 清除之前的检测结果
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '图片选择失败: $e';
      });
    }
  }

  /// 检测矩形
  Future<void> _detectRectangles() async {
    if (_image == null) {
      setState(() {
        _statusMessage = '请先选择一张图片';
      });
      return;
    }
    
    setState(() {
      _isDetecting = true;
      _statusMessage = '正在检测矩形...';
    });

    try {
      // 将图片转换为字节数组
      final ByteData? byteData = await _image!.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        setState(() {
          _isDetecting = false;
          _statusMessage = '图片转换失败';
        });
        return;
      }
      
      final Uint8List imageBytes = byteData.buffer.asUint8List();
      
      // 调用插件检测矩形
       final List<RectangleFeature> rectangles = await RectangleDetector.detectAllRectangles(imageBytes);
      
      if (rectangles.isNotEmpty) {
        setState(() {
          _detectedRectangles = rectangles;
          _isDetecting = false;
          _statusMessage = '检测到 ${rectangles.length} 个矩形:\n' +
              rectangles.map((rectangle) => 
                'TL: (${rectangle.topLeft.x.toStringAsFixed(1)}, ${rectangle.topLeft.y.toStringAsFixed(1)})\n' +
                'TR: (${rectangle.topRight.x.toStringAsFixed(1)}, ${rectangle.topRight.y.toStringAsFixed(1)})\n' +
                'BL: (${rectangle.bottomLeft.x.toStringAsFixed(1)}, ${rectangle.bottomLeft.y.toStringAsFixed(1)})\n' +
                'BR: (${rectangle.bottomRight.x.toStringAsFixed(1)}, ${rectangle.bottomRight.y.toStringAsFixed(1)})'
              ).join('\n\n');
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
      body: Stack(
        children: [
          // 图片显示区域 - 占据全屏
          _image == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '请选择一张图片开始检测',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : InteractiveViewer(
                  child: Center(
                    child: CustomPaint(
                      painter: RectanglePainter(
                        image: _image!,
                        rectangles: _detectedRectangles,
                        imageWidth: _imageWidth,
                        imageHeight: _imageHeight,
                        showOnlyLargestRectangle: _showOnlyLargestRectangle,
                      ),
                      child: Container(),
                    ),
                  ),
                ),
          
          // 悬浮控制面板
          _buildFloatingControlPanel(),
        ],
      ),
    );
  }

  /// 构建悬浮控制面板
  /// 根据屏幕宽度动态调整面板尺寸，避免布局溢出
  Widget _buildFloatingControlPanel() {
    return Positioned(
      top: 16,
      right: 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 根据可用空间动态计算面板宽度
          final screenWidth = MediaQuery.of(context).size.width;
          final maxPanelWidth = (screenWidth - 32).clamp(240.0, 360.0); // 留出左右各16像素边距，最小宽度降至240
          
          return Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: AnimatedContainer(
               duration: const Duration(milliseconds: 300),
               width: _isPanelExpanded ? maxPanelWidth : 56,
               constraints: BoxConstraints(
                 maxHeight: _isPanelExpanded ? 400 : 56,
                 minHeight: 56,
               ),
               padding: const EdgeInsets.all(8),
               child: _isPanelExpanded ? _buildExpandedPanel() : _buildCollapsedPanel(),
             ),
          );
        },
      ),
    );
  }

  /// 构建折叠状态的面板
  Widget _buildCollapsedPanel() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPanelExpanded = true;
        });
      },
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.settings,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  /// 构建展开状态的面板
  Widget _buildExpandedPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '控制面板',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isPanelExpanded = false;
                });
              },
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // 按钮区域
        LayoutBuilder(
          builder: (context, constraints) {
            // 根据可用宽度计算按钮高度，保持合理的宽高比
            double buttonHeight = (constraints.maxWidth * 0.15).clamp(24.0, 40.0);
            
            return Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '选择图片',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: _isDetecting || _image == null ? null : _detectRectangles,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: _isDetecting
                          ? SizedBox(
                              width: buttonHeight * 0.4,
                              height: buttonHeight * 0.4,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: Colors.white,
                              ),
                            )
                          : const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '检测矩形',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        
        // 显示选项开关
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  '显示最大矩形',
                  style: TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _showOnlyLargestRectangle,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyLargestRectangle = value;
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeColor: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // 状态信息
         Flexible(
           child: Container(
             width: double.infinity,
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: Colors.grey[100],
               borderRadius: BorderRadius.circular(8),
             ),
             child: SingleChildScrollView(
               child: Text(
                 _statusMessage,
                 style: const TextStyle(fontSize: 12),
               ),
             ),
           ),
         ),
      ],
    );
  }
}

/// 自定义画笔，用于绘制图片和检测到的矩形
class RectanglePainter extends CustomPainter {
  final ui.Image image;
  final List<RectangleFeature>? rectangles;
  final double imageWidth;
  final double imageHeight;
  final bool showOnlyLargestRectangle;

  RectanglePainter({
    required this.image,
    this.rectangles,
    required this.imageWidth,
    required this.imageHeight,
    this.showOnlyLargestRectangle = false,
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
      
      // 根据设置决定绘制哪些矩形
      List<RectangleFeature> rectanglesToDraw;
      if (showOnlyLargestRectangle) {
        rectanglesToDraw = [_findLargestRectangle(rectangles!)];
      } else {
        rectanglesToDraw = rectangles!;
      }
      
      for (final rectangle in rectanglesToDraw) {
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
  
  /// 计算矩形面积并找到最大的矩形
  RectangleFeature _findLargestRectangle(List<RectangleFeature> rectangles) {
    RectangleFeature largestRectangle = rectangles.first;
    double maxArea = _calculateRectangleArea(largestRectangle);
    
    for (final rectangle in rectangles) {
      final double area = _calculateRectangleArea(rectangle);
      if (area > maxArea) {
        maxArea = area;
        largestRectangle = rectangle;
      }
    }
    
    return largestRectangle;
  }
  
  /// 计算矩形面积（使用向量叉积计算四边形面积）
  double _calculateRectangleArea(RectangleFeature rectangle) {
    // 使用鞋带公式计算四边形面积
    final List<Point<double>> points = [
      rectangle.topLeft,
      rectangle.topRight,
      rectangle.bottomRight,
      rectangle.bottomLeft,
    ];
    
    double area = 0;
    for (int i = 0; i < points.length; i++) {
      final int j = (i + 1) % points.length;
      area += points[i].x * points[j].y;
      area -= points[j].x * points[i].y;
    }
    
    return (area / 2).abs();
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
