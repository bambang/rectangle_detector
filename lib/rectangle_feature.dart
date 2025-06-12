import 'dart:math' show Point;
import 'dart:ui';

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
      topLeft: Point(
        (topLeftMap['x'] as num).toDouble(),
        (topLeftMap['y'] as num).toDouble(),
      ),
      topRight: Point(
        (topRightMap['x'] as num).toDouble(),
        (topRightMap['y'] as num).toDouble(),
      ),
      bottomLeft: Point(
        (bottomLeftMap['x'] as num).toDouble(),
        (bottomLeftMap['y'] as num).toDouble(),
      ),
      bottomRight: Point(
        (bottomRightMap['x'] as num).toDouble(),
        (bottomRightMap['y'] as num).toDouble(),
      ),
    );
  }

  /// 从顶点列表创建四边形注释
  /// 顶点顺序：[左上, 右上, 右下, 左下]
  factory RectangleFeature.fromVertices(List<Point<double>> vertices) {
    if (vertices.length != 4) {
      throw ArgumentError('顶点列表必须包含4个点');
    }
    return RectangleFeature(
      topLeft: vertices[0],
      topRight: vertices[1],
      bottomRight: vertices[2],
      bottomLeft: vertices[3],
    );
  }

  /// 转换为顶点列表
  /// 返回顺序：[左上, 右上, 右下, 左下]
  List<Point<double>> get vertices => [
    topLeft,
    topRight,
    bottomRight,
    bottomLeft,
  ];

  /// 获取边界矩形
  Rect get bounds {
    final points = vertices;
    double xMin = points[0].x;
    double xMax = points[0].x;
    double yMin = points[0].y;
    double yMax = points[0].y;

    for (int i = 1; i < points.length; i++) {
      final point = points[i];
      if (point.x > xMax) xMax = point.x;
      if (point.x < xMin) xMin = point.x;
      if (point.y > yMax) yMax = point.y;
      if (point.y < yMin) yMin = point.y;
    }

    return Rect.fromLTRB(xMin, yMin, xMax, yMax);
  }

  /// 根据索引获取顶点
  Point<double> getVertex(int index) {
    switch (index) {
      case 0:
        return topLeft;
      case 1:
        return topRight;
      case 2:
        return bottomRight;
      case 3:
        return bottomLeft;
      default:
        throw ArgumentError('顶点索引必须在0-3之间');
    }
  }

  /// 复制当前矩形特征
  RectangleFeature copy() {
    return RectangleFeature(
      topLeft: topLeft,
      topRight: topRight,
      bottomRight: bottomRight,
      bottomLeft: bottomLeft,
    );
  }

  /// 相等性比较
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RectangleFeature &&
        other.topLeft == topLeft &&
        other.topRight == topRight &&
        other.bottomRight == bottomRight &&
        other.bottomLeft == bottomLeft;
  }

  @override
  int get hashCode {
    return Object.hash(topLeft, topRight, bottomRight, bottomLeft);
  }

  @override
  String toString() {
    return 'RectangleFeature(topLeft: $topLeft, topRight: $topRight, bottomLeft: $bottomLeft, bottomRight: $bottomRight)';
  }
}
