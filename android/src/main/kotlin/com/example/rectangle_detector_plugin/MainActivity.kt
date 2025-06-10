// package com.pengke.paper.scanner

// import android.content.Intent
// import android.os.Bundle
// import android.widget.Button
// import androidx.appcompat.app.AppCompatActivity
// import com.pengke.paper.scanner.scan.ScanActivity
// import com.pengke.paper.scanner.crop.CropActivity
// import android.provider.MediaStore
// import android.app.Activity
// import android.net.Uri
// import androidx.activity.result.contract.ActivityResultContracts
// import android.util.Log
// import android.widget.Toast
// import org.opencv.android.OpenCVLoader
// import org.opencv.core.Mat
// import org.opencv.core.MatOfByte
// import org.opencv.core.Size
// import org.opencv.core.CvType
// import org.opencv.imgcodecs.Imgcodecs
// import org.opencv.imgproc.Imgproc
// import org.opencv.core.Core
// import android.media.ExifInterface
// import java.io.InputStream
// import java.io.ByteArrayOutputStream
// import com.pengke.paper.scanner.SourceManager

// /**
//  * 主页面Activity
//  * 提供扫描文档和选择图片两个功能入口
//  */
// class MainActivity : AppCompatActivity() {
    
//     private val TAG = "MainActivity"
    
//     /**
//      * 图片选择器结果处理
//      */
//     private val imagePickerLauncher = registerForActivityResult(
//         ActivityResultContracts.StartActivityForResult()
//     ) { result ->
//         if (result.resultCode == Activity.RESULT_OK) {
//             result.data?.data?.let { uri ->
//                 processSelectedImage(uri)
//             }
//         }
//     }
    
//     override fun onCreate(savedInstanceState: Bundle?) {
//         super.onCreate(savedInstanceState)
//         setContentView(R.layout.activity_main)
        
//         // 初始化OpenCV
//         initializeOpenCV()
        
//         // 设置按钮点击事件
//         setupButtons()
//     }
    
//     /**
//      * 初始化OpenCV库
//      */
//     private fun initializeOpenCV() {
//         if (!OpenCVLoader.initDebug()) {
//             Log.e(TAG, "OpenCV initialization failed")
//             Toast.makeText(this, "OpenCV初始化失败", Toast.LENGTH_SHORT).show()
//         } else {
//             Log.i(TAG, "OpenCV initialization successful")
//         }
//     }
    
//     /**
//      * 设置按钮点击事件
//      */
//     private fun setupButtons() {
//         // 扫描文档按钮
//         findViewById<Button>(R.id.btn_scan_document).setOnClickListener {
//             startScanActivity()
//         }
        
//         // 选择图片按钮
//         findViewById<Button>(R.id.btn_select_image).setOnClickListener {
//             selectImageFromGallery()
//         }
//     }
    
//     /**
//      * 启动扫描Activity
//      */
//     private fun startScanActivity() {
//         try {
//             val intent = Intent(this, ScanActivity::class.java)
//             startActivity(intent)
//         } catch (e: Exception) {
//             Log.e(TAG, "Failed to start ScanActivity: ${e.message}")
//             Toast.makeText(this, "启动扫描功能失败，请检查权限", Toast.LENGTH_LONG).show()
//         }
//     }
    
//     /**
//      * 从相册选择图片
//      */
//     private fun selectImageFromGallery() {
//         try {
//             val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
//             intent.type = "image/*"
//             imagePickerLauncher.launch(intent)
//         } catch (e: Exception) {
//             Log.e(TAG, "Failed to open gallery: ${e.message}")
//             Toast.makeText(this, "打开相册失败", Toast.LENGTH_SHORT).show()
//         }
//     }
    
//     /**
//      * 处理选中的图片
//      */
//     private fun processSelectedImage(uri: Uri) {
//         try {
//             Log.i(TAG, "Processing selected image: $uri")
            
//             // 读取图片的EXIF信息
//             val inputStream: InputStream = contentResolver.openInputStream(uri)!!
//             val exif = ExifInterface(inputStream)
            
