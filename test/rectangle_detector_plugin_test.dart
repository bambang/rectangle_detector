import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:rectangle_detector/rectangle_detector.dart';
import 'package:rectangle_detector/rectangle_detector_platform_interface.dart';
import 'package:rectangle_detector/rectangle_detector_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Mock平台实现类，用于测试
class MockRectangleDetectorPlatform
    with MockPlatformInterfaceMixin
    implements RectangleDetectorPlatform {
  /// 获取平台版本信息
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  /// 检测图片中最大的矩形
  @override
  Future<Map<String, dynamic>?> detectRectangle(Uint8List imageData) {
    // 返回模拟的矩形检测结果
    return Future.value({
      'topLeft': {'x': 10.0, 'y': 10.0},
      'topRight': {'x': 100.0, 'y': 10.0},
      'bottomLeft': {'x': 10.0, 'y': 100.0},
      'bottomRight': {'x': 100.0, 'y': 100.0},
    });
  }

  /// 检测图片中所有矩形
  @override
  Future<List<Map<String, dynamic>>> detectAllRectangles(Uint8List imageData) {
    // 返回模拟的多个矩形检测结果
    return Future.value([
      {
        'topLeft': {'x': 10.0, 'y': 10.0},
        'topRight': {'x': 100.0, 'y': 10.0},
        'bottomLeft': {'x': 10.0, 'y': 100.0},
        'bottomRight': {'x': 100.0, 'y': 100.0},
      },
      {
        'topLeft': {'x': 150.0, 'y': 150.0},
        'topRight': {'x': 250.0, 'y': 150.0},
        'bottomLeft': {'x': 150.0, 'y': 250.0},
        'bottomRight': {'x': 250.0, 'y': 250.0},
      },
    ]);
  }
}

void main() {
  final RectangleDetectorPlatform initialPlatform =
      RectangleDetectorPlatform.instance;

  test('$MethodChannelRectangleDetector is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelRectangleDetector>());
  });

  test('getPlatformVersion', () async {
    MockRectangleDetectorPlatform fakePlatform =
        MockRectangleDetectorPlatform();
    RectangleDetectorPlatform.instance = fakePlatform;

    expect(await RectangleDetector.getPlatformVersion(), '42');
  });

  /// 测试单个矩形检测功能
  test('detectRectangle returns valid rectangle', () async {
    MockRectangleDetectorPlatform fakePlatform =
        MockRectangleDetectorPlatform();
    RectangleDetectorPlatform.instance = fakePlatform;

    // 创建测试用的图片数据
    final Uint8List testImageData = Uint8List.fromList([1, 2, 3, 4]);

    final result = await RectangleDetector.detectRectangle(testImageData);

    expect(result, isNotNull);
    expect(result!.topLeft.x, equals(10.0));
    expect(result.topLeft.y, equals(10.0));
    expect(result.topRight.x, equals(100.0));
    expect(result.bottomRight.x, equals(100.0));
    expect(result.bottomRight.y, equals(100.0));
  });

  /// 测试多个矩形检测功能
  test('detectAllRectangles returns list of rectangles', () async {
    MockRectangleDetectorPlatform fakePlatform =
        MockRectangleDetectorPlatform();
    RectangleDetectorPlatform.instance = fakePlatform;

    // 创建测试用的图片数据
    final Uint8List testImageData = Uint8List.fromList([1, 2, 3, 4]);

    final results = await RectangleDetector.detectAllRectangles(testImageData);

    expect(results, isNotNull);
    expect(results.length, equals(2));

    // 验证第一个矩形
    expect(results[0].topLeft.x, equals(10.0));
    expect(results[0].topLeft.y, equals(10.0));
    expect(results[0].bottomRight.x, equals(100.0));
    expect(results[0].bottomRight.y, equals(100.0));

    // 验证第二个矩形
    expect(results[1].topLeft.x, equals(150.0));
    expect(results[1].topLeft.y, equals(150.0));
    expect(results[1].bottomRight.x, equals(250.0));
    expect(results[1].bottomRight.y, equals(250.0));
  });
}
