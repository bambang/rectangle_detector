package com.example.rectangle_detector_plugin

import android.graphics.Bitmap
import android.util.Log
import org.opencv.android.Utils
import org.opencv.core.*
import org.opencv.imgproc.Imgproc
import kotlin.math.abs

/**
 * RectangleDetector
 * 专门负责图像处理和矩形检测的算法类
 * 使用OpenCV进行图像处理，不涉及初始化逻辑
 */
class RectangleDetector {
    companion object {
        private const val TAG = "RectangleDetector"
    }
    
    /**
     * 检测图像中的矩形
     * @param bitmap 输入的图像
     * @return 检测到的矩形顶点坐标，如果没有检测到则返回null
     */
    fun detectRectangle(bitmap: Bitmap): List<Point>? {
        return try {
            Log.d(TAG, "开始矩形检测，图像尺寸: ${bitmap.width}x${bitmap.height}")
            
            // 将Bitmap转换为OpenCV Mat
            val mat = Mat()
            Utils.bitmapToMat(bitmap, mat)
            Log.d(TAG, "Bitmap转换为Mat完成，Mat尺寸: ${mat.rows()}x${mat.cols()}")
            
            // 转换为灰度图像
            val grayMat = Mat()
            Imgproc.cvtColor(mat, grayMat, Imgproc.COLOR_RGB2GRAY)
            Log.d(TAG, "灰度转换完成")
            
            // 高斯模糊 - 减少噪声
            val blurredMat = Mat()
            Imgproc.GaussianBlur(grayMat, blurredMat, Size(5.0, 5.0), 0.0)
            Log.d(TAG, "高斯模糊完成")
            
            // 自适应阈值处理 - 提高边缘检测效果
            val threshMat = Mat()
            Imgproc.adaptiveThreshold(
                blurredMat, threshMat, 255.0,
                Imgproc.ADAPTIVE_THRESH_GAUSSIAN_C,
                Imgproc.THRESH_BINARY, 11, 2.0
            )
            Log.d(TAG, "自适应阈值处理完成")
            
            // Canny边缘检测 - 优化参数
            val edgesMat = Mat()
            Imgproc.Canny(threshMat, edgesMat, 30.0, 100.0, 3, false)
            Log.d(TAG, "Canny边缘检测完成")
            
            // 形态学操作 - 连接断开的边缘
            val kernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, Size(3.0, 3.0))
            val morphMat = Mat()
            Imgproc.morphologyEx(edgesMat, morphMat, Imgproc.MORPH_CLOSE, kernel)
            Log.d(TAG, "形态学操作完成")
            
            // 再次膨胀以加强边缘
            val dilatedMat = Mat()
            Imgproc.dilate(morphMat, dilatedMat, kernel, Point(-1.0, -1.0), 1)
            Log.d(TAG, "膨胀操作完成")
            
            // 查找轮廓
            val contours = mutableListOf<MatOfPoint>()
            val hierarchy = Mat()
            Imgproc.findContours(
                dilatedMat,
                contours,
                hierarchy,
                Imgproc.RETR_EXTERNAL,
                Imgproc.CHAIN_APPROX_SIMPLE
            )
            Log.d(TAG, "找到 ${contours.size} 个轮廓")
            
            // 查找最大的四边形轮廓
            val rectangle = findLargestRectangle(contours)
            
            if (rectangle != null) {
                Log.d(TAG, "检测到矩形，顶点数: ${rectangle.size}")
                rectangle.forEachIndexed { index, point ->
                    Log.d(TAG, "顶点$index: (${point.x}, ${point.y})")
                }
            } else {
                Log.w(TAG, "未检测到矩形")
            }
            
            // 释放内存
            mat.release()
            grayMat.release()
            blurredMat.release()
            threshMat.release()
            edgesMat.release()
            morphMat.release()
            dilatedMat.release()
            hierarchy.release()
            kernel.release()
            contours.forEach { it.release() }
            
            rectangle
        } catch (e: Exception) {
            Log.e(TAG, "Rectangle detection failed", e)
            null
        }
    }
    
    /**
     * 检测图像中的所有矩形
     * @param bitmap 输入的图像
     * @return 检测到的所有矩形顶点坐标列表
     */
    fun detectAllRectangles(bitmap: Bitmap): List<List<Point>> {
        return try {
            // 将Bitmap转换为OpenCV Mat
            val mat = Mat()
            Utils.bitmapToMat(bitmap, mat)
            
            // 转换为灰度图像
            val grayMat = Mat()
            Imgproc.cvtColor(mat, grayMat, Imgproc.COLOR_RGB2GRAY)
            
            // 高斯模糊 - 减少噪声
            val blurredMat = Mat()
            Imgproc.GaussianBlur(grayMat, blurredMat, Size(5.0, 5.0), 0.0)
            
            // 自适应阈值处理 - 提高边缘检测效果
            val threshMat = Mat()
            Imgproc.adaptiveThreshold(
                blurredMat, threshMat, 255.0,
                Imgproc.ADAPTIVE_THRESH_GAUSSIAN_C,
                Imgproc.THRESH_BINARY, 11, 2.0
            )
            
            // Canny边缘检测 - 优化参数
            val edgesMat = Mat()
            Imgproc.Canny(threshMat, edgesMat, 30.0, 100.0, 3, false)
            
            // 形态学操作 - 连接断开的边缘
            val kernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, Size(3.0, 3.0))
            val morphMat = Mat()
            Imgproc.morphologyEx(edgesMat, morphMat, Imgproc.MORPH_CLOSE, kernel)
            
            // 再次膨胀以加强边缘
            val dilatedMat = Mat()
            Imgproc.dilate(morphMat, dilatedMat, kernel, Point(-1.0, -1.0), 1)
            
            // 查找轮廓
            val contours = mutableListOf<MatOfPoint>()
            val hierarchy = Mat()
            Imgproc.findContours(
                dilatedMat,
                contours,
                hierarchy,
                Imgproc.RETR_EXTERNAL,
                Imgproc.CHAIN_APPROX_SIMPLE
            )
            
            // 查找所有四边形轮廓
            val rectangles = findAllRectangles(contours)
            
            // 释放内存
            mat.release()
            grayMat.release()
            blurredMat.release()
            threshMat.release()
            edgesMat.release()
            morphMat.release()
            dilatedMat.release()
            hierarchy.release()
            kernel.release()
            contours.forEach { it.release() }
            
            rectangles
        } catch (e: Exception) {
            Log.e(TAG, "All rectangles detection failed", e)
            emptyList()
        }
    }
    
    /**
     * 查找最大的矩形轮廓
     */
    private fun findLargestRectangle(contours: List<MatOfPoint>): List<Point>? {
        var largestArea = 0.0
        var largestRectangle: List<Point>? = null
        var validContours = 0
        var rectangleContours = 0
        
        Log.d(TAG, "开始分析 ${contours.size} 个轮廓")
        
        for ((index, contour) in contours.withIndex()) {
            val area = Imgproc.contourArea(contour)
            Log.d(TAG, "轮廓$index: 面积=$area")
            
            // 过滤太小的轮廓（降低阈值）
            if (area < 500) {
                Log.d(TAG, "轮廓$index: 面积太小，跳过")
                continue
            }
            
            validContours++
            Log.d(TAG, "轮廓$index: 面积符合要求，开始矩形近似")
            
            val rectangle = approximateToRectangle(contour)
            if (rectangle != null) {
                rectangleContours++
                Log.d(TAG, "轮廓$index: 成功近似为矩形，面积=$area")
                if (area > largestArea) {
                    largestArea = area
                    largestRectangle = rectangle
                    Log.d(TAG, "轮廓$index: 更新为最大矩形")
                }
            } else {
                Log.d(TAG, "轮廓$index: 无法近似为矩形")
            }
        }
        
        Log.d(TAG, "轮廓分析完成: 总数=${contours.size}, 有效=${validContours}, 矩形=${rectangleContours}, 最大面积=$largestArea")
        
        return largestRectangle
    }
    
    /**
     * 查找所有矩形轮廓
     */
    private fun findAllRectangles(contours: List<MatOfPoint>): List<List<Point>> {
        val rectangles = mutableListOf<List<Point>>()
        
        for (contour in contours) {
            val area = Imgproc.contourArea(contour)
            
            // 过滤太小的轮廓（降低阈值）
            if (area < 500) continue
            
            val rectangle = approximateToRectangle(contour)
            if (rectangle != null) {
                rectangles.add(rectangle)
            }
        }
        
        // 按面积排序，最大的在前
        return rectangles.sortedByDescending { calculateArea(it) }
    }
    
    /**
     * 将轮廓近似为矩形
     */
    private fun approximateToRectangle(contour: MatOfPoint): List<Point>? {
        val contour2f = MatOfPoint2f()
        contour.convertTo(contour2f, CvType.CV_32FC2)
        
        val approx = MatOfPoint2f()
        val epsilon = 0.02 * Imgproc.arcLength(contour2f, true)
        Imgproc.approxPolyDP(contour2f, approx, epsilon, true)
        
        val points = approx.toArray()
        Log.d(TAG, "多边形近似结果: ${points.size} 个顶点")
        
        contour2f.release()
        approx.release()
        
        // 检查是否为四边形
        if (points.size == 4) {
            Log.d(TAG, "检测到四边形，开始验证是否为有效矩形")
            // 验证是否为有效的矩形（检查角度和边长比例）
            if (isValidRectangle(points.toList())) {
                Log.d(TAG, "四边形验证通过，排列顶点")
                // 按顺序排列顶点：左上、右上、右下、左下
                return sortRectanglePoints(points.toList())
            } else {
                Log.d(TAG, "四边形验证失败")
            }
        } else {
            Log.d(TAG, "不是四边形，顶点数: ${points.size}")
        }
        
        return null
    }
    
    /**
     * 验证是否为有效的矩形
     * 使用更宽松的验证条件，确保能够检测到矩形
     */
    private fun isValidRectangle(points: List<Point>): Boolean {
        if (points.size != 4) {
            Log.d(TAG, "验证失败: 不是四边形，顶点数=${points.size}")
            return false
        }
        
        // 计算面积，过滤太小的形状（降低阈值）
        val area = calculateArea(points)
        Log.d(TAG, "四边形面积: $area")
        if (area < 1000) {
            Log.d(TAG, "验证失败: 面积太小 ($area < 1000)")
            return false  // 降低最小面积阈值
        }
        
        // 计算所有边的长度
        val sides = mutableListOf<Double>()
        for (i in points.indices) {
            val p1 = points[i]
            val p2 = points[(i + 1) % 4]
            val distance = kotlin.math.sqrt(
                (p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y)
            )
            sides.add(distance)
        }
        Log.d(TAG, "边长: ${sides.joinToString(", ") { "%.2f".format(it) }}")
        
        // 检查是否有边长过短（降低阈值）
        val minSideLength = 20.0  // 降低最小边长要求
        val shortSides = sides.filter { it < minSideLength }
        if (shortSides.isNotEmpty()) {
            Log.d(TAG, "验证失败: 存在过短边长 ${shortSides.joinToString(", ") { "%.2f".format(it) }} (< $minSideLength)")
            return false
        }
        
        // 检查宽高比是否合理（放宽限制）
        val maxSide = sides.maxOrNull() ?: 0.0
        val minSide = sides.minOrNull() ?: 0.0
        val aspectRatio = maxSide / minSide
        Log.d(TAG, "宽高比: %.2f (最大边=%.2f, 最小边=%.2f)".format(aspectRatio, maxSide, minSide))
        if (aspectRatio > 20.0) {
            Log.d(TAG, "验证失败: 宽高比过大 ($aspectRatio > 20.0)")
            return false  // 放宽宽高比限制
        }
        
        // 基本的四边形验证，不进行严格的矩形验证
        // 只检查是否为凸四边形
        val isConvex = isConvexQuadrilateral(points)
        Log.d(TAG, "凸四边形检查: $isConvex")
        if (!isConvex) {
            Log.d(TAG, "验证失败: 不是凸四边形")
            return false
        }
        
        Log.d(TAG, "验证成功: 所有条件都满足")
        return true
    }
    
    /**
     * 按顺序排列矩形顶点：左上、右上、右下、左下
     * 使用更可靠的几何方法来识别四个角点
     */
    private fun sortRectanglePoints(points: List<Point>): List<Point> {
        if (points.size != 4) return points
        
        // 按y坐标排序，分为上下两组
        val sortedByY = points.sortedBy { it.y }
        val topPoints = sortedByY.take(2)  // y值较小的两个点（上方）
        val bottomPoints = sortedByY.drop(2)  // y值较大的两个点（下方）
        
        // 在上方两点中，按x坐标排序确定左上和右上
        val topSorted = topPoints.sortedBy { it.x }
        val topLeft = topSorted[0]     // x值较小的为左上
        val topRight = topSorted[1]    // x值较大的为右上
        
        // 在下方两点中，按x坐标排序确定左下和右下
        val bottomSorted = bottomPoints.sortedBy { it.x }
        val bottomLeft = bottomSorted[0]   // x值较小的为左下
        val bottomRight = bottomSorted[1]  // x值较大的为右下
        
        // 返回按照topLeft, topRight, bottomRight, bottomLeft的顺序
        return listOf(topLeft, topRight, bottomRight, bottomLeft)
    }
    
    /**
     * 计算多边形面积
     */
    private fun calculateArea(points: List<Point>): Double {
        if (points.size < 3) return 0.0
        
        var area = 0.0
        for (i in points.indices) {
            val j = (i + 1) % points.size
            area += points[i].x * points[j].y
            area -= points[j].x * points[i].y
        }
        return abs(area) / 2.0
    }
    
    /**
     * 检查是否为凸四边形
     * 使用叉积判断所有顶点的转向是否一致
     */
    private fun isConvexQuadrilateral(points: List<Point>): Boolean {
        if (points.size != 4) return false
        
        var sign = 0
        for (i in points.indices) {
            val p1 = points[i]
            val p2 = points[(i + 1) % 4]
            val p3 = points[(i + 2) % 4]
            
            // 计算叉积
            val crossProduct = (p2.x - p1.x) * (p3.y - p2.y) - (p2.y - p1.y) * (p3.x - p2.x)
            
            if (crossProduct != 0.0) {
                val currentSign = if (crossProduct > 0) 1 else -1
                if (sign == 0) {
                    sign = currentSign
                } else if (sign != currentSign) {
                    return false  // 不是凸四边形
                }
            }
        }
        return true
    }
}