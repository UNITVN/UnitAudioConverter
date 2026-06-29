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
  s.license          = { :type => 'MIT' }
  s.author           = { 'Quang Tran' => 'trmquang3103@gmail.com' }
  s.source           = { :git => 'https://github.com/trmquang93/UnitAudioConverter.git', :tag => s.version.to_s }

  s.platform = :ios, "13.0"
  s.swift_version = '5.0'

  s.source_files = 'UnitAudioConverter/Classes/**/*'
  s.public_header_files = 'UnitAudioConverter/**/Headers/Public/*.h'
  s.preserve_paths = 'UnitAudioConverter/libmp3lame-device.a', 'UnitAudioConverter/libmp3lame-simulator.a'

  # Device and simulator arm64 slices must stay in separate archives; a single fat
  # libmp3lame.a cannot link for both iOS and iOS Simulator on Apple Silicon.
  lame_device = '"${PODS_TARGET_SRCROOT}/UnitAudioConverter/libmp3lame-device.a"'
  lame_simulator = '"${PODS_TARGET_SRCROOT}/UnitAudioConverter/libmp3lame-simulator.a"'
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS[sdk=iphoneos*]' => "$(inherited) -force_load #{lame_device}",
    'OTHER_LDFLAGS[sdk=iphonesimulator*]' => "$(inherited) -force_load #{lame_simulator}"
  }
end
