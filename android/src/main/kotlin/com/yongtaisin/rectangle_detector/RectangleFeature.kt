package com.yongtaisin.rectangle_detector

import org.opencv.core.Point

/**
 * 矩形特征点结构体
 * 与iOS端RectangleFeature保持一致的数据结构
 * @param topLeft 左上角点
 * @param topRight 右上角点
 * @param bottomLeft 左下角点
 * @param bottomRight 右下角点
 */
data class RectangleFeature(
    val topLeft: Point,
    val topRight: Point,
    val bottomLeft: Point,
    val bottomRight: Point
) {
    /**
     * 转换为字典格式，便于传递给Flutter
     * 与iOS端toDictionary()方法保持一致
     */
    fun toDictionary(): Map<String, Any> {
        return mapOf(
            "topLeft" to mapOf("x" to topLeft.x, "y" to topLeft.y),
            "topRight" to mapOf("x" to topRight.x, "y" to topRight.y),
            "bottomLeft" to mapOf("x" to bottomLeft.x, "y" to bottomLeft.y),
            "bottomRight" to mapOf("x" to bottomRight.x, "y" to bottomRight.y)
        )
    }
    
    /**
     * 将角点转换为Point数组
     * 按顺序：左上、右上、右下、左下
     */
    fun toArray(): Array<Point> = arrayOf(topLeft, topRight, bottomRight, bottomLeft)
    
    /**
     * 将角点转换为List
     * 按顺序：左上、右上、右下、左下
     */
    fun toList(): List<Point> = listOf(topLeft, topRight, bottomRight, bottomLeft)
}