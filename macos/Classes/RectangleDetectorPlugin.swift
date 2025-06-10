//
//  RectangleDetectorPlugin.swift
//  支持 iOS 和 macOS 平台的共享实现

import FlutterMacOS

// 引用共享的矩形检测功能
// 这些文件位于 ../shared/ 目录中，通过 podspec 配置引入

public class RectangleDetectorPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
#if os(iOS)
    let channel = FlutterMethodChannel(name: "rectangle_detector", binaryMessenger: registrar.messenger())
#elseif os(macOS)
    let channel = FlutterMethodChannel(name: "rectangle_detector", binaryMessenger: registrar.messenger)
#endif
    let instance = RectangleDetectorPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
#if os(iOS)
      result("iOS " + UIDevice.current.systemVersion)
#elseif os(macOS)
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
#endif
    case "detectRectangle":
      handleDetectRectangle(call: call, result: result)
    case "detectAllRectangles":
      handleDetectAllRectangles(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  /// 处理检测单个矩形的方法调用
  /// - Parameters:
  ///   - call: Flutter方法调用
  ///   - result: 结果回调
  private func handleDetectRectangle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let imageData = args["imageData"] as? FlutterStandardTypedData else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing or invalid imageData", details: nil))
      return
    }
    
#if os(iOS)
    guard let image = UIImage(data: imageData.data) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Cannot create UIImage from provided data", details: nil))
      return
    }
#elseif os(macOS)
    guard let image = NSImage(data: imageData.data) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Cannot create NSImage from provided data", details: nil))
      return
    }
#endif
    
    // 在后台线程执行图像处理
    DispatchQueue.global(qos: .userInitiated).async {
      if let corners = RectangleDetector.detectRectangle(in: image) {
        DispatchQueue.main.async {
          result(corners.toDictionary())
        }
      } else {
        DispatchQueue.main.async {
          result(nil)
        }
      }
    }
  }
  
  /// 处理检测所有矩形的方法调用
  /// - Parameters:
  ///   - call: Flutter方法调用
  ///   - result: 结果回调
  private func handleDetectAllRectangles(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let imageData = args["imageData"] as? FlutterStandardTypedData else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing or invalid imageData", details: nil))
      return
    }
    
#if os(iOS)
    guard let image = UIImage(data: imageData.data) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Cannot create UIImage from provided data", details: nil))
      return
    }
#elseif os(macOS)
    guard let image = NSImage(data: imageData.data) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Cannot create NSImage from provided data", details: nil))
      return
    }
#endif
    
    // 在后台线程执行图像处理
    DispatchQueue.global(qos: .userInitiated).async {
#if os(iOS)
      let allCorners = RectangleDetector.detectAllRectangles(in: image)
      let cornersArray = allCorners.map { $0.toDictionary() }
#elseif os(macOS)
      let rectangles = RectangleDetector.detectAllRectangles(in: image)
      let cornersArray = rectangles.map { $0.toDictionary() }
#endif
      DispatchQueue.main.async {
        result(cornersArray)
      }
    }
  }
}