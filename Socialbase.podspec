
Pod::Spec.new do |s|

  s.name         = "Socialbase"
  s.version      = "0.5.0"
  s.summary      = "Firestore Social framework"
  s.description  = <<-DESC
Socialbase is a framework for building SNS in Cloud Firestore.
                   DESC
  s.homepage     = "https://github.com/1amageek/Socialbase"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "1amageek" => "tmy0x3@icloud.com" }
  s.social_media_url   = "http://twitter.com/1amageek"
  s.platform     = :ios, "10.0"
  # s.ios.deployment_target = "11.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/1amageek/Socialbase.git", :tag => "#{s.version}" }
  s.source_files  = "Socialbase/**/*.swift"
  s.requires_arc = true
  s.static_framework = true
  s.dependency "Firebase/Core"
  s.dependency "Firebase/Firestore"
  s.dependency "Firebase/Storage"
  s.dependency "Pring"
end
