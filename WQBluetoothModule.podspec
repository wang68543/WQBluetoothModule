#
# Be sure to run `pod lib lint WQBluetoothModule.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WQBluetoothModule'
  s.version          = '0.1.0'
  s.summary          = '便于与蓝牙设备交互的框架'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
结合我自己日常的使用情况创建了一个使用命令字回调的便捷框架
                       DESC

  s.homepage         = 'https://github.com/Wang68543/WQBluetoothModule'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'WangQiang68543' => '1261496147@qq.com' }
  s.source           = { :git => 'https://github.com/Wang68543/WQBluetoothModule.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'WQBluetoothModule/Classes/*.swift'
  
  # s.resource_bundles = {
  #   'WQBluetoothModule' => ['WQBluetoothModule/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