//             // 获取旋转角度
//             var rotation = -1
//             val orientation: Int = exif.getAttributeInt(
//                 ExifInterface.TAG_ORIENTATION,
//                 ExifInterface.ORIENTATION_UNDEFINED
//             )
//             when (orientation) {
//                 ExifInterface.ORIENTATION_ROTATE_90 -> rotation = Core.ROTATE_90_CLOCKWISE
//                 ExifInterface.ORIENTATION_ROTATE_180 -> rotation = Core.ROTATE_180
//                 ExifInterface.ORIENTATION_ROTATE_270 -> rotation = Core.ROTATE_90_COUNTERCLOCKWISE
//             }
            
//             // 获取图片尺寸
//             var imageWidth = exif.getAttributeInt(ExifInterface.TAG_IMAGE_WIDTH, 0).toDouble()
//             var imageHeight = exif.getAttributeInt(ExifInterface.TAG_IMAGE_LENGTH, 0).toDouble()
            
//             if (rotation == Core.ROTATE_90_CLOCKWISE || rotation == Core.ROTATE_90_COUNTERCLOCKWISE) {
//                 imageWidth = exif.getAttributeInt(ExifInterface.TAG_IMAGE_LENGTH, 0).toDouble()
//                 imageHeight = exif.getAttributeInt(ExifInterface.TAG_IMAGE_WIDTH, 0).toDouble()
//             }
            
//             Log.i(TAG, "Image dimensions: ${imageWidth}x${imageHeight}, rotation: $rotation")
            
//             // 读取图片数据
//             val inputData: ByteArray? = getBytes(contentResolver.openInputStream(uri)!!)
//             if (inputData == null || inputData.isEmpty()) {
//                 Toast.makeText(this, "读取图片数据失败", Toast.LENGTH_SHORT).show()
//                 return
//             }
            
//             // 创建OpenCV Mat对象 - 不使用EXIF尺寸，直接从字节数组解码
//             val mat = MatOfByte(*inputData)
//             if (mat.empty()) {
//                 Toast.makeText(this, "创建图像矩阵失败", Toast.LENGTH_SHORT).show()
//                 return
//             }
            
//             // 解码图像
//             try {
//                 val pic = Imgcodecs.imdecode(mat, Imgcodecs.CV_LOAD_IMAGE_UNCHANGED)
//                 if (pic.empty()) {
//                     Toast.makeText(this, "解码图像失败", Toast.LENGTH_SHORT).show()
//                     mat.release()
//                     return
//                 }
            
//                 // 应用旋转
//                 if (rotation > -1) {
//                     Core.rotate(pic, pic, rotation)
//                 }
                
//                 mat.release()
                
//                 // 检测边缘并跳转到裁剪页面
//                 detectEdgeAndCrop(pic)
                
//             } catch (decodeException: Exception) {
//                 Log.e(TAG, "Error decoding image: ${decodeException.message}")
//                 Toast.makeText(this, "图像解码失败: ${decodeException.message}", Toast.LENGTH_LONG).show()
//                 mat.release()
//                 return
//             }
            
//         } catch (e: Exception) {
//             Log.e(TAG, "Error processing selected image: ${e.message}")
//             e.printStackTrace()
//             Toast.makeText(this, "处理图片失败: ${e.message}", Toast.LENGTH_LONG).show()
//         }
//     }
    
//     /**
//      * 检测图片边缘并跳转到裁剪页面
//      */
//     private fun detectEdgeAndCrop(pic: Mat) {
//         try {
//             Log.i(TAG, "Starting edge detection for image: ${pic.width()}x${pic.height()}")
            
//             // 检查图片是否有效
//             if (pic.empty()) {
//                 Log.e(TAG, "Image is empty")
//                 Toast.makeText(this, "图片无效，请重新选择", Toast.LENGTH_SHORT).show()
//                 return
//             }
            
//             // 调用边缘检测算法
//             val detectedCorners = detectDocumentEdges(pic)
            
