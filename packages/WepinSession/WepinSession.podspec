#
# Be sure to run `pod lib lint WepinSession.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WepinSession'
  s.version          = '1.1.0'
  s.summary          = 'A short description of WepinSession.'
  s.swift_version    = '5.0'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/WepinWallet/wepin-ios-sdk-internal-v1'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wepin.dev' => 'wepin.dev@iotrust.kr' }
  s.source           = { :git => 'https://github.com/WepinWallet/wepin-ios-sdk-internal-v1.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  # pod lib lint 할때 path : 로컬 저장소 기준의 path로 설정할것...lint 이상 없으면 아래경로로 수정 후 
  # 리포지토리에 push 후 pod trunk push 할것
  #s.source_files = 'WepinSession/Classes/**/*'

  # pod trunk push 할때 path : 리포지토리 기준의 path로 설정할것
  s.source_files = 'packages/WepinSession/WepinSession/Classes/**/*'

  s.module_name = 'WepinSession'
  
  # s.resource_bundles = {
  #   'WepinSession' => ['WepinSession/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'WepinCommon', '~> 1.1.0'
  s.dependency 'WepinStorage', '~> 1.1.0'
  s.dependency 'WepinNetwork', '~> 1.1.0'
  # s.dependency 'WepinCommon', '0.1.1-beta'
  # s.dependency 'WepinStorage', '0.1.1-beta'
  # s.dependency 'WepinNetwork', '0.1.1-beta'
end
