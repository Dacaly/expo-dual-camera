Pod::Spec.new do |s|
  s.name             = 'expo-dual-camera'
  s.version          = '1.0.2'
  s.summary          = 'Native dual camera support for Expo'
  s.description      = 'Native dual camera support using AVCaptureMultiCamSession for iOS and CameraX for Android'
  s.homepage         = 'https://github.com/Dacaly/expo-dual-camera'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Dacaly' => 'me@daantje.dev' }
  s.source           = { :git => 'https://github.com/Dacaly/expo-dual-camera.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.swift_version    = '5.0'
  s.source_files     = '../src/**/*.swift'
  s.dependency 'ExpoModulesCore'
end