//             // 转换颜色格式为BGRA（CropActivity需要的格式）
//             val processedPic = Mat()
//             if (pic.channels() == 3) {
//                 Imgproc.cvtColor(pic, processedPic, Imgproc.COLOR_RGB2BGRA)
//             } else if (pic.channels() == 4) {
//                 pic.copyTo(processedPic)
//             } else {
//                 Imgproc.cvtColor(pic, processedPic, Imgproc.COLOR_GRAY2BGRA)
//             }
            
//             // 设置全局数据
//             SourceManager.corners = detectedCorners
//             SourceManager.pic = processedPic
            
//             Log.i(TAG, "Edge detection completed, corners: ${detectedCorners != null}")
            
//             // 跳转到裁剪页面
//             val intent = Intent(this, CropActivity::class.java)
//             startActivity(intent)
            
//         } catch (e: Exception) {
//             Log.e(TAG, "Error in edge detection: ${e.message}")
//             e.printStackTrace()
//             Toast.makeText(this, "边缘检测失败: ${e.message}", Toast.LENGTH_LONG).show()
//         }
//     }
    
//     /**
//      * 检测文档边缘
//      * @param pic 输入图像
//      * @return 检测到的角点，如果检测失败则返回默认角点
//      */
//     private fun detectDocumentEdges(pic: Mat): com.pengke.paper.scanner.processor.Corners? {
//         return try {
//             Log.i(TAG, "Starting edge detection for ${pic.width()}x${pic.height()} image")
            
//             // 使用PaperProcessor进行真正的边缘检测
//             val detectedCorners = com.pengke.paper.scanner.processor.processPicture(pic)
            
//             if (detectedCorners != null) {
//                 Log.i(TAG, "Successfully detected document edges")
//                 detectedCorners.corners.forEachIndexed { index, point ->
//                     Log.i(TAG, "Corner $index: (${point?.x}, ${point?.y})")
//                 }
//                 return detectedCorners
//             } else {
//                 Log.w(TAG, "Edge detection failed, using default corners")
//                 // 如果检测失败，返回默认的四个角点（整个图片区域）
//                 val width = pic.width().toDouble()
//                 val height = pic.height().toDouble()
                
//                 val cornersList = listOf(
//                     org.opencv.core.Point(0.0, 0.0),           // 左上角
//                     org.opencv.core.Point(width, 0.0),         // 右上角
//                     org.opencv.core.Point(width, height),      // 右下角
//                     org.opencv.core.Point(0.0, height)        // 左下角
//                 )
                
//                 val size = org.opencv.core.Size(width, height)
//                 val defaultCorners = com.pengke.paper.scanner.processor.Corners(cornersList, size)
                
//                 Log.i(TAG, "Created default corners for ${width}x${height} image")
//                 return defaultCorners
//             }
            
//         } catch (e: Exception) {
//             Log.e(TAG, "Error in edge detection: ${e.message}")
//             e.printStackTrace()
            
//             // 发生异常时也返回默认角点
//             try {
//                 val width = pic.width().toDouble()
//                 val height = pic.height().toDouble()
//                 val cornersList = listOf(
//                     org.opencv.core.Point(0.0, 0.0),
//                     org.opencv.core.Point(width, 0.0),
//                     org.opencv.core.Point(width, height),
//                     org.opencv.core.Point(0.0, height)
//                 )
//                 val size = org.opencv.core.Size(width, height)
//                 return com.pengke.paper.scanner.processor.Corners(cornersList, size)
//             } catch (ex: Exception) {
//                 Log.e(TAG, "Failed to create default corners: ${ex.message}")
//                 return null
//             }
//         }
//     }
    
//     /**
//      * 将InputStream转换为ByteArray
//      */
//     private fun getBytes(inputStream: InputStream): ByteArray? {
//         return try {
//             val byteBuffer = ByteArrayOutputStream()
//             val bufferSize = 1024
//             val buffer = ByteArray(bufferSize)
//             var len: Int
//             while (inputStream.read(buffer).also { len = it } != -1) {
//                 byteBuffer.write(buffer, 0, len)
//             }
//             byteBuffer.toByteArray()
//         } catch (e: Exception) {
//             Log.e(TAG, "Error converting InputStream to ByteArray: ${e.message}")
//             null
//         }
//     }
// }