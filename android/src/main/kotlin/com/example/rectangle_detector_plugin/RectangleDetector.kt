package com.example.rectangle_detector_plugin

import android.graphics.Bitmap
import android.util.Log
import org.opencv.android.Utils
import org.opencv.core.*
import org.opencv.imgproc.Imgproc
import kotlin.math.abs
import kotlin.math.sqrt
import kotlin.math.pow
import kotlin.math.max
import kotlin.math.min

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
     * 检测图像中的单个最大矩形
     * @param bitmap 输入的图像
     * @return 检测到的矩形顶点坐标，如果未检测到则返回null
     */
    fun detectRectangle(bitmap: Bitmap): Map<String, Any>? {
        val allRectangles = detectAllRectangles(bitmap)
        
        // 选择评分最高的矩形
        return allRectangles.firstOrNull() // 已经按评分排序，第一个就是最好的
    }
    
    /**
     * 检测图像中的所有矩形
     * @param bitmap 输入的图像
     * @return 检测到的所有矩形顶点坐标列表
     */
    fun detectAllRectangles(bitmap: Bitmap): List<Map<String, Any>> {
        return try {
            val contours = preprocessImageAndFindContours(bitmap)
            val imageSize = Size(bitmap.width.toDouble(), bitmap.height.toDouble())
            val candidates = findValidRectangles(contours, imageSize)
            
            // 按评分排序，评分高的在前
            val sortedCandidates = candidates.sortedByDescending { it.second }
            
            Log.i(TAG, "Found ${sortedCandidates.size} rectangle candidates")
            
            sortedCandidates.map { (rectangle, score) ->
                mapOf(
                    "topLeft" to mapOf("x" to rectangle[0].x, "y" to rectangle[0].y),
                    "topRight" to mapOf("x" to rectangle[1].x, "y" to rectangle[1].y),
                    "bottomRight" to mapOf("x" to rectangle[2].x, "y" to rectangle[2].y),
                    "bottomLeft" to mapOf("x" to rectangle[3].x, "y" to rectangle[3].y),
                    "score" to score
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Rectangle detection failed", e)
            emptyList()
        }
    }
    
    /**
     * 预处理图像并查找轮廓
     * 完全按照PaperProcessor.kt中的findContours算法实现
     */
    private fun preprocessImageAndFindContours(bitmap: Bitmap): ArrayList<MatOfPoint> {
        // 将Bitmap转换为OpenCV Mat
        val src = Mat()
        Utils.bitmapToMat(bitmap, src)
        
        val grayImage: Mat
        val cannedImage: Mat
        // 使用不同大小的核进行形态学操作
        val smallKernel: Mat = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, Size(3.0, 3.0))
        val largeKernel: Mat = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, Size(7.0, 7.0))
        val dilate: Mat
        val size = Size(src.size().width, src.size().height)
        grayImage = Mat(size, CvType.CV_8UC4)
        cannedImage = Mat(size, CvType.CV_8UC1)
        dilate = Mat(size, CvType.CV_8UC1)

        // 简化预处理：保持基础但有效的边缘检测
        Imgproc.cvtColor(src, grayImage, Imgproc.COLOR_BGR2GRAY)
        
        // 轻微高斯模糊去噪，保留边缘信息
        Imgproc.GaussianBlur(grayImage, grayImage, Size(3.0, 3.0), 0.0)
        
        // 直接使用Canny边缘检测，使用经典参数
        Imgproc.Canny(grayImage, cannedImage, 50.0, 150.0)
        
        // 轻微膨胀操作，连接断开的边缘
        Imgproc.dilate(cannedImage, dilate, smallKernel)
        
        val contours = ArrayList<MatOfPoint>()
        val hierarchy = Mat()
        Imgproc.findContours(dilate, contours, hierarchy, Imgproc.RETR_TREE, Imgproc.CHAIN_APPROX_SIMPLE)
        
        Log.i(TAG, "Found ${contours.size} contours")
        
        // 简化轮廓过滤：只排除明显过大或过小的轮廓
        val imageArea = size.width * size.height
        val filteredContours = contours.filter { contour ->
            val area = Imgproc.contourArea(contour)
            val areaRatio = area / imageArea
            // 保留合理大小的轮廓，排除整个图像边界和噪点
            areaRatio in 0.01..0.8
        }
        
        Log.i(TAG, "Original contours: ${contours.size}, Filtered contours: ${filteredContours.size}")
        
        val validContours = ArrayList(filteredContours)
        validContours.sortByDescending { p: MatOfPoint -> Imgproc.contourArea(p) }
        
        // 释放所有Mat对象
        hierarchy.release()
        grayImage.release()
        cannedImage.release()
        smallKernel.release()
        largeKernel.release()
        dilate.release()
        src.release()

        return validContours
    }
    
    /**
     * 从轮廓中查找有效的矩形
     * 完全按照PaperProcessor.kt中的getCorners算法实现
     */
    private fun findValidRectangles(contours: ArrayList<MatOfPoint>, imageSize: Size): List<Pair<List<Point>, Double>> {
        val candidates = mutableListOf<Pair<List<Point>, Double>>()
        val maxCandidates = minOf(contours.size, 30) // 增加到30个轮廓，扩大搜索范围
        
        Log.i(TAG, "Processing ${contours.size} contours, checking top $maxCandidates")
        
        for (index in 0 until maxCandidates) {
            try {
                val c2f = MatOfPoint2f(*contours[index].toArray())
                val peri = Imgproc.arcLength(c2f, true)
                val approx = MatOfPoint2f()
                
                // 尝试多个近似参数，从严格到宽松，与PaperProcessor.kt保持一致
                val epsilonValues = listOf(0.015, 0.02, 0.025, 0.03)
                var foundQuad = false
                
                for (epsilon in epsilonValues) {
                    Imgproc.approxPolyDP(c2f, approx, epsilon * peri, true)
                    val points = approx.toArray().asList()
                    
                    Log.d(TAG, "Contour $index: epsilon=${epsilon}, points=${points.size}, area=${Imgproc.contourArea(c2f)}")
                    
                    // 检查是否为四边形
                    if (points.size == 4) {
                        val convex = MatOfPoint()
                        approx.convertTo(convex, CvType.CV_32S)
                        
                        // 检查是否为凸四边形，但允许轻微的不规则
                        val isConvex = Imgproc.isContourConvex(convex)
                        Log.d(TAG, "Contour $index: epsilon=${epsilon}, convex check = $isConvex")
                        
                        // 对于纯矩形图案，放宽凸性检查，允许轻微的数值误差
                        val shouldAccept = isConvex || (points.size == 4 && Imgproc.contourArea(approx) > imageSize.width * imageSize.height * 0.05)
                        if (shouldAccept) { // 大面积四边形即使凸性检查略有问题也接受
                            val sortedPoints = sortPoints(points)
                            
                            // 计算矩形度评分
                            val score = calculateRectangleScore(sortedPoints, Imgproc.contourArea(approx), imageSize)
                            candidates.add(Pair(sortedPoints, score))
                            
                            Log.i(TAG, "Found rectangle candidate $index: score = $score, convex = $isConvex, accepted = $shouldAccept")
                            
                            // 打印四个角的详细坐标
                            Log.d(TAG, "检测到的四个角坐标:")
                            sortedPoints.forEachIndexed { pointIndex, point ->
                                Log.d(TAG, "角点 $pointIndex: (${point.x}, ${point.y})")
                            }
                            
                            foundQuad = true
                            break // 找到四边形就停止尝试其他epsilon值
                        }
                        convex.release()
                    }
                }
                
                if (!foundQuad) {
                    Log.d(TAG, "Contour $index: no valid quadrilateral found")
                }
                
                c2f.release()
                approx.release()
                
            } catch (e: Exception) {
                Log.w(TAG, "Error processing contour $index: ${e.message}")
            }
        }
        
        Log.i(TAG, "Total candidates found: ${candidates.size}")
        
        return candidates
    }
    

    
    /**
     * 按顺序排列矩形顶点：左上、右上、右下、左下
     * 完全按照PaperProcessor.kt中的sortPoints算法实现
     */
    private fun sortPoints(points: List<Point>): List<Point> {
        val p0 = points.minBy { point -> point.x + point.y } ?: Point()
        val p1 = points.minBy { point -> point.y - point.x } ?: Point()
        val p2 = points.maxBy { point -> point.x + point.y } ?: Point()
        val p3 = points.maxBy { point -> point.y - point.x } ?: Point()
        return listOf(p0, p1, p2, p3)
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
     * 计算矩形质量评分
     * 完全按照PaperProcessor.kt中的calculateRectangleScore算法实现
     */
    private fun calculateRectangleScore(points: List<Point>, area: Double, imageSize: Size): Double {
        val tl = points[0]
        val tr = points[1] 
        val br = points[2]
        val bl = points[3]
        
        // 计算四边长度
        val topWidth = sqrt((tr.x - tl.x).pow(2.0) + (tr.y - tl.y).pow(2.0))
        val bottomWidth = sqrt((br.x - bl.x).pow(2.0) + (br.y - bl.y).pow(2.0))
        val leftHeight = sqrt((bl.x - tl.x).pow(2.0) + (bl.y - tl.y).pow(2.0))
        val rightHeight = sqrt((br.x - tr.x).pow(2.0) + (br.y - tr.y).pow(2.0))
        
        // 1. 面积评分 (强烈优先大面积，大幅降低小面积评分)
        val imageArea = imageSize.width * imageSize.height
        val areaRatio = area / imageArea
        val areaScore = when {
            areaRatio >= 0.2 -> 1.0         // 大面积优先，降低阈值
            areaRatio in 0.1..0.2 -> 0.8    // 中等面积
            areaRatio in 0.05..0.1 -> 0.4   // 较小面积，大幅降分
            areaRatio in 0.02..0.05 -> 0.1  // 小面积，严重降分
            else -> 0.01                    // 极小面积，几乎零分
        }
        
        // 2. 基本形状评分 (极度宽松的长宽比要求)
        val avgWidth = (topWidth + bottomWidth) / 2.0
        val avgHeight = (leftHeight + rightHeight) / 2.0
        val aspectRatio = max(avgWidth, avgHeight) / min(avgWidth, avgHeight)
        val aspectScore = when {
            aspectRatio <= 3.0 -> 1.0       // 长宽比不超过3:1都可以接受
            aspectRatio <= 5.0 -> 0.9       // 稍长的矩形
            aspectRatio <= 8.0 -> 0.8       // 较长的矩形
            aspectRatio <= 12.0 -> 0.7      // 很长的矩形
            else -> 0.6                     // 极度狭长，但仍给予较高分数
        }
        
        // 3. 边长一致性评分 (降低严格要求，允许透视变形)
        val widthConsistency = 1.0 - min(0.5, abs(topWidth - bottomWidth) / max(topWidth, bottomWidth))
        val heightConsistency = 1.0 - min(0.5, abs(leftHeight - rightHeight) / max(leftHeight, rightHeight))
        val edgeScore = (widthConsistency + heightConsistency) / 2.0
        
        // 4. 位置评分 (中心位置优先，但权重较低)
        val centerX = (tl.x + tr.x + bl.x + br.x) / 4.0
        val centerY = (tl.y + tr.y + bl.y + br.y) / 4.0
        val imageCenterX = imageSize.width / 2.0
        val imageCenterY = imageSize.height / 2.0
        val distanceFromCenter = sqrt((centerX - imageCenterX).pow(2.0) + (centerY - imageCenterY).pow(2.0))
        val maxDistance = sqrt(imageCenterX.pow(2.0) + imageCenterY.pow(2.0))
        val positionScore = 1.0 - (distanceFromCenter / maxDistance)
        
        // 面积加分机制：大面积四边形获得额外加分
        val areaBonus = if (areaRatio >= 0.15) {
            (areaRatio - 0.15) * 2.0  // 面积越大，额外加分越多
        } else {
            0.0
        }
        
        // 综合评分 (面积权重绝对主导，大面积获得额外加分)
        val totalScore = areaScore * 0.8 + aspectScore * 0.1 + edgeScore * 0.05 + positionScore * 0.05 + areaBonus
        
        Log.i(TAG, "Rectangle score breakdown: area=$areaScore (ratio=$areaRatio), aspect=$aspectScore (ratio=$aspectRatio), edge=$edgeScore, position=$positionScore, areaBonus=$areaBonus, total=$totalScore")
        
        return totalScore
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