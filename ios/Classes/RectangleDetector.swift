//  矩形识别

import UIKit
import Vision
import CoreImage

/// UIImage扩展，用于转换为CIImage
extension UIImage {
    /// 将UIImage转换为CIImage
    func toCIImage() -> CIImage? {
        if let ciImage = self.ciImage {
            return ciImage
        }
        if let cgImage = self.cgImage {
            return CIImage(cgImage: cgImage)
        }
        return nil
    }
}

/// 矩形特征点结构体
struct RectangleFeature {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint
    
    /// 转换为字典格式，便于传递给Flutter
    func toDictionary() -> [String: Any] {
        return [
            "topLeft": ["x": topLeft.x, "y": topLeft.y],
            "topRight": ["x": topRight.x, "y": topRight.y],
            "bottomLeft": ["x": bottomLeft.x, "y": bottomLeft.y],
            "bottomRight": ["x": bottomRight.x, "y": bottomRight.y]
        ]
    }
}



class RectangleDetector {
    /// 获取图片中最大矩形的四个顶点坐标
    /// - Parameter image: 输入图片
    /// - Returns: 包含四个顶点坐标的RectangleFeature对象，如果未检测到矩形则返回nil
    static func detectRectangle(in image: UIImage) -> RectangleFeature? {
        let rectangles = detectAllRectangles(in: image)
        guard !rectangles.isEmpty else { return nil }
        
        // 找到周长最大的矩形（参考用户提供的CIDetector实现）
        var largestRectangle = rectangles[0]
        var maxHalfPerimeter: CGFloat = 0
        
        for rectangle in rectangles {
            let width = hypot(rectangle.topRight.x - rectangle.topLeft.x, 
                             rectangle.topRight.y - rectangle.topLeft.y)
            let height = hypot(rectangle.bottomLeft.x - rectangle.topLeft.x, 
                              rectangle.bottomLeft.y - rectangle.topLeft.y)
            let halfPerimeter = width + height
            
            if halfPerimeter > maxHalfPerimeter {
                maxHalfPerimeter = halfPerimeter
                largestRectangle = rectangle
            }
        }
        
        return largestRectangle
    }
    
    /// 获取图片中所有矩形的四个顶点坐标
    /// - Parameter image: 输入图片
    /// - Returns: 包含所有矩形顶点坐标的数组
    static func detectAllRectangles(in image: UIImage) -> [RectangleFeature] {
        guard let ciImage = image.toCIImage() else { return [] }
        return detectAllRectanglesWithVision(in: ciImage)
    }

    /// 使用Vision框架检测所有矩形
    /// - Parameter image: 输入的CIImage
    /// - Returns: 检测到的所有矩形数组
    @available(iOS 11.0, *)
    private static func detectAllRectanglesWithVision(in image: CIImage) -> [RectangleFeature] {
        var results: [RectangleFeature] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        // 图片增强：提高对比度以改善边缘检测效果
        let enhancedImage = image.applyingFilter("CIColorControls", parameters: [
            "inputContrast": 1.1
        ])
        
        let imageRequestHandler = VNImageRequestHandler(ciImage: enhancedImage, options: [:])
        
        let rectangleDetectionRequest = VNDetectRectanglesRequest { request, error in
            guard error == nil, 
                  let observations = request.results as? [VNRectangleObservation] else {
                semaphore.signal()
                return
            }
            
            // 转换坐标系统：Vision框架使用左下角为原点的坐标系，需要转换为左上角为原点的坐标系
            let imageWidth = image.extent.width
            let imageHeight = image.extent.height
            
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
        rectangleDetectionRequest.minimumConfidence = 0.6        // 降低置信度阈值，检测更多候选矩形
        rectangleDetectionRequest.maximumObservations = 20       // 增加最大检测数量
        rectangleDetectionRequest.minimumAspectRatio = 0.2       // 降低最小宽高比限制，支持更多形状
        
        do {
            try imageRequestHandler.perform([rectangleDetectionRequest])
        } catch {
            semaphore.signal()
        }
        
        semaphore.wait()
        return results
    }
}