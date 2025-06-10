package com.example.rectangle_detector

import android.util.Log
import com.example.rectangle_detector.BuildConfig

/**
 * 调试日志工具类
 * 只在debug模式下输出日志，避免在生产环境中产生不必要的日志输出
 */
object DebugLogger {
    
    /**
     * 输出调试级别日志
     * @param tag 日志标签
     * @param message 日志消息
     */
    fun d(tag: String, message: String) {
        if (BuildConfig.DEBUG) {
            Log.d(tag, message)
        }
    }
    
    /**
     * 输出信息级别日志
     * @param tag 日志标签
     * @param message 日志消息
     */
    fun i(tag: String, message: String) {
        if (BuildConfig.DEBUG) {
            Log.i(tag, message)
        }
    }
    
    /**
     * 输出警告级别日志
     * @param tag 日志标签
     * @param message 日志消息
     */
    fun w(tag: String, message: String) {
        if (BuildConfig.DEBUG) {
            Log.w(tag, message)
        }
    }
    
    /**
     * 输出错误级别日志（始终输出，因为错误信息对生产环境也很重要）
     * @param tag 日志标签
     * @param message 日志消息
     * @param throwable 异常对象（可选）
     */
    fun e(tag: String, message: String, throwable: Throwable? = null) {
        if (throwable != null) {
            Log.e(tag, message, throwable)
        } else {
            Log.e(tag, message)
        }
    }
}