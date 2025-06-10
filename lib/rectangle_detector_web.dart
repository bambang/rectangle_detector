import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

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

/// A web implementation of the RectangleDetectorPlatform of the RectangleDetector plugin.
class RectangleDetectorWeb extends RectangleDetectorPlatform {
  /// Constructs a RectangleDetectorWeb
  RectangleDetectorWeb();

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
      // 确保 OpenCV.js 已加载
      await _ensureOpenCVLoaded();
      
      // 从字节数据创建图像
      final imageElement = await _createImageFromBytes(imageData);
      
      // 调用 JavaScript 函数检测矩形
      final result = _detectSingleRectangleJS(imageElement as JSAny);
      
      if (result == null) {
        return null;
      }
      
      return _convertJSObjectToMap(result);
    } catch (e) {
      print('Web 矩形检测错误: \$e');
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> detectAllRectangles(Uint8List imageData) async {
    try {
      // 确保 OpenCV.js 已加载
      await _ensureOpenCVLoaded();
      
      // 从字节数据创建图像
      final imageElement = await _createImageFromBytes(imageData);
      
      // 调用 JavaScript 函数检测所有矩形
      final result = _detectAllRectanglesJS(imageElement as JSAny);
      
      if (result == null) {
        return <Map<String, dynamic>>[];
      }
      
      // 转换 JavaScript 数组为 Dart List
      return _convertJSArrayToList(result);
    } catch (e) {
      print('Web 所有矩形检测错误: \$e');
      return <Map<String, dynamic>>[];
    }
  }

  /// 确保 OpenCV.js 已加载
  Future<void> _ensureOpenCVLoaded() async {
    final completer = Completer<void>();
    
    // 检查 OpenCV 是否已经加载
    if (cv != null && openCVReady == true) {
      return;
    }
    
    // 如果 OpenCV 脚本还没有加载，先加载它
    if (cv == null) {
      await _loadOpenCVScript();
    }
    
    // 等待 OpenCV 初始化完成
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (openCVReady == true) {
        timer.cancel();
        completer.complete();
      }
    });
    
    return completer.future;
  }

  /// 加载 OpenCV.js 脚本
  Future<void> _loadOpenCVScript() async {
    final completer = Completer<void>();
    
    final script = web.document.createElement('script') as web.HTMLScriptElement;
    script.src = 'https://docs.opencv.org/4.8.0/opencv.js';
    script.type = 'text/javascript';
    
    script.onload = (web.Event event) {
      completer.complete();
    }.toJS;
    
    script.onerror = (web.Event event) {
      completer.completeError('Failed to load OpenCV.js');
    }.toJS;
    
    web.document.head!.appendChild(script);
    
    return completer.future;
  }

  /// 从字节数据创建图像元素
  Future<web.HTMLImageElement> _createImageFromBytes(Uint8List imageData) async {
    final completer = Completer<web.HTMLImageElement>();
    
    // 创建 Blob
    final blob = web.Blob([imageData.toJS].toJS, web.BlobPropertyBag(type: 'image/jpeg'));
    final url = web.URL.createObjectURL(blob);
    
    // 创建图像元素
    final img = web.document.createElement('img') as web.HTMLImageElement;
    
    img.onload = (web.Event event) {
      web.URL.revokeObjectURL(url);
      completer.complete(img);
    }.toJS;
    
    img.onerror = (web.Event event) {
      web.URL.revokeObjectURL(url);
      completer.completeError('Failed to load image');
    }.toJS;
    
    img.src = url;
    
    return completer.future;
  }

  /// 将 JavaScript 对象转换为 Dart Map
  Map<String, dynamic> _convertJSObjectToMap(JSAny? jsObject) {
    if (jsObject == null) return <String, dynamic>{};
    
    try {
      final Map<String, dynamic> result = <String, dynamic>{};
      
      // 获取各个角点
      final topLeft = _getProperty(jsObject, 'topLeft');
      final topRight = _getProperty(jsObject, 'topRight');
      final bottomRight = _getProperty(jsObject, 'bottomRight');
      final bottomLeft = _getProperty(jsObject, 'bottomLeft');
      
      if (topLeft != null) {
        result['topLeft'] = {
          'x': _getProperty(topLeft, 'x')?.dartify(),
          'y': _getProperty(topLeft, 'y')?.dartify(),
        };
      }
      
      if (topRight != null) {
        result['topRight'] = {
          'x': _getProperty(topRight, 'x')?.dartify(),
          'y': _getProperty(topRight, 'y')?.dartify(),
        };
      }
      
      if (bottomRight != null) {
        result['bottomRight'] = {
          'x': _getProperty(bottomRight, 'x')?.dartify(),
          'y': _getProperty(bottomRight, 'y')?.dartify(),
        };
      }
      
      if (bottomLeft != null) {
        result['bottomLeft'] = {
          'x': _getProperty(bottomLeft, 'x')?.dartify(),
          'y': _getProperty(bottomLeft, 'y')?.dartify(),
        };
      }
      
      return result;
    } catch (e) {
      print('JavaScript 对象转换错误: \$e');
      return <String, dynamic>{};
    }
  }
  
  /// 将 JavaScript 数组转换为 Dart List
  List<Map<String, dynamic>> _convertJSArrayToList(JSAny? jsArray) {
    if (jsArray == null) return <Map<String, dynamic>>[];
    
    try {
      final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];
      final length = _getProperty(jsArray, 'length')?.dartify() as int? ?? 0;
      
      for (int i = 0; i < length; i++) {
        final item = _getArrayItem(jsArray, i);
        if (item != null) {
          result.add(_convertJSObjectToMap(item));
        }
      }
      
      return result;
    } catch (e) {
      print('JavaScript 数组转换错误: \$e');
      return <Map<String, dynamic>>[];
    }
  }
  
  /// 辅助方法：获取对象属性
  JSAny? _getProperty(JSAny object, String name) {
    return (object as JSObject)[name];
  }
  
  /// 辅助方法：获取数组元素
  JSAny? _getArrayItem(JSAny array, int index) {
    return (array as JSArray)[index];
  }
}