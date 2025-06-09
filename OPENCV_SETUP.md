# OpenCV 集成指南

由于 OpenCV 的 Maven 依赖在 Flutter 插件中不可用，需要手动集成 OpenCV SDK。以下是详细的集成步骤：

## 步骤 1: 下载 OpenCV Android SDK

1. 访问 [OpenCV 官方发布页面](https://opencv.org/releases/)
2. 下载 OpenCV Android SDK（推荐版本 4.5.3 或更高）
3. 解压 SDK 到一个方便的位置

## 步骤 2: 导入 OpenCV 模块

### 方法一：使用 Android Studio（推荐）

1. 在 Android Studio 中打开项目
2. 选择 `File` -> `New` -> `Import Module`
3. 浏览到解压的 OpenCV SDK 目录
4. 选择 `sdk/java` 文件夹
5. 为模块提供一个名称（例如：`opencv`）
6. 点击 `Finish`

### 方法二：手动复制

1. 将 `sdk/java` 文件夹复制到 `android/` 目录下
2. 重命名为 `opencv`
3. 在 `android/settings.gradle` 中添加：
   ```gradle
   include ':opencv'
   ```

## 步骤 3: 修复 OpenCV 模块的 build.gradle

打开 `android/opencv/build.gradle` 文件，进行以下修改：

1. 将第一行从：
   ```gradle
   apply plugin: 'com.android.application'
   ```
   改为：
   ```gradle
   apply plugin: 'com.android.library'
   ```

2. 注释或删除 `applicationId` 行：
   ```gradle
   // applicationId "org.opencv"
   ```

## 步骤 4: 添加依赖

在 `android/build.gradle` 文件的 `dependencies` 块中添加：

```gradle
dependencies {
    implementation project(':opencv')
    // ... 其他依赖
}
```

## 步骤 5: 添加原生库（可选）

如果需要使用 OpenCV 的原生功能：

1. 在 `android/src/main/` 下创建 `jniLibs` 文件夹
2. 从 OpenCV SDK 的 `sdk/native/libs/` 复制所需的架构文件夹到 `jniLibs/`
   - `arm64-v8a/`
   - `armeabi-v7a/`
   - `x86/`
   - `x86_64/`

## 步骤 6: 验证集成

运行以下命令验证集成是否成功：

```bash
cd example
flutter clean
flutter pub get
flutter build apk --debug
```

## 常见问题

### 问题 1: Gradle 同步失败

**解决方案**: 确保 OpenCV 模块的 `build.gradle` 文件已正确修改，特别是 `apply plugin` 和 `applicationId` 部分。

### 问题 2: 找不到 OpenCV 类

**解决方案**: 确保在 `android/build.gradle` 中正确添加了 `implementation project(':opencv')` 依赖。

### 问题 3: 运行时 OpenCV 初始化失败

**解决方案**: 确保设备上安装了 OpenCV Manager 应用，或者使用 `OpenCVLoader.initDebug()` 进行本地初始化。

## 注意事项

1. **版本兼容性**: 确保 OpenCV SDK 版本与 Android SDK 版本兼容
2. **应用大小**: 包含所有架构的原生库会增加应用大小，可以根据需要选择特定架构
3. **权限**: 如果使用相机功能，确保在 `AndroidManifest.xml` 中添加相应权限

## 完成后的项目结构

```
android/
├── opencv/                    # OpenCV 模块
│   ├── build.gradle          # 已修改的构建文件
│   └── src/
├── src/
│   └── main/
│       ├── jniLibs/          # 原生库（可选）
│       └── kotlin/
├── build.gradle              # 包含 OpenCV 依赖
└── settings.gradle           # 包含 opencv 模块
```

按照以上步骤完成后，Android 端的矩形检测功能应该能够正常工作。