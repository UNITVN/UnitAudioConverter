#
# Be sure to run `pod lib lint UnitAudioConverter.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'UnitAudioConverter'
  s.version          = '0.1.1'
  s.summary          = 'Convert audio file into different formats.'
  s.homepage         = 'https://github.com/trmquang93/UnitAudioConverter'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Quang Tran' => 'trmquang3103@gmail.com' }
  s.source           = { :git => 'https://github.com/trmquang93/UnitAudioConverter.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  
  s.platform = :ios
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.4'
  s.source_files = 'UnitAudioConverter/Classes/**/*'
  
  # s.resource_bundles = {
  #   'UnitAudioConverter' => ['UnitAudioConverter/Assets/*.png']
  # }

   s.public_header_files = 'UnitAudioConverter/**/Headers/Public/*.h'
   s.vendored_libraries = 'UnitAudioConverter/libmp3lame.a'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
