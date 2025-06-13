# Changelog

## 1.0.3

### 🔧 Bug Fixes

* Fixed web package compatibility issues with Flutter 3.16.0+
* Updated web dependency to ^1.0.0 for better Flutter version compatibility
* Resolved JSObject supertype errors in web implementation
* Enhanced cross-platform stability and build reliability

## 1.0.2

### 🔧 Bug Fixes

* Fixed code quality warnings in example files
* Replaced `print` statements with `developer.log` for better logging practices
* Optimized string concatenation to improve code readability
* Enhanced code analysis compliance

## 1.0.1

### 🔧 Bug Fixes

* Fixed pub.dev scoring issues
* Improved code formatting and documentation
* Enhanced Swift Package Manager support

## 1.0.0

### 🎉 Major Updates

* **Multiple Input Type Support**: Now supports `Uint8List`, `ui.Image`, and `ImageProvider` input formats
* **New Convenience Methods**:
  - `detectRectangleFromImage(ui.Image image)` - Detect rectangle from ui.Image
  - `detectRectangleFromProvider(ImageProvider provider)` - Detect rectangle from ImageProvider
  - `detectAllRectanglesFromImage(ui.Image image)` - Detect all rectangles from ui.Image
  - `detectAllRectanglesFromProvider(ImageProvider provider)` - Detect all rectangles from ImageProvider
* **Backward Compatibility**: Maintains existing API unchanged, ensuring no code modifications needed
* **Enhanced Documentation**: Updated README and API documentation with detailed usage examples
* **Performance Optimization**: Improved internal image conversion for better processing efficiency

### 🔧 Technical Improvements

* Added `dart:ui`, `dart:async`, `flutter/services.dart`, and `flutter/widgets.dart` dependencies
* Implemented automatic image format conversion functionality
* Enhanced error handling and parameter validation
* Comprehensive documentation and code comments

## 0.0.1

### 🚀 Initial Release

* Implemented rectangle feature point identification functionality
* Multi-platform support: Android, iOS, macOS, Web
* Native platform interface integration
* Complete example application included
* Built on Flutter plugin architecture
* Support for detecting single largest rectangle and all rectangles
* Returns precise four corner point coordinates
