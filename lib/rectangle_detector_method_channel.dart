import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'rectangle_detector_platform_interface.dart';

/// An implementation of [RectangleDetectorPlatform] that uses method channels.
class MethodChannelRectangleDetector extends RectangleDetectorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('rectangle_detector');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
  
  @override
  Future<Map<String, dynamic>?> detectRectangle(Uint8List imageData) async {
    final result = await methodChannel.invokeMethod(
      'detectRectangle',
      {'imageData': imageData},
    );
    if (result == null) return null;
    return _convertToStringDynamicMap(result);
  }
  
  @override
  Future<List<Map<String, dynamic>>> detectAllRectangles(Uint8List imageData) async {
    final result = await methodChannel.invokeMethod(
      'detectAllRectangles',
      {'imageData': imageData},
    );
    if (result == null) return [];
    
    if (result is List) {
      return result.map<Map<String, dynamic>>((item) {
        return _convertToStringDynamicMap(item);
      }).toList();
    }
    return [];
  }
  
  /// 递归转换Map<Object?, Object?>为Map<String, dynamic>
  /// - Parameter data: 需要转换的数据
  /// - Returns: 转换后的Map<String, dynamic>
  Map<String, dynamic> _convertToStringDynamicMap(dynamic data) {
    if (data is Map) {
      final Map<String, dynamic> result = {};
      data.forEach((key, value) {
        final String stringKey = key.toString();
        if (value is Map) {
          result[stringKey] = _convertToStringDynamicMap(value);
        } else if (value is List) {
          result[stringKey] = value.map((item) {
            if (item is Map) {
              return _convertToStringDynamicMap(item);
            }
            return item;
          }).toList();
        } else {
          result[stringKey] = value;
        }
      });
      return result;
    }
    throw ArgumentError('Expected Map but got ${data.runtimeType}');
  }
}
