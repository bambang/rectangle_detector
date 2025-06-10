//
//  RectangleDetector.swift
//  macOS 平台的矩形检测实现

import Cocoa
import Vision
import CoreImage

/// macOS平台的图像类型别名
public typealias Image = NSImage

// MARK: - NSImage扩展
/// NSImage扩展，用于转换为CIImage
extension NSImage {
    /// 将NSImage转换为CIImage
    /// - Returns: 转换后的CIImage对象，如果转换失败则返回nil
    func toCIImage() -> CIImage? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        return CIImage(cgImage: cgImage)
    }
}

// MARK: - 矩形检测器
/// 矩形检测器类，提供基于Vision框架的矩形检测功能
public class RectangleDetector {
    
    /// 检测图像中的第一个矩形
    /// - Parameter image: 要检测的图像
    /// - Returns: 检测到的矩形特征，如果没有检测到则返回nil
    public static func detectRectangle(in image: Image) -> RectangleFeature? {
        let rectangles = detectAllRectangles(in: image)
        return rectangles.first
    }
    
    /// 检测图像中的所有矩形
    /// - Parameter image: 要检测的图像
    /// - Returns: 检测到的所有矩形特征数组
    public static func detectAllRectangles(in image: Image) -> [RectangleFeature] {
        guard let ciImage = image.toCIImage() else {
            print("无法将图像转换为CIImage")
            return []
        }
        
        return detectAllRectanglesWithVision(ciImage: ciImage)
    }
    
    /// 使用Vision框架检测矩形
    /// - Parameter ciImage: CIImage对象
    /// - Returns: 检测到的矩形特征数组
    private static func detectAllRectanglesWithVision(ciImage: CIImage) -> [RectangleFeature] {
        var results: [RectangleFeature] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        let rectangleDetectionRequest = VNDetectRectanglesRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRectangleObservation] else {
                semaphore.signal()
                return
            }
            
            // 转换坐标系统：Vision框架使用左下角为原点的坐标系，需要转换为左上角为原点的坐标系
            let imageWidth = ciImage.extent.width
            let imageHeight = ciImage.extent.height
            
            results = observations.map { observation in
                // Vision框架的坐标是归一化的(0-1)，需要转换为实际像素坐标
                // 同时需要翻转Y轴坐标，因为Vision使用左下角为原点，而UI使用左上角为原点
                let topLeftConverted = CGPoint(
                    x: observation.topLeft.x * imageWidth,
                    y: (1.0 - observation.topLeft.y) * imageHeight
                )
                let topRightConverted = CGPoint(
                    x: observation.topRight.x * imageWidth,
                    y: (1.0 - observation.topRight.y) * imageHeight
                )
                let bottomLeftConverted = CGPoint(
                    x: observation.bottomLeft.x * imageWidth,
                    y: (1.0 - observation.bottomLeft.y) * imageHeight
                )
                let bottomRightConverted = CGPoint(
                    x: observation.bottomRight.x * imageWidth,
                    y: (1.0 - observation.bottomRight.y) * imageHeight
                )
                
                return RectangleFeature(
                    topLeft: topLeftConverted,
                    topRight: topRightConverted,
                    bottomLeft: bottomLeftConverted,
                    bottomRight: bottomRightConverted
                )
            }
            
            semaphore.signal()
        }
        
        // 优化检测参数以获得更准确的矩形检测结果
        rectangleDetectionRequest.minimumConfidence = 0.7        // 降低置信度阈值，检测更多候选矩形
        rectangleDetectionRequest.maximumObservations = 10       // 限制检测数量
        rectangleDetectionRequest.minimumAspectRatio = 0.4       // 降低最小宽高比限制，支持更多形状
        
        do {
            try imageRequestHandler.perform([rectangleDetectionRequest])
        } catch {
            semaphore.signal()
        }
        
        semaphore.wait()
        return results
    }
}