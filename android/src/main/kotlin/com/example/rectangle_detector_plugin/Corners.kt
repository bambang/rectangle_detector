package com.example.rectangle_detector_plugin

import org.opencv.core.Point
import org.opencv.core.Size

/**
 * 表示检测到的矩形角点信息
 * @param corners 四个角点，按顺序：左上、右上、右下、左下
 * @param size 图像尺寸
 */
data class Corners(
    val corners: List<Point>,
    val size: Size
) {
    init {
        require(corners.size == 4) { "Corners must contain exactly 4 points" }
    }
    
    /**
     * 获取左上角点
     */
    val topLeft: Point get() = corners[0]
    
    /**
     * 获取右上角点
     */
    val topRight: Point get() = corners[1]
    
    /**
     * 获取右下角点
     */
    val bottomRight: Point get() = corners[2]
    
    /**
     * 获取左下角点
     */
    val bottomLeft: Point get() = corners[3]
    
    /**
     * 将角点转换为Point数组
     */
    fun toArray(): Array<Point> = corners.toTypedArray()
    
    /**
     * 将角点转换为List
     */
    fun toList(): List<Point> = corners
}