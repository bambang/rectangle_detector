
import 'dart:math' show Point;
import 'dart:typed_data';
import 'rectangle_detector_plugin_platform_interface.dart';

/// 矩形特征点类
class RectangleFeature {
  final Point<double> topLeft;
  final Point<double> topRight;
  final Point<double> bottomLeft;
  final Point<double> bottomRight;
  
  const RectangleFeature({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });
  
  /// 从Map创建RectangleFeature对象
  factory RectangleFeature.fromMap(Map<String, dynamic> map) {
    final topLeftMap = map['topLeft'] as Map<String, dynamic>;
    final topRightMap = map['topRight'] as Map<String, dynamic>;
    final bottomLeftMap = map['bottomLeft'] as Map<String, dynamic>;
    final bottomRightMap = map['bottomRight'] as Map<String, dynamic>;
    
    return RectangleFeature(
      topLeft: Point((topLeftMap['x'] as num).toDouble(), (topLeftMap['y'] as num).toDouble()),
      topRight: Point((topRightMap['x'] as num).toDouble(), (topRightMap['y'] as num).toDouble()),
      bottomLeft: Point((bottomLeftMap['x'] as num).toDouble(), (bottomLeftMap['y'] as num).toDouble()),
      bottomRight: Point((bottomRightMap['x'] as num).toDouble(), (bottomRightMap['y'] as num).toDouble()),
    );
  }
  
  @override
  String toString() {
    return 'RectangleFeature(topLeft: $topLeft, topRight: $topRight, bottomLeft: $bottomLeft, bottomRight: $bottomRight)';
  }
}

class RectangleDetectorPlugin {
  Future<String?> getPlatformVersion() {
    return RectangleDetectorPluginPlatform.instance.getPlatformVersion();
  }
  
  /// 检测图片中最大的矩形并返回四个顶点坐标
  /// - Parameter imageData: 图片的字节数据
  /// - Returns: 包含四个顶点坐标的RectangleFeature对象，如果未检测到矩形则返回null
  Future<RectangleFeature?> detectRectangle(Uint8List imageData) async {
    final result = await RectangleDetectorPluginPlatform.instance.detectRectangle(imageData);
    if (result != null) {
      return RectangleFeature.fromMap(result);
    }
    return null;
  }
  
  /// 检测图片中所有矩形并返回四个顶点坐标
  /// - Parameter imageData: 图片的字节数据
  /// - Returns: 包含所有矩形顶点坐标的List
  Future<List<RectangleFeature>> detectAllRectangles(Uint8List imageData) async {
    final results = await RectangleDetectorPluginPlatform.instance.detectAllRectangles(imageData);
    return results.map((result) => RectangleFeature.fromMap(result)).toList();
  }
}
