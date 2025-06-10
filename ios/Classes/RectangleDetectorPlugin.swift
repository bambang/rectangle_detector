import Flutter
import UIKit

public class RectangleDetectorPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "rectangle_detector", binaryMessenger: registrar.messenger())
    let instance = RectangleDetectorPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
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
    
    guard let image = UIImage(data: imageData.data) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Cannot create UIImage from provided data", details: nil))
      return
    }
    
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
    
    guard let image = UIImage(data: imageData.data) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Cannot create UIImage from provided data", details: nil))
      return
    }
    
    // 在后台线程执行图像处理
    DispatchQueue.global(qos: .userInitiated).async {
      let allCorners = RectangleDetector.detectAllRectangles(in: image)
      let cornersArray = allCorners.map { $0.toDictionary() }
      DispatchQueue.main.async {
        result(cornersArray)
      }
    }
  }
}
