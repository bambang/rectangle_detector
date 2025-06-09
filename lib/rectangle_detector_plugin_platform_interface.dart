import 'dart:typed_data';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'rectangle_detector_plugin_method_channel.dart';

abstract class RectangleDetectorPluginPlatform extends PlatformInterface {
  /// Constructs a RectangleDetectorPluginPlatform.
  RectangleDetectorPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static RectangleDetectorPluginPlatform _instance = MethodChannelRectangleDetectorPlugin();

  /// The default instance of [RectangleDetectorPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelRectangleDetectorPlugin].
  static RectangleDetectorPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [RectangleDetectorPluginPlatform] when
  /// they register themselves.
  static set instance(RectangleDetectorPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
  
  /// 检测图片中最大的矩形并返回四个顶点坐标
  /// - Parameter imageData: 图片的字节数据
  /// - Returns: 包含四个顶点坐标的Map，如果未检测到矩形则返回null
  Future<Map<String, dynamic>?> detectRectangle(Uint8List imageData) {
    throw UnimplementedError('detectRectangle() has not been implemented.');
  }
  
  /// 检测图片中所有矩形并返回四个顶点坐标
  /// - Parameter imageData: 图片的字节数据
  /// - Returns: 包含所有矩形顶点坐标的List
  Future<List<Map<String, dynamic>>> detectAllRectangles(Uint8List imageData) {
    throw UnimplementedError('detectAllRectangles() has not been implemented.');
  }
}
