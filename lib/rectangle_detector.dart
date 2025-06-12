library;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rectangle_detector/rectangle_feature.dart';
import 'rectangle_detector_platform_interface.dart';

// 导出 RectangleFeature 类，使外部可以直接使用
export 'package:rectangle_detector/rectangle_feature.dart';

class RectangleDetector {
  static Future<String?> getPlatformVersion() {
    return RectangleDetectorPlatform.instance.getPlatformVersion();
  }

  /// 检测图像中的矩形并返回最大的矩形特征点
  ///
  /// [imageData] 图像的字节数据
  /// 返回包含矩形特征点的RectangleFeature对象，如果没有检测到矩形则返回null
  static Future<RectangleFeature?> detectRectangle(Uint8List imageData) async {
    final result = await RectangleDetectorPlatform.instance.detectRectangle(
      imageData,
    );
    if (result == null) return null;
    return RectangleFeature.fromMap(result);
  }

  /// 从ui.Image检测图像中的矩形并返回最大的矩形特征点
  ///
  /// [image] ui.Image对象
  /// 返回包含矩形特征点的RectangleFeature对象，如果没有检测到矩形则返回null
  static Future<RectangleFeature?> detectRectangleFromImage(
    ui.Image image,
  ) async {
    final imageData = await _imageToBytes(image);
    return detectRectangle(imageData);
  }

  /// 从ImageProvider检测图像中的矩形并返回最大的矩形特征点
  ///
  /// [imageProvider] ImageProvider对象
  /// 返回包含矩形特征点的RectangleFeature对象，如果没有检测到矩形则返回null
  static Future<RectangleFeature?> detectRectangleFromProvider(
    ImageProvider imageProvider,
  ) async {
    final uiImage = await _imageProviderToImage(imageProvider);
    final imageData = await _imageToBytes(uiImage);
    return detectRectangle(imageData);
  }

  /// 检测图像中的所有矩形并返回矩形特征点列表
  ///
  /// [imageData] 图像的字节数据
  /// 返回包含所有矩形特征点的RectangleFeature对象列表
  static Future<List<RectangleFeature>> detectAllRectangles(
    Uint8List imageData,
  ) async {
    final results = await RectangleDetectorPlatform.instance
        .detectAllRectangles(imageData);
    return results.map((result) => RectangleFeature.fromMap(result)).toList();
  }

  /// 从ui.Image检测图像中的所有矩形并返回矩形特征点列表
  ///
  /// [image] ui.Image对象
  /// 返回包含所有矩形特征点的RectangleFeature对象列表
  static Future<List<RectangleFeature>> detectAllRectanglesFromImage(
    ui.Image image,
  ) async {
    final imageData = await _imageToBytes(image);
    return detectAllRectangles(imageData);
  }

  /// 从ImageProvider检测图像中的所有矩形并返回矩形特征点列表
  ///
  /// [imageProvider] ImageProvider对象
  /// 返回包含所有矩形特征点的RectangleFeature对象列表
  static Future<List<RectangleFeature>> detectAllRectanglesFromProvider(
    ImageProvider imageProvider,
  ) async {
    final uiImage = await _imageProviderToImage(imageProvider);
    final imageData = await _imageToBytes(uiImage);
    return detectAllRectangles(imageData);
  }

  /// 将ui.Image转换为字节数据
  ///
  /// [image] ui.Image对象
  /// 返回图像的字节数据
  static Future<Uint8List> _imageToBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('无法将图像转换为字节数据');
    }
    return byteData.buffer.asUint8List();
  }

  /// 将ImageProvider转换为ui.Image
  ///
  /// [imageProvider] ImageProvider对象
  /// 返回ui.Image对象
  static Future<ui.Image> _imageProviderToImage(
    ImageProvider imageProvider,
  ) async {
    final ImageStream stream = imageProvider.resolve(
      const ImageConfiguration(),
    );
    final Completer<ui.Image> completer = Completer<ui.Image>();

    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        completer.completeError(exception, stackTrace);
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
    return completer.future;
  }
}
