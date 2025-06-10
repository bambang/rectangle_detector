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
    
    /// 标准化图像处理
    /// 修正图像方向并进行轻微的对比度增强，保持原始尺寸以避免坐标转换问题
    /// - Parameter image: 输入图片
    /// - Returns: 标准化后的CIImage
    private static func normalizeImage(_ image: UIImage) -> CIImage? {
        guard let ciImage = image.toCIImage() else { return nil }
        
        // 1. 修正图像方向（如果有EXIF信息）
        let orientedImage = ciImage.oriented(forExifOrientation: Int32(image.imageOrientation.rawValue))
        
        // 2. 轻微的对比度增强以改善边缘检测（保持原始尺寸）
        let enhancedImage = orientedImage.applyingFilter("CIColorControls", parameters: [
            "inputContrast": 1.1
        ])
        
        return enhancedImage
    }


    /// 获取图片中所有矩形的四个顶点坐标
    /// - Parameter image: 输入图片
    /// - Returns: 包含所有矩形顶点坐标的数组
    static func detectAllRectangles(in image: UIImage) -> [RectangleFeature] {
        guard let ciImage = normalizeImage(image) else { return [] }
        return detectAllRectanglesWithVision(in: ciImage)
    }

    /// 使用Vision框架检测所有矩形
    /// - Parameter image: 输入的CIImage
    /// - Returns: 检测到的所有矩形数组
    @available(iOS 11.0, *)
    private static func detectAllRectanglesWithVision(in image: CIImage) -> [RectangleFeature] {
        var results: [RectangleFeature] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        let imageRequestHandler = VNImageRequestHandler(ciImage: image, options: [:])
        
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