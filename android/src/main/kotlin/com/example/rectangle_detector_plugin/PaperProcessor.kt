package com.example.rectangle_detector_plugin

import android.graphics.Bitmap
import android.util.Log
import org.opencv.android.Utils
import org.opencv.core.*
import org.opencv.imgproc.Imgproc
import kotlin.math.*

const val TAG: String = "PaperProcessor"

fun processPicture(previewFrame: Mat): Corners? {
    val contours = findContours(previewFrame)
    return getCorners(contours, previewFrame.size())
}

fun cropPicture(picture: Mat, pts: List<Point>): Mat {

    pts.forEach { Log.i(TAG, "point: " + it.toString()) }
    val tl = pts[0]
    val tr = pts[1]
    val br = pts[2]
    val bl = pts[3]
    
    val widthA = sqrt((br.x - bl.x).pow(2.0) + (br.y - bl.y).pow(2.0))
    val widthB = sqrt((tr.x - tl.x).pow(2.0) + (tr.y - tl.y).pow(2.0))

    val dw = max(widthA, widthB)
    val maxWidth = dw.toInt()


    val heightA = sqrt((tr.x - br.x).pow(2.0) + (tr.y - br.y).pow(2.0))
    val heightB = sqrt((tl.x - bl.x).pow(2.0) + (tl.y - bl.y).pow(2.0))

    val dh = max(heightA, heightB)
    val maxHeight = dh.toInt()

    val croppedPic = Mat(maxHeight, maxWidth, CvType.CV_8UC4)

    val src_mat = Mat(4, 1, CvType.CV_32FC2)
    val dst_mat = Mat(4, 1, CvType.CV_32FC2)

    src_mat.put(0, 0, tl.x, tl.y, tr.x, tr.y, br.x, br.y, bl.x, bl.y)
    dst_mat.put(0, 0, 0.0, 0.0, dw, 0.0, dw, dh, 0.0, dh)

    val m = Imgproc.getPerspectiveTransform(src_mat, dst_mat)

    Imgproc.warpPerspective(picture, croppedPic, m, croppedPic.size())
    m.release()
    src_mat.release()
    dst_mat.release()
    Log.i(TAG, "crop finish")
    return croppedPic
}

fun enhancePicture(src: Bitmap?): Bitmap {
    val src_mat = Mat()
    Utils.bitmapToMat(src, src_mat)
    Imgproc.cvtColor(src_mat, src_mat, Imgproc.COLOR_RGBA2GRAY)
    Imgproc.adaptiveThreshold(src_mat, src_mat, 255.0, Imgproc.ADAPTIVE_THRESH_MEAN_C, Imgproc.THRESH_BINARY, 15, 15.0)
    val result = Bitmap.createBitmap(src?.width ?: 1080, src?.height ?: 1920, Bitmap.Config.RGB_565)
    Utils.matToBitmap(src_mat, result, true)
    src_mat.release()
    return result
}

private fun findContours(src: Mat): ArrayList<MatOfPoint> {

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

    return validContours
}

/**
 * 从轮廓中获取最佳的矩形角点
 * 优先选择面积较大的四边形，对形状规整性要求较宽松
 */
private fun getCorners(contours: ArrayList<MatOfPoint>, size: Size): Corners? {
    val candidates = mutableListOf<Pair<Corners, Double>>()
    val maxCandidates = minOf(contours.size, 30) // 增加到30个轮廓，扩大搜索范围
    
    Log.i(TAG, "Processing ${contours.size} contours, checking top $maxCandidates")
    
    for (index in 0 until maxCandidates) {
        try {
            val c2f = MatOfPoint2f(*contours[index].toArray())
            val peri = Imgproc.arcLength(c2f, true)
            val approx = MatOfPoint2f()
            
            // 尝试多个近似参数，从严格到宽松
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
                     if (isConvex) { // 恢复凸性检查，确保基本形状正确
                        val sortedPoints = sortPoints(points)
                        val corners = Corners(sortedPoints, size)
                        
                        // 计算矩形度评分
                        val score = calculateRectangleScore(sortedPoints, Imgproc.contourArea(approx), size)
                        candidates.add(Pair(corners, score))
                        
                        Log.i(TAG, "Found rectangle candidate $index: score = $score, convex = $isConvex")
                        foundQuad = true
                        break // 找到四边形就停止尝试其他epsilon值
                    }
                }
            }
            
            if (!foundQuad) {
                Log.d(TAG, "Contour $index: no valid quadrilateral found")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error processing contour $index: ${e.message}")
        }
    }
    
    Log.i(TAG, "Total candidates found: ${candidates.size}")
    
    // 按评分排序，返回最佳候选
    return candidates.maxByOrNull { it.second }?.first
}

/**
 * 计算矩形的质量评分
 * 优先考虑面积大小，对形状规整性要求较宽松
 * 考虑因素：面积大小、基本形状、边长一致性、位置等
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

private fun sortPoints(points: List<Point>): List<Point> {
    val p0 = points.minBy { point -> point.x + point.y } ?: Point()
    val p1 = points.minBy { point -> point.y - point.x } ?: Point()
    val p2 = points.maxBy { point -> point.x + point.y } ?: Point()
    val p3 = points.maxBy { point -> point.y - point.x } ?: Point()
    return listOf(p0, p1, p2, p3)
}