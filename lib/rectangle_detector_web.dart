import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'rectangle_detector_platform_interface.dart';

/// 外部 JavaScript 函数声明
@JS('detectSingleRectangle')
external JSAny? _detectSingleRectangleJS(JSAny image);

@JS('detectAllRectangles')
external JSAny? _detectAllRectanglesJS(JSAny image);

@JS('cv')
external JSAny? get cv;

@JS('openCVReady')
external bool? get openCVReady;

/// Web 平台的矩形检测器实现
///
/// 使用 OpenCV.js 在浏览器中进行图像处理和矩形检测
class RectangleDetectorWeb extends RectangleDetectorPlatform {
  /// 构造函数
  RectangleDetectorWeb();

  /// OpenCV.js 加载状态
  static bool _isOpenCVLoaded = false;
  static bool _isOpenCVLoading = false;
  static final List<Completer<void>> _loadingCompleters = [];

  /// 注册 Web 平台实现
  static void registerWith(Registrar registrar) {
    RectangleDetectorPlatform.instance = RectangleDetectorWeb();
  }

  @override
  Future<String?> getPlatformVersion() async {
    return 'Web ${web.window.navigator.userAgent}';
  }

  @override
  Future<Map<String, dynamic>?> detectRectangle(Uint8List imageData) async {
    try {
      // 输入验证
      if (imageData.isEmpty) {
        debugPrint('矩形检测错误: 图像数据为空');
        return null;
      }

      // 确保 OpenCV.js 已加载
      await _ensureOpenCVLoaded();

      // 从字节数据创建图像
      final imageElement = await _createImageFromBytes(imageData);

      // 调用 JavaScript 函数检测矩形
      final result = _detectSingleRectangleJS(imageElement as JSAny);

      if (result == null) {
        debugPrint('矩形检测: 未检测到矩形');
        return null;
      }

      return _convertJSObjectToMap(result);
    } catch (e, stackTrace) {
      debugPrint('Web 矩形检测错误: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> detectAllRectangles(
    Uint8List imageData,
  ) async {
    try {
      // 输入验证
      if (imageData.isEmpty) {
        debugPrint('所有矩形检测错误: 图像数据为空');
        return <Map<String, dynamic>>[];
      }

      // 确保 OpenCV.js 已加载
      await _ensureOpenCVLoaded();

      // 从字节数据创建图像
      final imageElement = await _createImageFromBytes(imageData);

      // 调用 JavaScript 函数检测所有矩形
      final result = _detectAllRectanglesJS(imageElement as JSAny);

      if (result == null) {
        debugPrint('所有矩形检测: 未检测到矩形');
        return <Map<String, dynamic>>[];
      }

      // 转换 JavaScript 数组为 Dart List
      return _convertJSArrayToList(result);
    } catch (e, stackTrace) {
      debugPrint('Web 所有矩形检测错误: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return <Map<String, dynamic>>[];
    }
  }

  /// 确保 OpenCV.js 已加载
  ///
  /// 使用单例模式避免重复加载，支持并发调用
  Future<void> _ensureOpenCVLoaded() async {
    // 如果已经加载完成，直接返回
    if (_isOpenCVLoaded && cv != null && openCVReady == true) {
      return;
    }

    // 如果正在加载，等待加载完成
    if (_isOpenCVLoading) {
      final completer = Completer<void>();
      _loadingCompleters.add(completer);
      return completer.future;
    }

    // 开始加载
    _isOpenCVLoading = true;

    try {
      // 如果 OpenCV 脚本还没有加载，先加载它
      if (cv == null) {
        await _loadOpenCVScript();
      }

      // 等待 OpenCV 初始化完成（最多等待30秒）
      await _waitForOpenCVReady();

      _isOpenCVLoaded = true;

      // 通知所有等待的调用者
      for (final completer in _loadingCompleters) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
      _loadingCompleters.clear();
    } catch (e) {
      // 通知所有等待的调用者加载失败
      for (final completer in _loadingCompleters) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      }
      _loadingCompleters.clear();
      rethrow;
    } finally {
      _isOpenCVLoading = false;
    }
  }

  /// 加载 OpenCV.js 脚本
  Future<void> _loadOpenCVScript() async {
    final completer = Completer<void>();

    final script =
        web.document.createElement('script') as web.HTMLScriptElement;
    script.src = 'https://docs.opencv.org/4.8.0/opencv.js';
    script.type = 'text/javascript';
    script.async = true;
    script.crossOrigin = 'anonymous';

    script.onload = (web.Event event) {
      debugPrint('OpenCV.js 脚本加载成功');
      completer.complete();
    }.toJS;

    script.onerror = (web.Event event) {
      const error = 'Failed to load OpenCV.js from CDN';
      debugPrint('OpenCV.js 脚本加载失败: $error');
      completer.completeError(error);
    }.toJS;

    web.document.head!.appendChild(script);

    return completer.future;
  }

  /// 等待 OpenCV 初始化完成
  Future<void> _waitForOpenCVReady() async {
    final completer = Completer<void>();
    const maxWaitTime = Duration(seconds: 30);
    const checkInterval = Duration(milliseconds: 100);

    final startTime = DateTime.now();

    Timer.periodic(checkInterval, (timer) {
      final elapsed = DateTime.now().difference(startTime);

      if (openCVReady == true) {
        timer.cancel();
        debugPrint('OpenCV.js 初始化完成');
        completer.complete();
      } else if (elapsed > maxWaitTime) {
        timer.cancel();
        const error = 'OpenCV.js 初始化超时';
        debugPrint(error);
        completer.completeError(error);
      }
    });

    return completer.future;
  }

  /// 从字节数据创建图像元素
  ///
  /// 支持多种图像格式，包含超时和错误处理
  Future<web.HTMLImageElement> _createImageFromBytes(
    Uint8List imageData,
  ) async {
    final completer = Completer<web.HTMLImageElement>();
    Timer? timeoutTimer;

    try {
      // 检测图像类型
      final mimeType = _detectImageMimeType(imageData);
      debugPrint('检测到图像类型: $mimeType');

      // 创建 Blob
      final blob = web.Blob(
        [imageData.toJS].toJS,
        web.BlobPropertyBag(type: mimeType),
      );
      final url = web.URL.createObjectURL(blob);

      // 创建图像元素
      final img = web.document.createElement('img') as web.HTMLImageElement;
      img.crossOrigin = 'anonymous';

      // 设置超时（10秒）
      timeoutTimer = Timer(const Duration(seconds: 10), () {
        web.URL.revokeObjectURL(url);
        if (!completer.isCompleted) {
          completer.completeError('图像加载超时');
        }
      });

      img.onload = (web.Event event) {
        timeoutTimer?.cancel();
        web.URL.revokeObjectURL(url);

        // 验证图像有效性
        if (img.naturalWidth > 0 && img.naturalHeight > 0) {
          debugPrint('图像加载成功: ${img.naturalWidth}x${img.naturalHeight}');
          completer.complete(img);
        } else {
          completer.completeError('无效图像: 尺寸为零');
        }
      }.toJS;

      img.onerror = (web.Event event) {
        timeoutTimer?.cancel();
        web.URL.revokeObjectURL(url);
        completer.completeError('图像加载失败: $event');
      }.toJS;

      img.src = url;

      return completer.future;
    } catch (e) {
      timeoutTimer?.cancel();
      completer.completeError('创建图像元素失败: $e');
      return completer.future;
    }
  }

  /// 检测图像 MIME 类型
  ///
  /// 根据文件头字节判断图像格式
  String _detectImageMimeType(Uint8List imageData) {
    if (imageData.length < 4) return 'image/jpeg';

    // PNG 签名: 89 50 4E 47
    if (imageData[0] == 0x89 &&
        imageData[1] == 0x50 &&
        imageData[2] == 0x4E &&
        imageData[3] == 0x47) {
      return 'image/png';
    }

    // JPEG 签名: FF D8
    if (imageData[0] == 0xFF && imageData[1] == 0xD8) {
      return 'image/jpeg';
    }

    // WebP 签名: 52 49 46 46 ... 57 45 42 50
    if (imageData.length >= 12 &&
        imageData[0] == 0x52 &&
        imageData[1] == 0x49 &&
        imageData[2] == 0x46 &&
        imageData[3] == 0x46 &&
        imageData[8] == 0x57 &&
        imageData[9] == 0x45 &&
        imageData[10] == 0x42 &&
        imageData[11] == 0x50) {
      return 'image/webp';
    }

    // GIF 签名: 47 49 46 38
    if (imageData[0] == 0x47 &&
        imageData[1] == 0x49 &&
        imageData[2] == 0x46 &&
        imageData[3] == 0x38) {
      return 'image/gif';
    }

    // BMP 签名: 42 4D
    if (imageData[0] == 0x42 && imageData[1] == 0x4D) {
      return 'image/bmp';
    }

    // 默认返回 JPEG
    return 'image/jpeg';
  }

  /// 将 JavaScript 对象转换为 Dart Map
  ///
  /// 安全地提取矩形角点坐标
  Map<String, dynamic> _convertJSObjectToMap(JSAny? jsObject) {
    if (jsObject == null) return <String, dynamic>{};

    try {
      final Map<String, dynamic> result = <String, dynamic>{};

      // 获取各个角点
      final topLeft = _getProperty(jsObject, 'topLeft');
      final topRight = _getProperty(jsObject, 'topRight');
      final bottomRight = _getProperty(jsObject, 'bottomRight');
      final bottomLeft = _getProperty(jsObject, 'bottomLeft');

      // 安全地提取坐标
      if (topLeft != null) {
        result['topLeft'] = _extractPoint(topLeft);
      }

      if (topRight != null) {
        result['topRight'] = _extractPoint(topRight);
      }

      if (bottomRight != null) {
        result['bottomRight'] = _extractPoint(bottomRight);
      }

      if (bottomLeft != null) {
        result['bottomLeft'] = _extractPoint(bottomLeft);
      }

      // 验证结果完整性
      if (result.length == 4) {
        debugPrint('成功提取矩形坐标: $result');
      } else {
        debugPrint('矩形坐标不完整: $result');
      }

      return result;
    } catch (e) {
      debugPrint('JavaScript 对象转换错误: $e');
      return <String, dynamic>{};
    }
  }

  /// 提取点坐标
  Map<String, dynamic> _extractPoint(JSAny point) {
    final x = _getProperty(point, 'x')?.dartify();
    final y = _getProperty(point, 'y')?.dartify();

    return {
      'x': (x is num) ? x.toDouble() : 0.0,
      'y': (y is num) ? y.toDouble() : 0.0,
    };
  }

  /// 将 JavaScript 数组转换为 Dart List
  ///
  /// 安全地处理数组转换和元素提取
  List<Map<String, dynamic>> _convertJSArrayToList(JSAny? jsArray) {
    if (jsArray == null) return <Map<String, dynamic>>[];

    try {
      final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];
      final length = _getProperty(jsArray, 'length')?.dartify() as int? ?? 0;

      debugPrint('检测到 $length 个矩形');

      for (int i = 0; i < length; i++) {
        final item = _getArrayItem(jsArray, i);
        if (item != null) {
          final rectangle = _convertJSObjectToMap(item);
          if (rectangle.isNotEmpty) {
            result.add(rectangle);
          }
        }
      }

      debugPrint('成功转换 ${result.length} 个矩形');
      return result;
    } catch (e) {
      debugPrint('JavaScript 数组转换错误: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// 辅助方法：获取对象属性
  JSAny? _getProperty(JSAny object, String name) {
    try {
      return (object as JSObject)[name];
    } catch (e) {
      debugPrint('获取属性 $name 失败: $e');
      return null;
    }
  }

  /// 辅助方法：获取数组元素（兼容3.2.0版本）
  JSAny? _getArrayItem(JSAny array, int index) {
    try {
      // 使用字符串索引访问数组元素，兼容Dart 3.2.0
      return (array as JSObject)[index.toString()];
    } catch (e) {
      debugPrint('获取数组元素 $index 失败: $e');
      return null;
    }
  }
}
