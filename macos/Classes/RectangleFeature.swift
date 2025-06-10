//
//  RectangleFeature.swift
//  矩形特征点结构体

import Cocoa
import CoreGraphics

/// 矩形特征点结构体
/// 用于描述检测到的矩形的四个角点坐标
public struct RectangleFeature {
    /// 左上角点坐标
    public let topLeft: CGPoint
    /// 右上角点坐标
    public let topRight: CGPoint
    /// 左下角点坐标
    public let bottomLeft: CGPoint
    /// 右下角点坐标
    public let bottomRight: CGPoint
    
    /// 转换为字典格式，便于传递给Flutter
    /// - Returns: 包含四个角点坐标的字典
    public func toDictionary() -> [String: Any] {
        return [
            "topLeft": ["x": topLeft.x, "y": topLeft.y],
            "topRight": ["x": topRight.x, "y": topRight.y],
            "bottomLeft": ["x": bottomLeft.x, "y": bottomLeft.y],
            "bottomRight": ["x": bottomRight.x, "y": bottomRight.y]
        ]
    }
}