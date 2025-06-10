#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint rectangle_detector.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'rectangle_detector'
  s.version          = '0.0.1'
  s.summary          = '基于Vision提供矩形识别功能'
  s.description      = <<-DESC
A new Flutter plugin project for macOS.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end