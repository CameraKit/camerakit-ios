Pod::Spec.new do |s|

  s.name              = "CameraKit-iOS"
  s.version           = "1.2.1"
  s.swift_version     = "5"
  s.summary           = "Camera library for iOS written in pure Swift."
  s.description       = "Easy to work with, camera library for iOS written in pure Swift."
  s.homepage          = "https://camerakit.io/"
  s.license           = { :type => "Apache", :file => "LICENSE" }
  s.author            = { "Alterac, Inc" => "hello@camerakit.io" }
  s.social_media_url  = "http://twitter.com/withcamerakit"
  s.platform          = :ios, "10.0"
  s.source            = { :git => "https://github.com/CameraKit/camerakit-ios.git", :tag => "v#{s.version}" }
  s.source_files      = "CameraKit/CameraKit/**/*.{swift}"

end
