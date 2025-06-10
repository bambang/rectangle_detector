package com.yongtaisin.rectangle_detector

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.ByteArrayOutputStream
import org.opencv.core.Point

/**
 * RectangleDetectorPlugin
 * Flutter插件主类，负责Flutter与Android原生代码的通信桥梁
 * 专注于方法调用路由、参数转换和结果返回
 */
class RectangleDetectorPlugin: FlutterPlugin, MethodCallHandler {
  companion object {
    private const val TAG = "RectangleDetectorPlugin"
  }
  
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private val rectangleDetector = RectangleDetector()
  private val openCVManager = OpenCVManager.getInstance()

  /**
   * 插件附加到Flutter引擎时的回调
   * 设置方法通道并初始化OpenCV
   */
  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "rectangle_detector")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
    
    // 使用OpenCVManager初始化OpenCV
    openCVManager.initialize(context) { success ->
      if (success) {
        DebugLogger.d(TAG, "OpenCV initialization completed successfully")
      } else {
        DebugLogger.e(TAG, "OpenCV initialization failed")
      }
    }
  }

  /**
   * 处理来自Flutter的方法调用
   * @param call 方法调用信息
   * @param result 结果回调
   */
  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "detectRectangle" -> {
        detectRectangle(call, result)
      }
      "detectAllRectangles" -> {
        detectAllRectangles(call, result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }
  
  private fun detectRectangle(call: MethodCall, result: Result) {
    if (!openCVManager.isInitialized()) {
      result.error("OPENCV_NOT_INITIALIZED", "OpenCV is not initialized", null)
      return
    }
    
    try {
      val imageData = call.argument<ByteArray>("imageData")
      if (imageData == null) {
        result.error("INVALID_ARGUMENT", "imageData is required", null)
        return
      }
      
      val bitmap = BitmapFactory.decodeByteArray(imageData, 0, imageData.size)
      if (bitmap == null) {
        result.error("INVALID_IMAGE", "Failed to decode image", null)
        return
      }
      
      val rectangle = rectangleDetector.detectRectangle(bitmap)
      bitmap.recycle()
      
      result.success(rectangle)
    } catch (e: Exception) {
      DebugLogger.e(TAG, "Error detecting rectangle", e)
      result.error("DETECTION_ERROR", "Failed to detect rectangle: ${e.message}", null)
    }
  }
  
  private fun detectAllRectangles(call: MethodCall, result: Result) {
    if (!openCVManager.isInitialized()) {
      result.error("OPENCV_NOT_INITIALIZED", "OpenCV is not initialized", null)
      return
    }
    
    try {
      val imageData = call.argument<ByteArray>("imageData")
      if (imageData == null) {
        result.error("INVALID_ARGUMENT", "imageData is required", null)
        return
      }
      
      val bitmap = BitmapFactory.decodeByteArray(imageData, 0, imageData.size)
      if (bitmap == null) {
        result.error("INVALID_IMAGE", "Failed to decode image", null)
        return
      }
      
      val rectangles = rectangleDetector.detectAllRectangles(bitmap)
      bitmap.recycle()
      
      result.success(rectangles)
    } catch (e: Exception) {
      DebugLogger.e(TAG, "Error detecting rectangles", e)
      result.error("DETECTION_ERROR", "Failed to detect rectangles: ${e.message}", null)
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
