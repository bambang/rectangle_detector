package com.example.rectangle_detector_plugin

import android.content.Context
import android.util.Log
import org.opencv.android.OpenCVLoader

/**
 * OpenCV管理工具类
 * 负责OpenCV的初始化和状态管理，采用单例模式确保全局唯一
 */
class OpenCVManager private constructor() {
    companion object {
        private const val TAG = "OpenCVManager"
        
        @Volatile
        private var INSTANCE: OpenCVManager? = null
        
        /**
         * 获取OpenCVManager单例实例
         * @return OpenCVManager实例
         */
        fun getInstance(): OpenCVManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: OpenCVManager().also { INSTANCE = it }
            }
        }
    }
    
    private var isInitialized = false
    private val initCallbacks = mutableListOf<(Boolean) -> Unit>()
    
    /**
     * 初始化OpenCV库
     * 使用OpenCV 4.9.0+的新API进行初始化
     * @param context Android上下文（保留参数以保持API兼容性）
     * @param callback 初始化结果回调，true表示成功，false表示失败
     */
    fun initialize(context: Context, callback: (Boolean) -> Unit) {
        if (isInitialized) {
            DebugLogger.d(TAG, "OpenCV already initialized")
            callback(true)
            return
        }
        
        // 添加到回调列表
        initCallbacks.add(callback)
        
        // 如果已经在初始化中，直接返回等待结果
        if (initCallbacks.size > 1) {
            DebugLogger.d(TAG, "OpenCV initialization in progress, waiting...")
            return
        }
        
        DebugLogger.d(TAG, "Starting OpenCV initialization using initLocal()")
        
        try {
            // 使用新的OpenCV 4.9.0+ API进行初始化
            val success = OpenCVLoader.initLocal()
            isInitialized = success
            
            if (success) {
                DebugLogger.d(TAG, "OpenCV loaded successfully using initLocal()")
            } else {
                DebugLogger.e(TAG, "OpenCV initialization failed")
            }
            
            // 通知所有等待的回调
            synchronized(initCallbacks) {
                initCallbacks.forEach { it(success) }
                initCallbacks.clear()
            }
        } catch (e: Exception) {
            DebugLogger.e(TAG, "OpenCV initialization exception: ${e.message}", e)
            isInitialized = false
            
            // 通知所有等待的回调初始化失败
            synchronized(initCallbacks) {
                initCallbacks.forEach { it(false) }
                initCallbacks.clear()
            }
        }
    }
    
    /**
     * 检查OpenCV是否已初始化
     * @return true表示已初始化，false表示未初始化
     */
    fun isInitialized(): Boolean = isInitialized
    
    /**
     * 重置初始化状态（主要用于测试）
     * 注意：这个方法应该谨慎使用，通常只在测试环境中调用
     */
    fun reset() {
        DebugLogger.w(TAG, "Resetting OpenCV initialization state")
        isInitialized = false
        synchronized(initCallbacks) {
            initCallbacks.clear()
        }
    }
}